//
//  CoreMLImageProcessor.swift
//  ObjectTracking
//
//  Created by Mac8 on 30/08/2023.
//

import Foundation
import UIKit
import Vision

class CoreMLImageProcessor: NSObject, ImageProcessor {
    private var visionModel: VNCoreMLModel!
    private var requests = [VNRequest]()
    private var processedResponseObjects = [ImageProcessorResponseObject]()
    private var bufferSize: CGSize = .zero
    
    func setupProcessor(with model: AIModel) throws {
        self.visionModel = try VNCoreMLModel(for: yolov8x().model)
        let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
            DispatchQueue.main.async(execute: {
                if let results = request.results {
                    self.drawResults(results)
                }
            })
        })
        self.requests = [objectRecognition]
    }
    
    func processFrame(_ sampleImage: UIImage, alreadyDetected: [ImageProcessorResponseObject]) async throws -> [ImageProcessorResponseObject] {
        guard let pixelBuffer = sampleImage.buffer() else {
            return []
        }
        
        let imageWidth = CVPixelBufferGetWidth(pixelBuffer)
        let imageHeight = CVPixelBufferGetHeight(pixelBuffer)
        
        self.bufferSize = CGSize(width: imageWidth, height: imageHeight)
        self.processBuffer(pixelBuffer: pixelBuffer)
        
        return self.processedResponseObjects
    }
}

extension CoreMLImageProcessor {
    func drawResults(_ results: [Any]) {
        var newDetections = [ImageProcessorResponseObject]()
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            
            let topLabelObservation = objectObservation.labels[0]
//            print(topLabelObservation.identifier)
//            guard topLabelObservation.identifier.lowercased() == "car" else { continue }
            let boundingBox = CGRect(origin: CGPoint(x:1.0-objectObservation.boundingBox.origin.y-objectObservation.boundingBox.size.height, y:objectObservation.boundingBox.origin.x), size: CGSize(width:objectObservation.boundingBox.size.height, height:objectObservation.boundingBox.size.width))
            
            let objectBounds = VNImageRectForNormalizedRect(boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            let formattedString = NSMutableAttributedString(string: String(format: "\(topLabelObservation.identifier)\n %.1f%% ", topLabelObservation.confidence*100).capitalized)
            newDetections.append(ImageProcessorResponseObject(identifier: UUID().uuidString, trackingId: 0, label: formattedString.string, frame: boundingBox, confidence: 0))
            
        }
        
        self.processedResponseObjects = newDetections
    }
    
    func processBuffer(pixelBuffer: CVPixelBuffer) {
        let value:CGImagePropertyOrientation = UIDevice.current.orientation == .portrait ? .up  : .rightMirrored
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
            
        } catch {
            print(error)
        }
    }
}
