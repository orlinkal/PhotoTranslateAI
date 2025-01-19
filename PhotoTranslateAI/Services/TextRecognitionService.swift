import Vision
import AVFoundation

class TextRecognitionService: NSObject, ObservableObject {
    @Published var detectedText: String = "No text recognized"
    @Published var textBoxes: [CGRect] = []
    
    private var textRecognitionRequest: VNRecognizeTextRequest?
    
    override init() {
        super.init()
        setupVision()
    }
    
    private func setupVision() {
        textRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            
            var recognizedText: [String] = []
            var recognizedBoxes: [CGRect] = []
            
            for observation in observations {
                if let candidate = observation.topCandidates(1).first,
                   candidate.confidence > 0.5 {
                    recognizedText.append(candidate.string)
                    recognizedBoxes.append(observation.boundingBox)
                }
            }
            
            DispatchQueue.main.async {
                if !recognizedText.isEmpty {
                    self?.detectedText = recognizedText.joined(separator: "\n")
                    self?.textBoxes = recognizedBoxes
                }
            }
        }
        
        textRecognitionRequest?.recognitionLevel = .accurate
        textRecognitionRequest?.usesLanguageCorrection = true
    }
    
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .right,  // Back to .right since we're in portrait mode
            options: [:]
        )
        
        do {
            try imageRequestHandler.perform([textRecognitionRequest].compactMap { $0 })
        } catch {
            print("Failed to perform recognition: \(error)")
        }
    }
} 