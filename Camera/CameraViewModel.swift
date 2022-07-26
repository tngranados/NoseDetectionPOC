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

    @Published var nosePosition: CGPoint? {
        didSet {
            guard let nosePosition = nosePosition, debounceTimer == nil else { return }

            if nosePosition.x > 50 && nosePosition.x < 150 && nosePosition.y > 250 && nosePosition.y < 350 {
                capturePhoto()
                debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { _ in
                    self.debounceTimer = nil
                })
            }
        }
    }
    private var debounceTimer: Timer?
    
    var faceLayers: [CAShapeLayer] = []

    var preview: PreviewHolder!

    override init() {
        super.init()

        self.preview = PreviewHolder(viewModel: self, cameraType: .builtInWideAngleCamera, cameraPosition: .front)
    }

    public func capturePhoto() {
        preview?.getView().capturePhoto()
    }
}
