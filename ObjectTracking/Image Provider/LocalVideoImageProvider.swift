//
//  LocalVideoImageProvider.swift
//  ObjectTracking
//
//  Created by Mac8 on 30/08/2023.
//

import Foundation
import UIKit
import Combine
import AVFoundation

class LocalVideoImageProvider: NSObject, ObservableObject, ImageProvider {
    var currentFrame: Published<UIImage?>.Publisher { $videoImagePreview }
    @Published var videoImagePreview:UIImage?
    
    private let reader: AVAssetReader?
    private let queue = DispatchQueue(label: "LocalVideoImageProvider-SourceQueue")
    private lazy var timer: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.preferredFramesPerSecond = 30
        return displayLink
    }()
    
    init(videoName:String, extensionName:String) {
        let url = Bundle.main.url(forResource: videoName, withExtension: extensionName)!
        let asset = AVAsset(url: url)
        reader = try? AVAssetReader(asset: asset)

        super.init()

        let videoTrack = asset.tracks(withMediaType: .video).first!
        let output = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [
                String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)
            ]
        )
        reader?.add(output)
    }
    
    func setupProvider() {
        
    }
    
    func startProvider() {
        self.start()
    }
    
    func stopProvider() {
        self.stop()
    }
}


private extension LocalVideoImageProvider {
    func start() {
        queue.async { [unowned self] in
            self.reader?.startReading()
            self.timer.add(to: .main, forMode: .default)
        }
    }

    func stop() {
        queue.async { [unowned self] in
            self.stopReading()
        }
    }

    @objc
    func update() {
        queue.async { [unowned self] in
            if let buffer = self.reader?.outputs.first?.copyNextSampleBuffer() {
                self.videoImagePreview = buffer.image()
            } else {
                self.stopReading()
            }
        }
    }

    private func stopReading() {
        timer.invalidate()
        reader?.cancelReading()
    }
}
