//
//  ContentView.swift
//  ObjectTracking
//
//  Created by Mac8 on 23/08/2023.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State var cameraPreviewImage:UIImage?
    @State var cancellables = Set<AnyCancellable>()
    @State var currentDetectedObjects:[ImageProcessorResponseObject] = []
    @State var currentModel:AIModel = .inception_v4
    
    var imageProvider = DeviceCameraImageProvider()
    var imageProcessor = MLKitImageProcessor()
    
    var body: some View {
        VStack {
            if let image = cameraPreviewImage {
                Image(uiImage: image).resizable()
                    .overlay(
                        GeometryReader { imageArea in
                            ZStack {
                                ForEach(self.currentDetectedObjects, id: \.self.identifier) { objects in
                                    ZStack {
                                        Color.red.opacity(0.3)
                                        Rectangle().stroke(.red)
                                    }
                                    .frame(width: objects.frame.width * imageArea.size.width, height: objects.frame.height * imageArea.size.height)
                                    .position(x: objects.frame.midX * imageArea.size.width, y: objects.frame.midY * imageArea.size.height)
                                }
                            }
                        }
                    )
            }
        }
        .padding()
        .onAppear {
            self.imageProvider.setupProvider()
            self.imageProvider.startProvider()
            
            try? self.imageProcessor.setupProcessor(with: self.currentModel)
            
            imageProvider.currentFrame.receive(on: DispatchQueue.main).sink { image in
                self.cameraPreviewImage = image
                if let validImage = self.cameraPreviewImage {
                    self.processImage(validImage)
                }
            }
            .store(in: &cancellables)
        }
        .onDisappear {
            self.imageProvider.stopProvider()
        }
    }
    
    func processImage(_ image:UIImage) {
        Task {
           let objects = try? await self.imageProcessor.processFrame(image, alreadyDetected: [])
            self.currentDetectedObjects = objects ?? []
            print("objects found: \(objects?.count ?? 0)")
        }
    }
    
}
