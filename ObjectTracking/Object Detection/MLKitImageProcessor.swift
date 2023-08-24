//
//  ObjectDetectionMain.swift
//  ObjectTracking
//
//  Created by Mac8 on 24/08/2023.
//

import Foundation
import MLKit
import MLKitObjectDetectionCustom

class MLKitImageProcessor: NSObject, ImageProcessor {
    var objectDetector:ObjectDetector?
    var bufferSize:CGSize = .zero
    var alreadyDetected:[ImageProcessorResponseObject] = []
    
    func setupProcessor(with model: AIModel) throws {
        guard let localModelFilePath = Bundle.main.path(forResource: model.modelName, ofType: model.modelExtension) else {
            throw MLError.unableToLoadMLModel
        }
        
        let localModel = LocalModel(path: localModelFilePath)
        let options = CustomObjectDetectorOptions(localModel: localModel)
        options.detectorMode = .stream
        options.shouldEnableMultipleObjects = true
        options.shouldEnableClassification = true
        
        self.objectDetector = ObjectDetector.objectDetector(options: options)
    }
    
    func processFrame(_ sampleImage: UIImage, alreadyDetected:[ImageProcessorResponseObject]) async throws -> [ImageProcessorResponseObject] {
        guard let objectDetector = objectDetector else { throw MLError.detectorOrProcessorNotFound }
        guard let imageBuffer = sampleImage.buffer() else { throw MLError.pixelBufferNotValid }
        
        let imageWidth = CVPixelBufferGetWidth(imageBuffer)
        let imageHeight = CVPixelBufferGetHeight(imageBuffer)
        
        bufferSize = CGSize(width: imageWidth, height: imageHeight)
        self.alreadyDetected = alreadyDetected
        
        let image = VisionImage(image: sampleImage)
        do {
            let objects = try await objectDetector.process(image)
            return self.convertDetectObjects(objects)
        }
        catch {
            throw error
        }
    }
}


extension MLKitImageProcessor {
    func convertDetectObjects(_ objects:[Object]) -> [ImageProcessorResponseObject] {
        let currentDetectedObjects = objects.map({ self.convertObject($0) })
        return currentDetectedObjects
    }
    
    private func convertObject(_ object:Object) -> ImageProcessorResponseObject {
        let normalizedRect = CGRect(x: object.frame.origin.x / self.bufferSize.width, y: object.frame.origin.y / self.bufferSize.height, width: object.frame.size.width / self.bufferSize.width, height: object.frame.size.height / self.bufferSize.height)
        let label = object.labels.map({ $0.text }).joined(separator: ", ")
        let confidence = object.labels.first?.confidence ?? 0.0
        let trackingId = object.trackingID?.intValue ?? 0
        let identifier = UUID().uuidString
        
        let newObject = ImageProcessorResponseObject(identifier: identifier, trackingId: trackingId, label: label, frame: normalizedRect, confidence: confidence)
        return newObject
    }
    
}
