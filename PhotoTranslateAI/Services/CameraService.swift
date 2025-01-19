import AVFoundation
import SwiftUI

class CameraService: NSObject, ObservableObject {
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var cameraPermissionGranted = false
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera-session")
    weak var textRecognitionService: TextRecognitionService?
    private var isSessionRunning = false
    
    override init() {
        super.init()
        setupPreviewLayer()
        checkPermission()
        
        // Add observer for device orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePreviewOrientation),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func updatePreviewOrientation() {
        guard let connection = previewLayer?.connection else { return }
        
        let currentDevice = UIDevice.current
        let orientation = currentDevice.orientation
        
        switch orientation {
        case .portrait:
            connection.videoOrientation = .portrait
        case .landscapeRight:
            connection.videoOrientation = .landscapeLeft
        case .landscapeLeft:
            connection.videoOrientation = .landscapeRight
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
        default:
            connection.videoOrientation = .portrait
        }
    }
    
    private func setupPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        // Set initial orientation
        if let connection = previewLayer.connection {
            let currentDevice = UIDevice.current
            let orientation = currentDevice.orientation
            let previewLayerConnection = connection
            
            switch orientation {
            case .portrait:
                previewLayerConnection.videoOrientation = .portrait
            case .landscapeRight:
                previewLayerConnection.videoOrientation = .landscapeLeft
            case .landscapeLeft:
                previewLayerConnection.videoOrientation = .landscapeRight
            case .portraitUpsideDown:
                previewLayerConnection.videoOrientation = .portraitUpsideDown
            default:
                previewLayerConnection.videoOrientation = .portrait
            }
        }
        
        self.previewLayer = previewLayer
    }
    
    private func checkPermission() {
        print("Checking camera permission...")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Camera permission already granted")
            cameraPermissionGranted = true
            setupCamera()
        case .notDetermined:
            print("Requesting camera permission...")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                print("Camera permission response: \(granted)")
                DispatchQueue.main.async {
                    self?.cameraPermissionGranted = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        default:
            print("Camera permission denied")
            cameraPermissionGranted = false
        }
    }
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                return
            }
            
            if self.session.canAddInput(videoInput) {
                self.session.addInput(videoInput)
            }
            
            // Add video output
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            
            if self.session.canAddOutput(videoOutput) {
                self.session.addOutput(videoOutput)
                if let connection = videoOutput.connection(with: .video) {
                    connection.videoOrientation = .portrait
                }
            }
            
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.startSession()
            }
        }
    }
    
    func startSession() {
        guard !isSessionRunning else { return }
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
            self?.isSessionRunning = true
        }
    }
    
    func stopSession() {
        guard isSessionRunning else { return }
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
            self?.isSessionRunning = false
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        textRecognitionService?.processFrame(sampleBuffer)
    }
} 