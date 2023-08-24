//
//  ImageProvierProtocol.swift
//  ObjectTracking
//
//  Created by Mac8 on 23/08/2023.
//

import Foundation
import UIKit
import Combine

protocol ImageProvider {
    var currentFrame:Published<UIImage?>.Publisher { get }
    func setupProvider()
    func startProvider()
    func stopProvider()
}
