import SwiftUI
import AVFoundation
import Vision

struct TextOverlayView: View {
    let textBoxes: [CGRect]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(textBoxes.enumerated()), id: \.offset) { _, box in
                    // Convert Vision coordinates to view coordinates with rotation
                    let rect = CGRect(
                        x: (1 - box.maxY) * geometry.size.width,  // Rotate and flip
                        y: box.minX * geometry.size.height,       // Rotate
                        width: box.height * geometry.size.width,  // Swap dimensions
                        height: box.width * geometry.size.height  // Swap dimensions
                    )
                    
                    Rectangle()
                        .stroke(Color.yellow, lineWidth: 2)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// Preview provider for development
struct TextOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        TextOverlayView(textBoxes: [
            CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.1),
            CGRect(x: 0.5, y: 0.5, width: 0.3, height: 0.1)
        ])
        .background(Color.black)
    }
} 