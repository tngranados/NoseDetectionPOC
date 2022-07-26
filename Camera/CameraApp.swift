//
//  CameraApp.swift
//  Camera
//
//  Created by Antonio Granados Moscoso on 26/7/22.
//

import SwiftUI

@main
struct CameraApp: App {
    @StateObject var cameraViewModel = CameraViewModel()

    var body: some Scene {
        WindowGroup {
            CameraView(viewModel: cameraViewModel)
                .edgesIgnoringSafeArea(.all)
                .statusBar(hidden: true)
        }
    }
}
