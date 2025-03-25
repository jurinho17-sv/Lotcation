import SwiftUI

struct SplashScreenView: View {
    // Binding to connect with parent view
    @Binding var showSplash: Bool
    
    @State private var isAnimating = false
    @State private var parkingOpacity = 1.0
    @State private var loOpacity = 1.0
    
    // Position and opacity for the moving parts
    @State private var lotOffset: CGSize = .zero
    @State private var cationOffset: CGSize = .zero
    @State private var lotOpacity = 1.0
    @State private var cationOpacity = 1.0
    
    // Font settings
    let fontSize: CGFloat = 42
    
    var body: some View {
        ZStack {
            // Yellow background
            Color(hex: "fffc00").edgesIgnoringSafeArea(.all)
            
            ZStack {
                // This positions our text properly
                VStack(spacing: 20) {
                    // Parking text
                    HStack(spacing: 0) {
                        Text("Parking ")
                            .font(.custom("Noto Sans", size: fontSize).bold())
                            .foregroundColor(.black)
                            .opacity(parkingOpacity)
                        
                        // "Lot" text that will move
                        Text("Lot")
                            .font(.custom("Noto Sans", size: fontSize).bold())
                            .foregroundColor(.black)
                            .opacity(lotOpacity)
                            .offset(lotOffset)
                    }
                    
                    // Location text
                    HStack(spacing: 0) {
                        Text("Lo")
                            .font(.custom("Noto Sans", size: fontSize).bold())
                            .foregroundColor(.black)
                            .opacity(loOpacity)
                        
                        // "cation" text that will move
                        Text("cation")
                            .font(.custom("Noto Sans", size: fontSize).bold())
                            .foregroundColor(.black)
                            .opacity(cationOpacity)
                            .offset(cationOffset)
                    }
                }
                
                // Static "Lotcation" in final position - now vertically centered
                Text("Lotcation")
                    .font(.custom("Noto Sans", size: fontSize).bold())
                    .foregroundColor(.black)
                    .opacity(1 - (lotOpacity + cationOpacity) / 2) // Fades in as others fade out
                    // No vertical offset to keep it perfectly centered
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            startSplashAnimation()
        }
    }
    
    private func startSplashAnimation() {
        // Begin animation sequence after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Fade out "Parking" and "Lo"
            withAnimation(.easeInOut(duration: 1.0)) {
                parkingOpacity = 0.0
                loOpacity = 0.0
            }
            
            // Begin moving "Lot" and "cation" together
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 1.5)) {
                    // Adjust movement to converge on center
                    lotOffset = CGSize(width: 0, height: 50)
                    cationOffset = CGSize(width: 0, height: -30)
                    
                    // Gradually fade out the moving parts as they reach destination
                    lotOpacity = 0.0
                    cationOpacity = 0.0
                }
                
                // Navigate to main screen after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showSplash = false
                }
            }
        }
    }
}
