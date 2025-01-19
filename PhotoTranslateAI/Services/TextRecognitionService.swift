import Vision
import AVFoundation
import UIKit

extension Notification.Name {
    static let didUpdateTextBoxes = Notification.Name("didUpdateTextBoxes")
}

class TextRecognitionService: NSObject, ObservableObject {
    @Published var detectedText: String = "No text recognized"
    @Published var textBoxes: [CGRect] = []
    
    private var textRecognitionRequest: VNRecognizeTextRequest?
    private var previousBoxes: [CGRect] = []  // Store previous frame's boxes
    private var stableFrameCount: [CGRect: Int] = [:]  // Track how long each box has been stable
    private let stabilityThreshold = 10  // Number of frames before accepting a new box
    private let boxSimilarityThreshold: CGFloat = 0.7  // How similar boxes need to be to be considered the same
    
    // Adjusted thresholds for better zone detection
    private let verticalMergeThreshold: CGFloat = 0.1
    private let horizontalMergeThreshold: CGFloat = 0.1
    private let minimumTextHeight: Float = 0.015
    private let maximumZoneGap: CGFloat = 0.15
    private let minimumZoneArea: CGFloat = 0.01  // Minimum area for a text zone
    
    override init() {
        super.init()
        setupVision()
    }
    
    private func setupVision() {
        textRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  !observations.isEmpty else { return }
            
            let significantObservations = observations.filter { $0.boundingBox.height >= CGFloat(self?.minimumTextHeight ?? 0.015) }
            let adjustedBoxes = significantObservations.map { observation in
                self?.adjustForDeviceOrientation(observation.boundingBox) ?? observation.boundingBox
            }
            
            let mergedBoxes = self?.mergeTextBoxes(adjustedBoxes) ?? []
            let stableBoxes = self?.stabilizeBoxes(mergedBoxes) ?? []
            
            DispatchQueue.main.async {
                self?.textBoxes = stableBoxes
                NotificationCenter.default.post(
                    name: .didUpdateTextBoxes,
                    object: nil,
                    userInfo: ["boxes": stableBoxes]
                )
            }
        }
        
        textRecognitionRequest?.recognitionLevel = .accurate
        textRecognitionRequest?.minimumTextHeight = minimumTextHeight
        textRecognitionRequest?.recognitionLanguages = ["en-US"]
    }
    
    private func adjustForDeviceOrientation(_ boundingBox: CGRect) -> CGRect {
        let orientation = UIDevice.current.orientation
        
        switch orientation {
        case .portrait, .unknown, .faceUp, .faceDown:
            // Convert from Vision coordinates to AVFoundation coordinates
            return CGRect(
                x: boundingBox.minY,
                y: 1 - boundingBox.minX - boundingBox.width,
                width: boundingBox.height,
                height: boundingBox.width
            )
        case .portraitUpsideDown:
            return CGRect(
                x: 1 - boundingBox.minY - boundingBox.height,
                y: boundingBox.minX,
                width: boundingBox.height,
                height: boundingBox.width
            )
        case .landscapeLeft:
            return boundingBox
        case .landscapeRight:
            return CGRect(
                x: 1 - boundingBox.minX - boundingBox.width,
                y: 1 - boundingBox.minY - boundingBox.height,
                width: boundingBox.width,
                height: boundingBox.height
            )
        @unknown default:
            return boundingBox
        }
    }
    
    private func shouldMergeBoxes(_ box1: CGRect, _ box2: CGRect) -> Bool {
        // Check if boxes overlap or are very close
        let verticalOverlap = min(box1.maxY, box2.maxY) - max(box1.minY, box2.minY)
        let horizontalOverlap = min(box1.maxX, box2.maxX) - max(box1.minX, box2.minX)
        
        let verticalGap = verticalOverlap < 0 ? -verticalOverlap : 0
        let horizontalGap = horizontalOverlap < 0 ? -horizontalOverlap : 0
        
        // Check if boxes are close enough to be in the same zone
        let isCloseVertically = verticalGap < verticalMergeThreshold
        let isCloseHorizontally = horizontalGap < horizontalMergeThreshold
        
        // Check if boxes overlap in either direction
        let hasVerticalOverlap = verticalOverlap > 0
        let hasHorizontalOverlap = horizontalOverlap > 0
        
        // Merge if boxes overlap in one direction and are close in the other
        return (hasVerticalOverlap && isCloseHorizontally) || 
               (hasHorizontalOverlap && isCloseVertically) ||
               (isCloseVertically && isCloseHorizontally)
    }
    
    private func mergeTextBoxes(_ boxes: [CGRect]) -> [CGRect] {
        // First, group boxes into clusters
        var clusters: [[CGRect]] = []
        var remainingBoxes = boxes
        
        while !remainingBoxes.isEmpty {
            var currentCluster: [CGRect] = [remainingBoxes.removeFirst()]
            var didAddToCluster: Bool
            
            repeat {
                didAddToCluster = false
                var boxesToRemove: [Int] = []
                
                // Try to add remaining boxes to current cluster
                for (index, box) in remainingBoxes.enumerated() {
                    // Check if box should be added to cluster
                    if currentCluster.contains(where: { shouldMergeBoxes($0, box) }) {
                        currentCluster.append(box)
                        boxesToRemove.append(index)
                        didAddToCluster = true
                    }
                }
                
                // Remove added boxes
                for index in boxesToRemove.sorted(by: >) {
                    remainingBoxes.remove(at: index)
                }
                
            } while didAddToCluster
            
            clusters.append(currentCluster)
        }
        
        // Convert clusters to merged boxes
        return clusters.compactMap { cluster -> CGRect? in
            guard !cluster.isEmpty else { return nil }
            
            // Create a single box for each cluster
            let minX = cluster.map { $0.minX }.min()!
            let minY = cluster.map { $0.minY }.min()!
            let maxX = cluster.map { $0.maxX }.max()!
            let maxY = cluster.map { $0.maxY }.max()!
            
            let mergedBox = CGRect(
                x: minX,
                y: minY,
                width: maxX - minX,
                height: maxY - minY
            )
            
            // Only include zones that are large enough
            return mergedBox.width * mergedBox.height >= minimumZoneArea ? mergedBox : nil
        }
    }
    
    private func stabilizeBoxes(_ newBoxes: [CGRect]) -> [CGRect] {
        var stableBoxes: [CGRect] = []
        
        // Update stability count for each box
        for newBox in newBoxes {
            if let (existingBox, _) = stableFrameCount.first(where: { areBoxesSimilar($0.key, newBox) }) {
                stableFrameCount[existingBox, default: 0] += 1
                if stableFrameCount[existingBox, default: 0] >= stabilityThreshold {
                    stableBoxes.append(smoothBox(existingBox, with: newBox))
                }
            } else {
                stableFrameCount[newBox] = 1
            }
        }
        
        // Remove boxes that are no longer detected
        stableFrameCount = stableFrameCount.filter { box, count in
            if newBoxes.contains(where: { areBoxesSimilar(box, $0) }) {
                return true
            }
            return count >= stabilityThreshold
        }
        
        // If no stable boxes yet, use the current boxes
        if stableBoxes.isEmpty && !newBoxes.isEmpty {
            stableBoxes = newBoxes
        }
        
        previousBoxes = stableBoxes
        return stableBoxes
    }
    
    private func areBoxesSimilar(_ box1: CGRect, _ box2: CGRect) -> Bool {
        let centerDistance = hypot(box1.midX - box2.midX, box1.midY - box2.midY)
        let averageSize = (box1.width + box1.height + box2.width + box2.height) / 4
        
        return centerDistance < averageSize * (1 - boxSimilarityThreshold)
    }
    
    private func smoothBox(_ oldBox: CGRect, with newBox: CGRect) -> CGRect {
        // Smoothly interpolate between old and new box positions
        let smoothingFactor: CGFloat = 0.7  // Higher value = more smoothing
        
        return CGRect(
            x: oldBox.origin.x * smoothingFactor + newBox.origin.x * (1 - smoothingFactor),
            y: oldBox.origin.y * smoothingFactor + newBox.origin.y * (1 - smoothingFactor),
            width: oldBox.width * smoothingFactor + newBox.width * (1 - smoothingFactor),
            height: oldBox.height * smoothingFactor + newBox.height * (1 - smoothingFactor)
        )
    }
    
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            .perform([textRecognitionRequest].compactMap { $0 })
    }
} 
