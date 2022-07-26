//
//  CameraView.swift
//  Camera
//
//  Created by Antonio Granados Moscoso on 26/7/22.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @ObservedObject var viewModel: CameraViewModel
    
    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Color.black

            viewModel.preview
                .onTapGesture {
                    viewModel.capturePhoto()
                }
            
            VStack {
                Spacer()
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(viewModel.capturedPhotos, id: \.self) { photo in
                            Image(uiImage: photo)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80)
                        }
                    }
                    .padding()
                }
            }
            .padding(.bottom, 50)

            Rectangle()
                .foregroundColor(.clear)
                .border(.red, width: 2)
                .frame(width: 100, height: 100).position(x: 100, y: 300)

            if let nosePosition = viewModel.nosePosition {
                VStack {
                    Spacer().frame(height: 50)
                    Text("Nose x: \(nosePosition.x), y: \(nosePosition.y)")
                        .foregroundColor(.white)
                    Spacer()
                }
            }
        }
    }
}
