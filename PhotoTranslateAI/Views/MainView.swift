import SwiftUI
import AVFoundation

struct MainView: View {
    @StateObject private var cameraService = CameraService()
    @State private var isMenuOpen = false
    @State private var isAutoDetectEnabled = false
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(cameraService: cameraService)
                .edgesIgnoringSafeArea(.all)
            
            // Menu button
            VStack {
                HStack {
                    Button(action: { isMenuOpen.toggle() }) {
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Auto-detect toggle
                    Button(action: { isAutoDetectEnabled.toggle() }) {
                        Text(isAutoDetectEnabled ? "Auto ON" : "Auto OFF")
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(20)
                    }
                    .padding()
                }
                Spacer()
            }
            
            // Side menu
            if isMenuOpen {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        isMenuOpen = false
                    }
                
                HStack {
                    MenuView()
                        .frame(width: 250)
                        .background(Color(.systemBackground))
                        .offset(x: isMenuOpen ? 0 : -250)
                        .animation(.default, value: isMenuOpen)
                    
                    Spacer()
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
} 