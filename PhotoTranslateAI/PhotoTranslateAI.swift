import SwiftUI
import Vision

@main
struct PhotoTranslateAIApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

struct RecognizedTextBlock {
    let text: String
    let boundingBox: CGRect
    let confidence: Float
}

func recognizeText(in image: UIImage, completion: @escaping ([RecognizedTextBlock]) -> Void) {
    guard let cgImage = image.cgImage else {
        completion([])
        return
    }
    
    let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            completion([])
            return
        }
        
        // Sort observations by vertical position (top to bottom)
        let sortedObservations = observations.sorted { first, second in
            // Flip Y coordinate since Vision uses bottom-left origin
            let firstY = 1 - first.boundingBox.midY
            let secondY = 1 - second.boundingBox.midY
            
            // If on roughly the same line (within threshold), sort by X position
            if abs(firstY - secondY) < 0.02 {
                return first.boundingBox.minX < second.boundingBox.minX
            }
            return firstY < secondY
        }
        
        // Convert observations to our custom structure
        let textBlocks = sortedObservations.compactMap { observation -> RecognizedTextBlock? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            
            // Convert normalized coordinates to actual image coordinates
            let imageRect = CGRect(x: observation.boundingBox.minX * CGFloat(cgImage.width),
                                 y: (1 - observation.boundingBox.maxY) * CGFloat(cgImage.height),
                                 width: observation.boundingBox.width * CGFloat(cgImage.width),
                                 height: observation.boundingBox.height * CGFloat(cgImage.height))
            
            return RecognizedTextBlock(
                text: candidate.string,
                boundingBox: imageRect,
                confidence: candidate.confidence
            )
        }
        
        completion(textBlocks)
    }
    
    // Configure for accurate text recognition
    request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["en-US"] // Add more languages as needed
    
    // Enable detection of multiple languages
    request.customWords = []
    request.minimumTextHeight = 0.01 // Detect even small text
    
    let handler = VNImageRequestHandler(cgImage: cgImage)
    try? handler.perform([request])
}

// Function to format recognized text blocks into structured text
func formatRecognizedText(_ blocks: [RecognizedTextBlock]) -> String {
    var formattedText = ""
    var currentY: CGFloat = -1
    let lineSpacingThreshold: CGFloat = 10 // Adjust based on your needs
    
    for block in blocks {
        if currentY == -1 {
            // First line
            formattedText += block.text
        } else {
            let yDiff = abs(block.boundingBox.minY - currentY)
            
            if yDiff < lineSpacingThreshold {
                // Same line - add space
                formattedText += " " + block.text
            } else if yDiff < lineSpacingThreshold * 2 {
                // New line
                formattedText += "\n" + block.text
            } else {
                // New paragraph
                formattedText += "\n\n" + block.text
            }
        }
        
        currentY = block.boundingBox.minY
    }
    
    return formattedText
} 