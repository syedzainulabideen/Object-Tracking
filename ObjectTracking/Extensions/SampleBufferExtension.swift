//
//  SampleBufferExtension.swift
//  ObjectTracking
//
//  Created by Mac8 on 23/08/2023.
//

import Foundation
import AVFoundation
import UIKit

extension CMSampleBuffer {
    func image() -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        let ciimage = CIImage(cvPixelBuffer: imageBuffer)
        let image = self.convert(cmage: ciimage)
        return image
    }
    
    private func convert(cmage: CIImage) -> UIImage {
         let context = CIContext(options: nil)
         let cgImage = context.createCGImage(cmage, from: cmage.extent)!
         let image = UIImage(cgImage: cgImage)
         return image
    }
}
