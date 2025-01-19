import SwiftUI
import AVFoundation

struct MainView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var textRecognitionService = TextRecognitionService()
    @State private var isLanguageMenuShowing = false
    @State private var sourceLanguage = Language.autoDetect
    @State private var targetLanguage = Language.english
    
    var body: some View {
        ZStack {
            if cameraService.cameraPermissionGranted {
                CameraPreviewView(
                    cameraService: cameraService,
                    textBoxes: textRecognitionService.textBoxes
                )
                .edgesIgnoringSafeArea(.all)
                
                // UI Elements
                VStack {
                    // Top bar with language selection
                    HStack {
                        Button(action: { isLanguageMenuShowing.toggle() }) {
                            HStack {
                                Image(systemName: "line.horizontal.3")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("\(sourceLanguage.name) → \(targetLanguage.name)")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Bottom text display
                    if !textRecognitionService.detectedText.isEmpty {
                        VStack {
                            Text("Detected Text:")
                                .foregroundColor(.white)
                                .font(.headline)
                            Text(textRecognitionService.detectedText)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding()
                    } else {
                        Text("No text detected - Point camera at text")
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.yellow)
                            .cornerRadius(10)
                            .padding()
                    }
                }
                
                // Language menu
                LanguageSelectionMenu(
                    isShowing: $isLanguageMenuShowing,
                    sourceLanguage: $sourceLanguage,
                    targetLanguage: $targetLanguage
                )
            } else {
                VStack {
                    Text("Camera Access Required")
                        .font(.title)
                    Text("Please enable camera access in Settings to use this app.")
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .onAppear {
            cameraService.textRecognitionService = textRecognitionService
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
} 