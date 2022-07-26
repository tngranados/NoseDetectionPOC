//
//  PreviewView.swift
//  Camera
//
//  Created by Antonio Granados Moscoso on 26/7/22.
//

import SwiftUI
import UIKit
import AVFoundation

class PreviewView: UIView, AVCapturePhotoCaptureDelegate {
//    private var delegate: CameraViewDelegate?

    private var captureSession: AVCaptureSession?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var viewModel: CameraViewModel

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    init(
        //delegate: CameraViewDelegate? = nil,
        viewModel: CameraViewModel,
        cameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera,
        cameraPosition: AVCaptureDevice.Position = .back) {

        self.viewModel = viewModel
        super.init(frame: .zero)

//        self.delegate = delegate

        var accessAllowed = false

        let blocker = DispatchGroup()
        blocker.enter()

        AVCaptureDevice.requestAccess(for: .video) { (flag) in
            accessAllowed = true
//            delegate?.cameraAccessGranted()
            blocker.leave()
        }

        blocker.wait()

        if !accessAllowed {
//            delegate?.cameraAccessDenied()
            return
        }

        let session = AVCaptureSession()
        session.beginConfiguration()
        let videoDevice = AVCaptureDevice.default(cameraType,
                                                  for: .video, position: cameraPosition)

        guard videoDevice != nil, let deviceInput = try? AVCaptureDeviceInput(device: videoDevice!), session.canAddInput(deviceInput) else {
//            delegate?.noCameraDetected()
            return
        }
        self.videoDeviceInput = deviceInput
        session.addInput(videoDeviceInput!)

        self.photoOutput = AVCapturePhotoOutput()
        photoOutput!.isHighResolutionCaptureEnabled = true
        photoOutput!.isLivePhotoCaptureEnabled = photoOutput!.isLivePhotoCaptureSupported

        guard session.canAddOutput(photoOutput!) else {
//            delegate?.noCameraDetected()
            return

        }
        session.sessionPreset = .photo
        session.addOutput(photoOutput!)

        session.commitConfiguration()

        self.captureSession = session
//        delegate?.cameraSessionStarted()
        self.captureSession?.startRunning()
    }

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if nil != self.superview {
            self.videoPreviewLayer.session = self.captureSession
            self.videoPreviewLayer.videoGravity = .resizeAspectFill
        }
    }

    func capturePhoto() {
        let photoSettings: AVCapturePhotoSettings
        if photoOutput!.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format:
                                                    [AVVideoCodecKey: AVVideoCodecType.hevc])

            let previewPixelType = photoSettings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                 kCVPixelBufferWidthKey as String: 160,
                                 kCVPixelBufferHeightKey as String: 160,
            ]
            photoSettings.previewPhotoFormat = previewFormat
        } else {
            photoSettings = AVCapturePhotoSettings()
        }
        photoSettings.flashMode = .auto
        self.photoOutput?.capturePhoto(with: photoSettings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            viewModel.capturedPhotoError = error
            return
        }

        if let cgImage = photo.previewCGImageRepresentation() {
            let orientation = photo.metadata[kCGImagePropertyOrientation as String] as! NSNumber
            let uiOrientation = UIImage.Orientation(rawValue: orientation.intValue)!
            let image = UIImage(cgImage: cgImage, scale: 1, orientation: uiOrientation)
            viewModel.capturedPhotos.insert(image, at: 0)
        } else {
            viewModel.capturedPhotoError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "error"])
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}

struct PreviewHolder: UIViewRepresentable {
//    private var delegate: CameraViewDelegate?
    @ObservedObject var viewModel: CameraViewModel

    private var cameraType: AVCaptureDevice.DeviceType
    private var cameraPosition: AVCaptureDevice.Position
    private var view: PreviewView

    init(
//        delegate: CameraViewDelegate? = nil,
        viewModel: CameraViewModel,
        cameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera, cameraPosition: AVCaptureDevice.Position = .back) {
//        self.delegate = delegate
        self.cameraType = cameraType
        self.cameraPosition = cameraPosition
//        self.view = PreviewView(delegate: delegate, cameraType: cameraType, cameraPosition: cameraPosition)
        self.viewModel = viewModel
        self.view = PreviewView(viewModel: viewModel, cameraType: cameraType, cameraPosition: cameraPosition)
        viewModel.preview = self
    }

    func makeUIView(context: UIViewRepresentableContext<PreviewHolder>) -> PreviewView {
        view
    }

    func updateUIView(_ uiView: PreviewView, context: UIViewRepresentableContext<PreviewHolder>) {
    }

    func getView() -> PreviewView {
        return self.view
    }

    typealias UIViewType = PreviewView
}
