import Vision
import AVFoundation
import UIKit

class TextRecognitionService: NSObject, ObservableObject {
    @Published var detectedText: String = "No text recognized"
    @Published var textBoxes: [CGRect] = []
    
    private var textRecognitionRequest: VNRecognizeTextRequest?
    
    // Parameters for merging text boxes
    private let horizontalMergeThreshold: CGFloat = 0.05  // Max horizontal gap (5% of image width)
    private let verticalMergeThreshold: CGFloat = 0.02    // Max vertical gap (2% of image height)
    
    override init() {
        super.init()
        setupVision()
    }
    
    private func mergeTextBoxes(_ boxes: [CGRect]) -> [CGRect] {
        var mergedBoxes: [CGRect] = []
        var remainingBoxes = boxes
        
        while !remainingBoxes.isEmpty {
            let currentBox = remainingBoxes.removeFirst()
            var mergedBox = currentBox
            var didMerge = true
            
            while didMerge {
                didMerge = false
                remainingBoxes = remainingBoxes.filter { box in
                    // Check if boxes are close enough to merge
                    let horizontalGap = min(abs(mergedBox.maxX - box.minX), abs(box.maxX - mergedBox.minX))
                    let verticalGap = min(abs(mergedBox.maxY - box.minY), abs(box.maxY - mergedBox.minY))
                    
                    let shouldMerge = (horizontalGap < horizontalMergeThreshold && 
                                     abs(mergedBox.midY - box.midY) < verticalMergeThreshold) ||
                                    (verticalGap < verticalMergeThreshold &&
                                     abs(mergedBox.midX - box.midX) < horizontalMergeThreshold)
                    
                    if shouldMerge {
                        // Merge boxes by creating a new box that encompasses both
                        mergedBox = CGRect(
                            x: min(mergedBox.minX, box.minX),
                            y: min(mergedBox.minY, box.minY),
                            width: max(mergedBox.maxX, box.maxX) - min(mergedBox.minX, box.minX),
                            height: max(mergedBox.maxY, box.maxY) - min(mergedBox.minY, box.minY)
                        )
                        didMerge = true
                        return false
                    }
                    return true
                }
            }
            
            mergedBoxes.append(mergedBox)
        }
        
        return mergedBoxes
    }
    
    private func setupVision() {
        textRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            
            // Convert observations to CGRect boxes
            let boxes = observations.compactMap { observation -> CGRect? in
                guard let candidate = observation.topCandidates(1).first,
                      candidate.confidence > 0.5 else {
                    return nil
                }
                return observation.boundingBox
            }
            
            // Merge nearby boxes
            let mergedBoxes = self?.mergeTextBoxes(boxes) ?? []
            
            DispatchQueue.main.async {
                self?.textBoxes = mergedBoxes
                
                // Update detected text (optional - you might want to modify this too)
                let recognizedText = observations.compactMap { observation -> String? in
                    guard let candidate = observation.topCandidates(1).first,
                          candidate.confidence > 0.5 else {
                        return nil
                    }
                    return candidate.string
                }
                if !recognizedText.isEmpty {
                    self?.detectedText = recognizedText.joined(separator: "\n")
                }
            }
        }
        
        textRecognitionRequest?.recognitionLevel = .accurate
        textRecognitionRequest?.usesLanguageCorrection = true
    }
    
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Get the actual image dimensions
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        print("Processing frame with dimensions: \(width)x\(height)")
        
        // Determine the correct orientation based on device orientation
        let deviceOrientation = UIDevice.current.orientation
        var orientation: CGImagePropertyOrientation = .right // Default for portrait
        
        switch deviceOrientation {
        case .portrait:
            orientation = .right
        case .portraitUpsideDown:
            orientation = .left
        case .landscapeLeft:
            orientation = .up
        case .landscapeRight:
            orientation = .down
        default:
            orientation = .right
        }
        
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [:]
        )
        
        do {
            try imageRequestHandler.perform([textRecognitionRequest].compactMap { $0 })
        } catch {
            print("Failed to perform recognition: \(error)")
        }
    }
} 
