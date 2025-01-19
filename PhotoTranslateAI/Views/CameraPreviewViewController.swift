import UIKit
import AVFoundation
import Vision
import SwiftUI

class CameraPreviewViewController: UIViewController {
    var previewLayer: AVCaptureVideoPreviewLayer?
    var highlightLayers: [CAShapeLayer] = []
    var onTextSelected: ((String) -> Void)?
    var cameraService: CameraService?
    private let padding: CGFloat = 10.0  // Padding around text boxes
    private var selectedLayer: CAShapeLayer?  // Track currently selected layer
    private var screenshotImageView: UIImageView?
    private let screenshotPadding: CGFloat = 30.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        // Add observer for orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    func set(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        
        // Reset previous selection and remove screenshot
        selectedLayer?.strokeColor = UIColor.red.cgColor
        screenshotImageView?.removeFromSuperview()
        screenshotImageView = nil
        
        // Check if tap is within any highlight layer
        for (index, layer) in highlightLayers.enumerated() {
            if let path = layer.path, path.contains(location) {
                // Change tapped layer to green
                layer.strokeColor = UIColor.systemGreen.cgColor
                selectedLayer = layer
                
                // Temporarily hide all other highlight layers
                highlightLayers.forEach { $0.isHidden = $0 != layer }
                
                // Capture full screen
                if let screenshot = captureFullScreenshot() {
                    // Hide camera preview and all highlights
                    previewLayer?.isHidden = true
                    highlightLayers.forEach { $0.isHidden = true }
                    
                    // Display screenshot
                    let imageView = UIImageView(image: screenshot)
                    imageView.contentMode = .scaleAspectFit
                    imageView.frame = view.bounds
                    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    imageView.center = view.center
                    view.addSubview(imageView)
                    screenshotImageView = imageView
                    
                    // Add back button on the middle right
                    let backButton = UIButton(type: .system)
                    backButton.setTitle("Back", for: .normal)
                    backButton.setImage(UIImage(systemName: "arrow.left.circle.fill"), for: .normal)
                    backButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
                    backButton.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
                    backButton.layer.cornerRadius = 20
                    backButton.tintColor = .systemBlue
                    backButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
                    backButton.addTarget(self, action: #selector(backToCameraView), for: .touchUpInside)
                    
                    // Size button to fit content
                    backButton.sizeToFit()
                    
                    // Position button in middle right
                    let buttonSize = backButton.bounds.size
                    backButton.frame = CGRect(
                        x: view.bounds.width - buttonSize.width - 20,
                        y: (view.bounds.height - buttonSize.height) / 2,
                        width: buttonSize.width,
                        height: buttonSize.height
                    )
                    backButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
                    
                    // Add shadow for better visibility
                    backButton.layer.shadowColor = UIColor.black.cgColor
                    backButton.layer.shadowOffset = CGSize(width: 0, height: 2)
                    backButton.layer.shadowRadius = 4
                    backButton.layer.shadowOpacity = 0.3
                    
                    view.addSubview(backButton)
                }
                
                // Show all highlight layers again (they'll be hidden when we switch to screenshot)
                highlightLayers.forEach { $0.isHidden = false }
                
                onTextSelected?("Selected text from box \(index)")
                break
            }
        }
    }
    
    @objc private func backToCameraView() {
        // Remove screenshot and show camera
        screenshotImageView?.removeFromSuperview()
        screenshotImageView = nil
        
        // Remove back button
        view.subviews.forEach { subview in
            if let button = subview as? UIButton {
                button.removeFromSuperview()
            }
        }
        
        previewLayer?.isHidden = false
        highlightLayers.forEach { $0.isHidden = false }
        
        // Reset selection
        selectedLayer?.strokeColor = UIColor.red.cgColor
        selectedLayer = nil
    }
    
    @objc private func handleOrientationChange() {
        // Only handle if we're in screenshot mode
        guard screenshotImageView != nil else { return }
        
        // Recapture screenshot with new orientation
        if let newScreenshot = captureFullScreenshot() {
            screenshotImageView?.image = newScreenshot
            
            // Update screenshot view frame and position
            screenshotImageView?.frame = view.bounds
            screenshotImageView?.contentMode = .scaleAspectFit
            screenshotImageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            screenshotImageView?.center = view.center
            
            // Update back button position
            view.subviews.forEach { subview in
                if let button = subview as? UIButton {
                    let buttonSize = button.bounds.size
                    button.frame = CGRect(
                        x: view.bounds.width - buttonSize.width - 20,
                        y: (view.bounds.height - buttonSize.height) / 2,
                        width: buttonSize.width,
                        height: buttonSize.height
                    )
                    button.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
                }
            }
        }
    }
    
    private func captureFullScreenshot() -> UIImage? {
        guard let cameraService = cameraService,
              let fullImage = cameraService.getCurrentFrame(),
              let selectedLayer = selectedLayer,
              let originalPath = selectedLayer.path else {
            return nil
        }
        
        let deviceOrientation = UIDevice.current.orientation
        let isLandscape = deviceOrientation.isLandscape
        
        // Create an image context with the screen size
        let contextSize = isLandscape ? 
            CGSize(width: view.bounds.width, height: view.bounds.height) :
            view.bounds.size
        
        UIGraphicsBeginImageContextWithOptions(contextSize, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Draw the blurred background first
        if let cgImage = fullImage.cgImage {
            let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: getImageOrientation(for: deviceOrientation))
            
            // Create blurred version of the full image
            let blurEffect = CIFilter(name: "CIGaussianBlur")
            blurEffect?.setValue(CIImage(image: image), forKey: kCIInputImageKey)
            blurEffect?.setValue(8, forKey: kCIInputRadiusKey)
            
            if let blurredImage = blurEffect?.outputImage,
               let blurredCGImage = CIContext().createCGImage(blurredImage, from: blurredImage.extent) {
                let finalBlurredImage = UIImage(cgImage: blurredCGImage, scale: 1.0, 
                                              orientation: getImageOrientation(for: deviceOrientation))
                finalBlurredImage.draw(in: view.bounds)
                
                // Get the original box rect and create expanded rect
                let originalBox = originalPath.boundingBox
                let expandedBox = originalBox.insetBy(dx: -32, dy: -32)
                
                // Create expanded path
                let expandedPath = UIBezierPath(rect: expandedBox)
                
                // Use the expanded path as a mask
                context.saveGState()
                expandedPath.addClip()
                
                // Draw original non-blurred image in the expanded area
                image.draw(in: view.bounds)
                context.restoreGState()
                
                // Draw the expanded green box
                context.saveGState()
                context.setStrokeColor(UIColor.systemGreen.cgColor)
                context.setLineWidth(2.0)
                expandedPath.stroke()
                context.restoreGState()
            }
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func getImageOrientation(for deviceOrientation: UIDeviceOrientation) -> UIImage.Orientation {
        switch deviceOrientation {
        case .landscapeLeft:
            return .left
        case .landscapeRight:
            return .right
        case .portraitUpsideDown:
            return .down
        default:
            return .up
        }
    }
    
    func updateTextBoxes(_ boxes: [CGRect]) {
        // Clear selection when boxes update
        selectedLayer = nil
        
        highlightLayers.forEach { $0.removeFromSuperlayer() }
        highlightLayers.removeAll()
        
        for box in boxes {
            guard let previewLayer = previewLayer else { continue }
            
            let deviceOrientation = UIDevice.current.orientation
            let viewBox: CGRect
            let compensationFactor: CGFloat = 1.0
            let centerOffset = previewLayer.bounds.width * (compensationFactor - 1) / 2
            
            // Calculate base box with orientation handling
            switch deviceOrientation {
            case .landscapeLeft:
                viewBox = CGRect(
                    x: box.minY * previewLayer.bounds.width * compensationFactor - centerOffset,
                    y: box.minX * previewLayer.bounds.height,
                    width: box.height * previewLayer.bounds.width,
                    height: box.width * previewLayer.bounds.height
                )
            case .landscapeRight:
                viewBox = CGRect(
                    x: (1 - box.maxY) * previewLayer.bounds.width * compensationFactor - centerOffset,
                    y: (1 - box.maxX) * previewLayer.bounds.height,
                    width: box.height * previewLayer.bounds.width,
                    height: box.width * previewLayer.bounds.height
                )
            default:
                viewBox = CGRect(
                    x: (1 - box.maxY) * previewLayer.bounds.width * compensationFactor - centerOffset,
                    y: (1 - box.maxX) * previewLayer.bounds.height,
                    width: box.height * previewLayer.bounds.width,
                    height: box.width * previewLayer.bounds.height
                )
            }
            
            // Add padding to make boxes bigger
            let paddedBox = viewBox.insetBy(dx: -padding, dy: -padding)
            
            // Create highlight layer
            let highlightLayer = CAShapeLayer()
            highlightLayer.frame = previewLayer.frame
            highlightLayer.fillColor = UIColor.clear.cgColor
            highlightLayer.strokeColor = UIColor.red.cgColor
            highlightLayer.lineWidth = 2.0
            highlightLayer.opacity = 0.7
            
            let path = UIBezierPath(rect: paddedBox)
            highlightLayer.path = path.cgPath
            
            previewLayer.addSublayer(highlightLayer)
            highlightLayers.append(highlightLayer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        
        // Update highlight layers frames
        highlightLayers.forEach { $0.frame = view.bounds }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// SwiftUI wrapper
struct CameraPreviewView: UIViewControllerRepresentable {
    let cameraService: CameraService
    let textBoxes: [CGRect]
    
    func makeUIViewController(context: Context) -> CameraPreviewViewController {
        let controller = CameraPreviewViewController()
        if let previewLayer = cameraService.previewLayer {
            controller.set(previewLayer: previewLayer)
        }
        controller.cameraService = cameraService
        return controller
    }
    
    func updateUIViewController(_ controller: CameraPreviewViewController, context: Context) {
        controller.updateTextBoxes(textBoxes)
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
