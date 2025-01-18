import SwiftUI

struct MainView: View {
    @StateObject private var cameraService = CameraService()
    @State private var isMenuShowing = false
    @State private var sourceLanguage = Language.autoDetect
    @State private var targetLanguage = Language.english
    
    var body: some View {
        ZStack {
            if cameraService.cameraPermissionGranted {
                CameraPreviewView(session: cameraService.session)
                    .ignoresSafeArea()
                
                VStack {
                    HStack {
                        Button(action: {
                            isMenuShowing.toggle()
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding()
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    if let error = cameraService.error {
                        Text("Camera Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                    } else {
                        HStack {
                            Text("\(sourceLanguage.name) → \(targetLanguage.name)")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.bottom, 50)
            } else {
                Text("Camera access is required to use this app")
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            LanguageSelectionMenu(
                isShowing: $isMenuShowing,
                sourceLanguage: $sourceLanguage,
                targetLanguage: $targetLanguage
            )
        }
        .onDisappear {
            cameraService.stop()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
} 