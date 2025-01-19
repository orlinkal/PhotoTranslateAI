import UIKit
import AVFoundation
import Vision
import SwiftUI

class CameraPreviewViewController: UIViewController {
    var previewLayer: AVCaptureVideoPreviewLayer?
    var highlightLayers: [CAShapeLayer] = []
    private var debugLabels: [UILabel] = []
    private let showDebugInfo = true  // Toggle for debug information
    
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
        // Remove old highlight layers and debug labels
        highlightLayers.forEach { $0.removeFromSuperlayer() }
        highlightLayers.removeAll()
        debugLabels.forEach { $0.removeFromSuperview() }
        debugLabels.removeAll()
        
        // Create new highlight layers
        for (index, box) in boxes.enumerated() {
            guard let previewLayer = previewLayer else { continue }
            
            // For portrait mode:
            // 1. Swap x and y coordinates due to 90-degree rotation
            // 2. Flip coordinates to match device orientation
            // 3. Apply compensation from center to avoid offset
            let compensationFactor: CGFloat = 1.2
            let centerOffset = previewLayer.bounds.width * (compensationFactor - 1) / 2
            
            let viewBox = CGRect(
                x: (1 - box.maxY) * previewLayer.bounds.width * compensationFactor - centerOffset,
                y: (1 - box.maxX) * previewLayer.bounds.height,
                width: box.height * previewLayer.bounds.width,
                height: box.width * previewLayer.bounds.height
            )
            
            // Create highlight layer
            let highlightLayer = CAShapeLayer()
            highlightLayer.frame = previewLayer.frame
            highlightLayer.fillColor = UIColor.clear.cgColor
            highlightLayer.strokeColor = UIColor.red.cgColor
            highlightLayer.lineWidth = 2.0
            highlightLayer.opacity = 0.7
            
            let path = UIBezierPath(rect: viewBox)
            highlightLayer.path = path.cgPath
            
            previewLayer.addSublayer(highlightLayer)
            highlightLayers.append(highlightLayer)
            
            if showDebugInfo {
                // Add debug label
                let label = UILabel()
                label.text = String(format: "Box %d: (%.1f, %.1f)", index, viewBox.origin.x, viewBox.origin.y)
                label.textColor = .red
                label.font = .systemFont(ofSize: 10)
                label.frame = CGRect(x: viewBox.minX, y: viewBox.minY - 15, width: 200, height: 15)
                view.addSubview(label)
                debugLabels.append(label)
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