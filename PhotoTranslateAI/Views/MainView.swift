import SwiftUI

struct MainView: View {
    @StateObject private var cameraService = CameraService()
    
    var body: some View {
        ZStack {
            if cameraService.cameraPermissionGranted {
                CameraPreviewView(session: cameraService.session)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    if let error = cameraService.error {
                        Text("Camera Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                    } else {
                        Text("Camera Preview")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                    }
                }
                .padding(.bottom, 50)
            } else {
                Text("Camera access is required to use this app")
                    .multilineTextAlignment(.center)
                    .padding()
            }
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