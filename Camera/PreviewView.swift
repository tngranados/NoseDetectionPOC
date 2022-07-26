//
//  PreviewView.swift
//  Camera
//
//  Created by Antonio Granados Moscoso on 26/7/22.
//

import SwiftUI
import UIKit
import AVFoundation
import Vision

class PreviewView: UIView, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var viewModel: CameraViewModel

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    init(
        viewModel: CameraViewModel,
        cameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera,
        cameraPosition: AVCaptureDevice.Position = .back) {

        self.viewModel = viewModel
        super.init(frame: .zero)

        var accessAllowed = false

        let blocker = DispatchGroup()
        blocker.enter()

        AVCaptureDevice.requestAccess(for: .video) { (flag) in
            accessAllowed = true
            blocker.leave()
        }

        blocker.wait()

        if !accessAllowed {
            return
        }

        let session = AVCaptureSession()
        session.beginConfiguration()
        let videoDevice = AVCaptureDevice.default(cameraType,
                                                  for: .video, position: cameraPosition)

        guard videoDevice != nil, let deviceInput = try? AVCaptureDeviceInput(device: videoDevice!), session.canAddInput(deviceInput) else {
            return
        }
        self.videoDeviceInput = deviceInput
        session.addInput(videoDeviceInput!)

        self.photoOutput = AVCapturePhotoOutput()
        photoOutput!.isHighResolutionCaptureEnabled = false
        photoOutput!.isLivePhotoCaptureEnabled = false

        guard session.canAddOutput(photoOutput!) else {
            return

        }
        session.sessionPreset = .photo
        session.addOutput(photoOutput!)

        self.videoOutput = AVCaptureVideoDataOutput()
        self.videoOutput?.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        self.videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera queue"))

        session.addOutput(videoOutput!)

        self.videoOutput?.connection(with: .video)?.videoOrientation = .portrait

        session.commitConfiguration()

        self.captureSession = session
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
        photoSettings.flashMode = .off
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

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let faceDetectionRequest = VNDetectFaceLandmarksRequest { request, error in
            DispatchQueue.main.async {
                self.viewModel.faceLayers.forEach { $0.removeFromSuperlayer() }

                if let results = request.results as? [VNFaceObservation] {
                    for result in results {
                        guard let landmarks = result.landmarks,
                              let nose = landmarks.nose else { return }

                        let faceRectConverted = self.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: result.boundingBox)

                        let landmarkPath = CGMutablePath()
                        let landmarkPathPoints = nose.normalizedPoints
                            .map({ point in
                                CGPoint(
                                    x: point.y * faceRectConverted.height + faceRectConverted.origin.x,
                                    y: point.x * faceRectConverted.width + faceRectConverted.origin.y)
                            })
                        landmarkPath.addLines(between: landmarkPathPoints)
                        landmarkPath.closeSubpath()

                        self.viewModel.nosePosition = landmarkPath.center

                        let landmarkLayer = CAShapeLayer()
                        landmarkLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2.0 * 5, height: 2.0 * 5), cornerRadius: 10).cgPath
                        landmarkLayer.position = landmarkPath.center
                        landmarkLayer.fillColor = UIColor.red.cgColor

                        self.viewModel.faceLayers.append(landmarkLayer)
                        self.layer.addSublayer(landmarkLayer)
                    }
                }
            }
        }

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .leftMirrored)

        do {
            try imageRequestHandler.perform([faceDetectionRequest])
        } catch {
            print(error.localizedDescription)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}

struct PreviewHolder: UIViewRepresentable {
    @ObservedObject var viewModel: CameraViewModel

    private var cameraType: AVCaptureDevice.DeviceType
    private var cameraPosition: AVCaptureDevice.Position
    private var view: PreviewView

    init(
        viewModel: CameraViewModel,
        cameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera, cameraPosition: AVCaptureDevice.Position = .back) {
        self.cameraType = cameraType
        self.cameraPosition = cameraPosition
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
