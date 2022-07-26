//
//  CameraViewModel.swift
//  Camera
//
//  Created by Antonio Granados Moscoso on 26/7/22.
//

import SwiftUI

public class CameraViewModel : NSObject, ObservableObject {
    @Published var capturedPhotos: [UIImage] = []
    @Published var capturedPhotoError: Error?

    var preview: PreviewHolder!

    override init() {
        super.init()

        self.preview = PreviewHolder(viewModel: self, cameraType: .builtInWideAngleCamera, cameraPosition: .front)
    }

    public func capturePhoto() {
        preview?.getView().capturePhoto()
    }
}
