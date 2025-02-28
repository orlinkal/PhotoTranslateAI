import AVFoundation
import SwiftUI

class CameraService: NSObject, ObservableObject {
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var cameraPermissionGranted = false
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera-session")
    weak var textRecognitionService: TextRecognitionService?
    private var isSessionRunning = false
    private var videoOutput: AVCaptureVideoDataOutput?
    private var currentVideoFrame: CMSampleBuffer?
    
    private var captureDevice: AVCaptureDevice? {
        guard let videoInput = session.inputs.first as? AVCaptureDeviceInput else { return nil }
        return videoInput.device
    }
    
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
                self.videoOutput = videoOutput
                if let connection = videoOutput.connection(with: .video) {
                    connection.videoOrientation = .portrait
                }
            }
            
            self.session.commitConfiguration()
            
            self.session.startRunning()
            self.isSessionRunning = true
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
    
    func focus(at point: CGPoint, completion: @escaping () -> Void) {
        guard let device = captureDevice else {
            completion()
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            // Check if device supports focus point
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            
            // Check if device supports exposure point
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
            
            // Wait a bit for focus to adjust before taking the picture
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion()
            }
        } catch {
            print("Error setting focus: \(error.localizedDescription)")
            completion()
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        currentVideoFrame = sampleBuffer
        
        textRecognitionService?.processFrame(sampleBuffer)
    }
    
    func getCurrentFrame() -> UIImage? {
        guard let sampleBuffer = currentVideoFrame,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
} 