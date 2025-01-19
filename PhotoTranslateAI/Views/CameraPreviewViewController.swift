import UIKit
import AVFoundation
import Vision
import SwiftUI

class CameraPreviewViewController: UIViewController {
    var previewLayer: AVCaptureVideoPreviewLayer?
    var highlightLayers: [CAShapeLayer] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }
    
    func set(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }
    
    func updateTextBoxes(_ boxes: [CGRect]) {
        // Remove old highlight layers
        highlightLayers.forEach { $0.removeFromSuperlayer() }
        highlightLayers.removeAll()
        
        // Create new highlight layers
        for box in boxes {
            // Convert normalized coordinates to view coordinates
            let viewBox = previewLayer?.layerRectConverted(fromMetadataOutputRect: box) ?? .zero
            
            let highlightLayer = CAShapeLayer()
            highlightLayer.frame = view.bounds
            highlightLayer.fillColor = UIColor.clear.cgColor
            highlightLayer.strokeColor = UIColor.yellow.cgColor
            highlightLayer.lineWidth = 2
            highlightLayer.path = UIBezierPath(rect: viewBox).cgPath
            
            if let previewLayer = previewLayer {
                previewLayer.addSublayer(highlightLayer)
                highlightLayers.append(highlightLayer)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        
        // Update highlight layers frames
        highlightLayers.forEach { $0.frame = view.bounds }
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
        return controller
    }
    
    func updateUIViewController(_ controller: CameraPreviewViewController, context: Context) {
        controller.updateTextBoxes(textBoxes)
    }
} 