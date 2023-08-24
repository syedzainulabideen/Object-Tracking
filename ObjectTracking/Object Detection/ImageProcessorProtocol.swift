//
//  ImageProcessorProtocol.swift
//  ObjectTracking
//
//  Created by Mac8 on 24/08/2023.
//

import Foundation
import UIKit

protocol ImageProcessor {
    func setupProcessor(with model:AIModel) throws
    func processFrame(_ sampleImage: UIImage, alreadyDetected:[ImageProcessorResponseObject]) async throws -> [ImageProcessorResponseObject]
}

struct ImageProcessorResponseObject: Hashable {
    var identifier:String
    var trackingId:Int
    var label:String
    var frame:CGRect
    var confidence:Float
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(trackingId)
        hasher.combine(label)
    }
}

enum AIModel: String, CaseIterable {
    case inception_v4 = "Inception V4"
    
    var modelName:String {
        switch self {
        case .inception_v4:
            return "inception_v4_1_metadata_1"
        }
    }
    
    var modelExtension:String {
        return "tflite"
    }
}

enum MLError: Error {
    case unableToLoadMLModel
    case pixelBufferNotValid
    case detectorOrProcessorNotFound
}
