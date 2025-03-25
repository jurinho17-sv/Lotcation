import SwiftUI

struct ContentView: View {
    // Add state to store user name
    @State private var userName: String = "User" // Default value until we get actual name
    
    // Font sizes
    let titleSize: CGFloat = 32
    let headingSize: CGFloat = 24
    let bodySize: CGFloat = 18
    let buttonTextSize: CGFloat = 28 // Increased by 40% from original 20
    
    // Get day-specific message
    private var dayMessage: String {
        let weekday = Calendar.current.component(.weekday, from: Date())
        
        switch weekday {
        case 1: // Sunday
            return "Sunday funday"
        case 2: // Monday
            return "Monday blues"
        case 3: // Tuesday
            return "Taco Tuesday"
        case 4: // Wednesday
            return "Happy Humpday :)"
        case 5: // Thursday
            return "Almost Friday"
        case 6: // Friday
            return "TGIF"
        case 7: // Saturday
            return "Weekend vibes"
        default:
            return ""
        }
    }
    
    // Get time-based message
    private var timeMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour >= 22 || hour < 5 {
            return "Go to bed :), \(userName)"
        }
        // Early morning
        else if hour >= 5 && hour < 7 {
            return "Early bird, \(userName)"
        }
        // Morning coffee time
        else if hour >= 7 && hour < 9 {
            return "Need coffee, \(userName)"
        }
        // Standard morning
        else if hour < 12 {
            return "Good morning :), \(userName)"
        }
        // Lunch time
        else if hour == 12 {
            return "Lunch time, \(userName)"
        }
        // Post-lunch slump
        else if hour >= 13 && hour < 15 {
            return "Afternoon slump, \(userName)"
        }
        // Rush hour special message
        else if hour >= 17 && hour < 19 {
            return "Rush hour survivor, \(userName)"
        }
        // Standard evening
        else {
            return "Good evening :), \(userName)"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Yellow background
                Color(hex: "fffc00")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // App title
                    Text("Lotcation")
                        .font(.custom("Noto Sans", size: titleSize).bold())
                        .foregroundColor(.black)
                    
                    // Greeting section with two separate lines
                    VStack(spacing: 5) {
                        // Day-specific message on top - USING WINKY SANS FONT
                        Text(dayMessage)
                            .font(.custom("WinkySans-Regular", size: headingSize))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                        
                        // Time-based message below - USING WINKY SANS FONT
                        Text(timeMessage)
                            .font(.custom("WinkySans-Regular", size: headingSize))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: geometry.size.width * 0.9)
                    .padding(.bottom, 30)
                    
                    // Find parking button (Feature #1 from requirements)
                    // Height increased by 10%, text size increased by 40%
                    Button(action: {
                        // Find nearby parking action
                        print("Finding nearby parking...")
                    }) {
                        Text("Find Lotcations")
                            .font(.custom("Noto Sans", size: buttonTextSize).bold())
                            .foregroundColor(.black)
                            .frame(width: geometry.size.width * 0.85, height: 198) // Increased by 10% from 180
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 20)
                    
                    // Emergency parking button (Feature #7 from requirements)
                    // Height increased by 10%, text size increased by 40%, renamed button
                    Button(action: {
                        // Park now action
                        print("Finding immediate parking...")
                    }) {
                        Text("Immediate Parking")
                            .font(.custom("Noto Sans", size: buttonTextSize).bold())
                            .foregroundColor(.white)
                            .frame(width: geometry.size.width * 0.85, height: 198) // Increased by 10% from 180
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    // Recent parking history placeholder
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Recent Parking")
                            .font(.custom("Noto Sans", size: headingSize).bold())
                            .foregroundColor(.white)
                        
                        Text("No recent parking locations")
                            .font(.custom("Noto Sans", size: bodySize))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding()
            }
        }
    }
}
