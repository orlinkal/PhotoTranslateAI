import SwiftUI
import UIKit

class SelectionViewController: UIViewController {
    private var screenshotImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScreenshotView()
    }
    
    private func setupScreenshotView() {
        screenshotImageView = UIImageView(frame: view.bounds)
        screenshotImageView.contentMode = .scaleAspectFill
        view.addSubview(screenshotImageView)
    }
    
    func setScreenshot(_ image: UIImage) {
        screenshotImageView.image = image
    }
    
    func getSelectionRect() -> CGRect {
        // Return the entire visible area
        return view.bounds
    }
}

// Standard Apple-style crop overlay
class CropOverlayView: UIView {
    override func draw(_ rect: CGRect) {
        // Draw grid lines
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setLineWidth(1.0)
        
        // Draw thirds
        let thirdWidth = bounds.width / 3
        let thirdHeight = bounds.height / 3
        
        for i in 1...2 {
            let x = thirdWidth * CGFloat(i)
            let y = thirdHeight * CGFloat(i)
            
            // Vertical lines
            context?.move(to: CGPoint(x: x, y: 0))
            context?.addLine(to: CGPoint(x: x, y: bounds.height))
            
            // Horizontal lines
            context?.move(to: CGPoint(x: 0, y: y))
            context?.addLine(to: CGPoint(x: bounds.width, y: y))
        }
        
        context?.strokePath()
    }
}

// Standard resize control using UIInteractiveTransition
class ResizeControl: UIView {
    weak var delegate: UIViewController?
    
    private var initialBounds = CGRect.zero
    private var initialCenter = CGPoint.zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        isUserInteractionEnabled = true
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        
        switch gesture.state {
        case .began:
            initialBounds = superview.bounds
            initialCenter = superview.center
            
        case .changed:
            let translation = gesture.translation(in: self)
            let newBounds = CGRect(
                x: initialBounds.origin.x,
                y: initialBounds.origin.y,
                width: initialBounds.width + translation.x,
                height: initialBounds.height + translation.y
            )
            
            // Apply minimum size and maximum size constraints
            let minSize: CGFloat = 100
            let maxSize = UIScreen.main.bounds.size
            
            var constrainedBounds = newBounds
            constrainedBounds.size.width = min(max(minSize, constrainedBounds.width), maxSize.width)
            constrainedBounds.size.height = min(max(minSize, constrainedBounds.height), maxSize.height)
            
            superview.bounds = constrainedBounds
            
            // Keep the selection centered
            superview.center = initialCenter
            
        default:
            break
        }
    }
} 
