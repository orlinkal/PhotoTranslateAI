import UIKit
import AVFoundation
import Vision
import SwiftUI

class CameraPreviewViewController: UIViewController {
    var previewLayer: AVCaptureVideoPreviewLayer?
    var onTextSelected: ((String) -> Void)?
    var cameraService: CameraService?
    private var screenshotImageView: UIImageView?
    
    // UI Elements
    private lazy var shutterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "camera.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 30
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(handleShutterTap), for: .touchUpInside)
        return button
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.left.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 30
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(handleBackTap), for: .touchUpInside)
        button.isHidden = true // Initially hidden
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupButtons()
    }
    
    private func setupButtons() {
        // Add and position shutter button
        view.addSubview(shutterButton)
        shutterButton.frame = CGRect(x: view.bounds.width - 80,
                                   y: view.bounds.height/2 - 30,
                                   width: 60, height: 60)
        shutterButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
        
        // Add and position back button (same size as shutter)
        view.addSubview(backButton)
        backButton.frame = CGRect(x: view.bounds.width - 80,
                                y: view.bounds.height/2 + 40,
                                width: 60, height: 60)  // Same size as shutter
        backButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
    }
    
    func set(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        view.bringSubviewToFront(shutterButton)
        view.bringSubviewToFront(backButton)
    }
    
    @objc private func handleShutterTap() {
        guard let cameraService = cameraService,
              let frame = cameraService.getCurrentFrame() else { return }
        
        // Create screenshot
        let screenshot = UIImage(cgImage: frame.cgImage!)
        
        // Hide camera preview
        previewLayer?.isHidden = true
        
        // Display screenshot
        let imageView = UIImageView(image: screenshot)
        imageView.contentMode = .scaleAspectFill
        imageView.frame = view.bounds
        view.insertSubview(imageView, at: 0)
        screenshotImageView = imageView
        
        // Show back button and ensure buttons are on top
        backButton.isHidden = false
        view.bringSubviewToFront(shutterButton)
        view.bringSubviewToFront(backButton)
    }
    
    @objc private func handleBackTap() {
        // Remove screenshot and show camera
        screenshotImageView?.removeFromSuperview()
        screenshotImageView = nil
        previewLayer?.isHidden = false
        
        // Hide back button
        backButton.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

// SwiftUI wrapper
struct CameraPreviewView: UIViewControllerRepresentable {
    let cameraService: CameraService
    
    func makeUIViewController(context: Context) -> CameraPreviewViewController {
        let controller = CameraPreviewViewController()
        if let previewLayer = cameraService.previewLayer {
            controller.set(previewLayer: previewLayer)
        }
        controller.cameraService = cameraService
        return controller
    }
    
    func updateUIViewController(_ controller: CameraPreviewViewController, context: Context) {
        // No updates needed
    }
}

// Move the extension outside the class, at file scope
extension UIImage {
    func applyBlurEffect(radius: CGFloat) -> UIImage? {
        let context = CIContext(options: nil)
        guard let ciImage = CIImage(image: self),
              let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            return nil
        }
        
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let outputImage = blurFilter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
} 
