import UIKit
import AVFoundation
import Vision
import SwiftUI
import TOCropViewController

class CameraPreviewViewController: UIViewController {
    var previewLayer: AVCaptureVideoPreviewLayer?
    var onTextSelected: ((String) -> Void)?
    var cameraService: CameraService?
    private var screenshotImageView: UIImageView?
    private var selectionViewController: SelectionViewController?
    private var resultSheet: UIView?
    private var recognizedTextLabel: UILabel?
    
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
    
    private lazy var translateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "text.bubble.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 30
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(handleTranslateTap), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var cropButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "crop"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 30
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.addTarget(self, action: #selector(handleCropTap), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupButtons()
    }
    
    private func setupButtons() {
        let buttonSize: CGFloat = 80
        let sideSpacing: CGFloat = 40
        let bottomPadding: CGFloat = 50
        
        // Determine if we're in landscape
        let isLandscape = UIDevice.current.orientation.isLandscape
        
        // Calculate button positions based on orientation
        let buttonY: CGFloat
        let rightEdge = view.bounds.width - buttonSize - sideSpacing
        
        if isLandscape {
            // In landscape, position buttons on the right side
            buttonY = view.bounds.height/2 - buttonSize/2  // Center vertically
        } else {
            // In portrait, position buttons at the bottom
            buttonY = view.bounds.height - bottomPadding - buttonSize
        }
        
        // Position shutter/back button
        if isLandscape {
            shutterButton.frame = CGRect(x: rightEdge,
                                       y: buttonY,
                                       width: buttonSize,
                                       height: buttonSize)
            backButton.frame = shutterButton.frame
        } else {
            let centerX = view.bounds.width/2 - buttonSize/2
            shutterButton.frame = CGRect(x: centerX,
                                       y: buttonY,
                                       width: buttonSize,
                                       height: buttonSize)
            backButton.frame = shutterButton.frame
        }
        
        // Position crop button
        if isLandscape {
            cropButton.frame = CGRect(x: rightEdge,
                                    y: buttonY - buttonSize - sideSpacing,
                                    width: buttonSize,
                                    height: buttonSize)
        } else {
            cropButton.frame = CGRect(x: sideSpacing,
                                    y: buttonY,
                                    width: buttonSize,
                                    height: buttonSize)
        }
        
        // Position translate button
        if isLandscape {
            translateButton.frame = CGRect(x: rightEdge,
                                         y: buttonY + buttonSize + sideSpacing,
                                         width: buttonSize,
                                         height: buttonSize)
        } else {
            translateButton.frame = CGRect(x: rightEdge,
                                         y: buttonY,
                                         width: buttonSize,
                                         height: buttonSize)
        }
        
        // Update corner radius and add to view
        [shutterButton, backButton, cropButton, translateButton].forEach { button in
            button.layer.cornerRadius = buttonSize/2
            view.addSubview(button)
        }
        
        // Set initial visibility
        backButton.isHidden = true
        cropButton.isHidden = true
        translateButton.isHidden = true
        
        // Update button icons padding
        let iconPadding: CGFloat = 15
        let iconInsets = UIEdgeInsets(top: iconPadding, left: iconPadding,
                                     bottom: iconPadding, right: iconPadding)
        
        [shutterButton, backButton, cropButton, translateButton].forEach { button in
            button.imageEdgeInsets = iconInsets
        }
        
        // Ensure proper z-index
        view.bringSubviewToFront(cropButton)
        view.bringSubviewToFront(shutterButton)
        view.bringSubviewToFront(backButton)
        view.bringSubviewToFront(translateButton)
    }
    
    func set(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        view.bringSubviewToFront(shutterButton)
        view.bringSubviewToFront(backButton)
    }
    
    @objc private func handleShutterTap() {
        guard let cameraService = cameraService else { return }
        
        let focusPoint = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        cameraService.focus(at: focusPoint) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard let self = self,
                      let frame = cameraService.getCurrentFrame() else { return }
                
                // Create screenshot with proper orientation
                let screenshot: UIImage
                if UIDevice.current.orientation.isLandscape {
                    if UIDevice.current.orientation == .landscapeLeft {
                        screenshot = UIImage(cgImage: frame.cgImage!, scale: 1.0, orientation: .left)
                    } else {
                        screenshot = UIImage(cgImage: frame.cgImage!, scale: 1.0, orientation: .right)
                    }
                } else {
                    screenshot = UIImage(cgImage: frame.cgImage!, scale: 1.0, orientation: .up)
                }
                
                // Display screenshot with proper fitting
                let imageView = UIImageView(image: screenshot)
                imageView.contentMode = .scaleAspectFit
                self.adjustImageViewFrame(imageView, for: screenshot)
                
                self.view.insertSubview(imageView, at: 0)
                self.screenshotImageView = imageView
                
                // Hide camera preview
                self.previewLayer?.isHidden = true
                
                // Show selection view and buttons
                let selectionVC = SelectionViewController()
                self.addChild(selectionVC)
                selectionVC.view.frame = self.view.bounds
                self.view.insertSubview(selectionVC.view, at: 1)
                selectionVC.didMove(toParent: self)
                self.selectionViewController = selectionVC
                
                // Animate button transition
                UIView.transition(from: self.shutterButton,
                                to: self.backButton,
                                duration: 0.3,
                                options: [.transitionFlipFromLeft, .showHideTransitionViews],
                                completion: nil)
                
                // Show crop and translate buttons
                self.cropButton.isHidden = false
                self.translateButton.isHidden = false
                
                // When showing screenshot, hide shutter and show back/translate
                self.shutterButton.isHidden = true
                self.backButton.isHidden = false
            }
        }
    }
    
    private func adjustImageViewFrame(_ imageView: UIImageView, for image: UIImage) {
        let aspectRatio = image.size.width / image.size.height
        let screenRatio = view.bounds.width / view.bounds.height
        
        if aspectRatio > screenRatio {
            // Image is wider than screen
            let height = view.bounds.width / aspectRatio
            imageView.frame = CGRect(
                x: 0,
                y: (view.bounds.height - height) / 2,
                width: view.bounds.width,
                height: height
            )
        } else {
            // Image is taller than screen
            let width = view.bounds.height * aspectRatio
            imageView.frame = CGRect(
                x: (view.bounds.width - width) / 2,
                y: 0,
                width: width,
                height: view.bounds.height
            )
        }
    }
    
    @objc private func handleBackTap() {
        // Remove selection view
        selectionViewController?.willMove(toParent: nil)
        selectionViewController?.view.removeFromSuperview()
        selectionViewController?.removeFromParent()
        selectionViewController = nil
        
        // Hide crop and translate buttons
        cropButton.isHidden = true
        translateButton.isHidden = true
        
        // Animate button transition back
        UIView.transition(from: backButton,
                         to: shutterButton,
                         duration: 0.3,
                         options: [.transitionFlipFromRight, .showHideTransitionViews],
                         completion: nil)
        
        // Remove screenshot and show camera
        screenshotImageView?.removeFromSuperview()
        screenshotImageView = nil
        previewLayer?.isHidden = false
    }
    
    @objc private func handleTranslateTap() {
        guard let screenshot = screenshotImageView?.image else { return }
        
        // Start loading indicator
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .label
        activityIndicator.startAnimating()
        
        // Setup bottom sheet
        let sheet = UIView()
        sheet.backgroundColor = .systemBackground
        sheet.layer.cornerRadius = 15
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.layer.shadowColor = UIColor.black.cgColor
        sheet.layer.shadowOffset = CGSize(width: 0, height: -2)
        sheet.layer.shadowRadius = 5
        sheet.layer.shadowOpacity = 0.1
        
        // Add pan gesture for swipe-to-dismiss
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSheetPan(_:)))
        sheet.addGestureRecognizer(panGesture)
        
        // Configure text label
        let textLabel = UILabel()
        textLabel.numberOfLines = 0
        textLabel.font = .systemFont(ofSize: 16)
        textLabel.textColor = .label
        textLabel.text = "Recognizing text..."
        
        // Configure scroll view
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        scrollView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        // Add views to hierarchy
        scrollView.addSubview(textLabel)
        sheet.addSubview(scrollView)
        sheet.addSubview(activityIndicator)
        view.addSubview(sheet)
        
        // Add close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.addTarget(self, action: #selector(closeResultSheet), for: .touchUpInside)
        sheet.addSubview(closeButton)
        
        // Layout
        sheet.frame = CGRect(x: 0, y: view.bounds.height,
                            width: view.bounds.width,
                            height: view.bounds.height / 2)
        
        closeButton.frame = CGRect(x: view.bounds.width - 50, y: 10, width: 30, height: 30)
        
        // Configure scroll view frame
        let scrollViewTopPadding: CGFloat = 50
        scrollView.frame = CGRect(x: 0,
                                y: scrollViewTopPadding,
                                width: sheet.bounds.width,
                                height: sheet.bounds.height - scrollViewTopPadding - 10)
        
        // Configure text label frame
        let horizontalPadding: CGFloat = 20
        textLabel.frame = CGRect(x: horizontalPadding,
                               y: 0,
                               width: scrollView.bounds.width - (horizontalPadding * 2),
                               height: 0)
        
        activityIndicator.center = CGPoint(x: sheet.bounds.width/2, y: 100)
        
        // Animate sheet presentation
        UIView.animate(withDuration: 0.3) {
            sheet.frame.origin.y = self.view.bounds.height - sheet.bounds.height
        }
        
        resultSheet = sheet
        recognizedTextLabel = textLabel
        
        // Perform text recognition
        recognizeText(in: screenshot) { [weak self] recognizedText in
            DispatchQueue.main.async {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
                
                if let text = recognizedText {
                    textLabel.text = text
                    // Update layout after text is set
                    textLabel.sizeToFit()
                    scrollView.contentSize = CGSize(
                        width: scrollView.bounds.width,
                        height: textLabel.frame.height + 20 // Add some padding
                    )
                } else {
                    textLabel.text = "No text found in image"
                    textLabel.sizeToFit()
                    scrollView.contentSize = CGSize(
                        width: scrollView.bounds.width,
                        height: textLabel.frame.height + 20
                    )
                }
            }
        }
    }
    
    private func recognizeText(in image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        // Create a new image-request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Create a new request to recognize text
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Failed to recognize text: \(error)")
                completion(nil)
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            
            // Combine all recognized text
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            completion(recognizedText.isEmpty ? nil : recognizedText)
        }
        
        // Configure the recognition level
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            // Perform the text-recognition request
            try requestHandler.perform([request])
        } catch {
            print("Failed to perform recognition: \(error)")
            completion(nil)
        }
    }
    
    @objc private func closeResultSheet() {
        UIView.animate(withDuration: 0.3) {
            self.resultSheet?.frame.origin.y = self.view.bounds.height
        } completion: { _ in
            self.resultSheet?.removeFromSuperview()
            self.resultSheet = nil
            self.recognizedTextLabel = nil
        }
    }
    
    @objc private func handleCropTap() {
        guard let screenshot = screenshotImageView?.image else { return }
        
        let cropViewController = TOCropViewController(image: screenshot)
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    // Add orientation change handling
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { [weak self] _ in
            guard let self = self else { return }
            
            // Update button layout
            self.setupButtons()
            
            // Restore button visibility states if in screenshot mode
            if self.screenshotImageView != nil {
                self.shutterButton.isHidden = true
                self.backButton.isHidden = false
                self.cropButton.isHidden = false
                self.translateButton.isHidden = false
                
                // Ensure proper z-index
                self.view.bringSubviewToFront(self.cropButton)
                self.view.bringSubviewToFront(self.backButton)
                self.view.bringSubviewToFront(self.translateButton)
            }
            
            // Adjust screenshot image view frame if it exists
            if let imageView = self.screenshotImageView,
               let image = imageView.image {
                self.adjustImageViewFrame(imageView, for: image)
            }
        }
    }
    
    // Add this new method to handle the pan gesture
    @objc private func handleSheetPan(_ gesture: UIPanGestureRecognizer) {
        guard let sheet = resultSheet else { return }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            // Only allow downward dragging
            if translation.y >= 0 {
                sheet.frame.origin.y = view.bounds.height - sheet.bounds.height + translation.y
            }
            
        case .ended:
            let sheetHeight = sheet.bounds.height
            let currentPosition = sheet.frame.origin.y
            let dismissThreshold = view.bounds.height - (sheetHeight * 0.7)
            
            // Dismiss if dragged past threshold or flicked down with sufficient velocity
            if currentPosition > dismissThreshold || velocity.y > 500 {
                UIView.animate(withDuration: 0.2, animations: {
                    sheet.frame.origin.y = self.view.bounds.height
                }) { _ in
                    self.closeResultSheet()
                }
            } else {
                // Return to original position
                UIView.animate(withDuration: 0.2) {
                    sheet.frame.origin.y = self.view.bounds.height - sheetHeight
                }
            }
            
        default:
            break
        }
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

// Add UIImagePickerController delegate methods
extension CameraPreviewViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            // Update screenshot with cropped image
            screenshotImageView?.image = editedImage
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// Move the TOCropViewControllerDelegate extension outside the class
extension CameraPreviewViewController: TOCropViewControllerDelegate {
    func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        // Update screenshot with cropped image
        screenshotImageView?.image = image
        screenshotImageView?.contentMode = .scaleAspectFit  // Change to fit instead of fill
        
        // Adjust frame to show entire cropped image
        if let imageView = screenshotImageView {
            let aspectRatio = image.size.width / image.size.height
            let screenRatio = view.bounds.width / view.bounds.height
            
            if aspectRatio > screenRatio {
                // Image is wider than screen
                let height = view.bounds.width / aspectRatio
                imageView.frame = CGRect(
                    x: 0,
                    y: (view.bounds.height - height) / 2,
                    width: view.bounds.width,
                    height: height
                )
            } else {
                // Image is taller than screen
                let width = view.bounds.height * aspectRatio
                imageView.frame = CGRect(
                    x: (view.bounds.width - width) / 2,
                    y: 0,
                    width: width,
                    height: view.bounds.height
                )
            }
        }
        
        cropViewController.dismiss(animated: true)
    }
    
    func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        cropViewController.dismiss(animated: true)
    }
} 
