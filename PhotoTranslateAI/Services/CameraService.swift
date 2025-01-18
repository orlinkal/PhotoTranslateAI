import AVFoundation
import SwiftUI

class CameraService: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var cameraPermissionGranted = false
    @Published var error: Error?
    
    private let sessionQueue = DispatchQueue(label: "camera-session")
    
    override init() {
        super.init()
        checkPermission()
    }
    
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionGranted = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        default:
            cameraPermissionGranted = false
        }
    }
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Clear any existing inputs
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            
            do {
                guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                              for: .video,
                                                              position: .back) else {
                    print("Failed to get camera device")
                    return
                }
                
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                
                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                    print("Camera input added successfully")
                } else {
                    print("Could not add camera input")
                    return
                }
                
                self.session.commitConfiguration()
                
                DispatchQueue.main.async {
                    self.session.startRunning()
                    print("Camera session started")
                }
                
            } catch {
                print("Error setting up camera: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.error = error
                }
            }
        }
    }
    
    func stop() {
        sessionQueue.async {
            self.session.stopRunning()
        }
    }
} 