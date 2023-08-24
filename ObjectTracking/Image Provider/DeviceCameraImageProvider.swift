//
//  DeviceCameraImageProvider.swift
//  ObjectTracking
//
//  Created by Mac8 on 23/08/2023.
//

import Foundation
import UIKit
import AVFoundation
import Vision
import Combine

class DeviceCameraImageProvider: NSObject, ObservableObject, ImageProvider {
    @Published private var cameraImagePreview:UIImage?
    var currentFrame: Published<UIImage?>.Publisher { $cameraImagePreview }
    
    private let session = AVCaptureSession()
    private var detectionOverlay: CALayer! = nil
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    func setupProvider() {
        UIApplication.shared.isIdleTimerDisabled = true
        self.setupAVCapture()
    }
    
    func startProvider() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func stopProvider() {
        UIApplication.shared.isIdleTimerDisabled = false
        DispatchQueue.global(qos: .background).async {
            self.session.stopRunning()
        }
    }
    
    private func setupAVCapture() {
        var deviceInput: AVCaptureDeviceInput!
        
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.medium
        
        guard session.canAddInput(deviceInput) else {
            print("Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        
        session.addInput(deviceInput)
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            videoDataOutput.alwaysDiscardsLateVideoFrames = false
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        }
        else {
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        
        let captureConnection = videoDataOutput.connection(with: .video)
        captureConnection?.isEnabled = true
        captureConnection?.videoOrientation = UIDevice.current.orientation == .portrait ? .portrait  : .landscapeRight

        do {
            try  videoDevice!.lockForConfiguration()
            videoDevice?.focusMode = .continuousAutoFocus
            //let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            //let bufferSize = CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        session.commitConfiguration()
    }
}


extension DeviceCameraImageProvider: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.cameraImagePreview = sampleBuffer.image()
    }
}


