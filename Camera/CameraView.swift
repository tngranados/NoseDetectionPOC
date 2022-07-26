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
        }
    }
}
