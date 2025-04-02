import SwiftUI
import GoogleSignIn
import CoreLocation
import MapKit

struct ContentView: View {
    // Authentication manager to handle Google Sign-in
    @StateObject private var authManager = AuthenticationManager()
    
    // Location manager to handle user location
    @StateObject private var locationManager = LocationManager()
    
    // User name from Google Sign-in or default value
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "User"
    
    // Add state for location permission alert
    @State private var showLocationAlert = false
    
    // Add state for navigation
    @State private var showingParkingLocations = false
    
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
    
    // Get time-based message with consistent pattern
    private var timeMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Using consistent pattern of hour ranges with clear boundaries
        // Late night/early morning (10PM-5AM)
        if hour >= 22 || hour < 5 {
            return "Drive safely, \(userName)"
        }
        // Early morning (5AM-7AM)
        else if hour >= 5 && hour < 7 {
            return "Early bird, \(userName)"
        }
        // Morning coffee time (7AM-9AM)
        else if hour >= 7 && hour < 9 {
            return "Need coffee, \(userName)"
        }
        // Standard morning (9AM-12PM)
        else if hour >= 9 && hour < 12 {
            return "Good morning, \(userName)"
        }
        // Lunch time (12PM-1PM)
        else if hour >= 12 && hour < 13 {
            return "Lunch time, \(userName)"
        }
        // Post-lunch slump (1PM-3PM)
        else if hour >= 13 && hour < 15 {
            return "Afternoon slump, \(userName)"
        }
        // Afternoon (3PM-5PM)
        else if hour >= 15 && hour < 17 {
            return "Good afternoon, \(userName)"
        }
        // Rush hour special message (5PM-7PM)
        else if hour >= 17 && hour < 19 {
            return "Rush hour survivor, \(userName)"
        }
        // Evening (7PM-10PM)
        else if hour >= 19 && hour < 22 {
            return "Good evening, \(userName)"
        }
        // Final catch-all (shouldn't reach here with above conditions)
        else {
            return "Hello, \(userName)" // Fallback for any unexpected cases
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Yellow background
                Color(hex: "fffc00")
                    .ignoresSafeArea()
                
                // Content based on authentication state
                if authManager.isAuthenticated {
                    // Main app content for authenticated users
                    authenticatedContent(geometry: geometry)
                } else {
                    // Sign-in screen for unauthenticated users
                    unauthenticatedContent(geometry: geometry)
                }
            }
        }
        .onAppear {
            // Update userName when the view appears
            self.userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
            
            // Add observer for changes to UserDefaults
            NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { _ in
                self.userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
            }
            
            // Request location permission when the view appears
            locationManager.requestLocationPermission()
        }
        .alert(isPresented: $showLocationAlert) {
            Alert(
                title: Text("Location Access Required"),
                message: Text("Lotcation needs access to your location to find nearby parking. Please grant permission in Settings."),
                primaryButton: .default(Text("Open Settings"), action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }),
                secondaryButton: .cancel()
            )
        }
        .fullScreenCover(isPresented: $showingParkingLocations) {
            ParkingLocationsView(locationManager: locationManager)
        }
    }
    
    // Authenticated user view
    private func authenticatedContent(geometry: GeometryProxy) -> some View {
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
            
            
            // Find parking button with location status
            Button(action: {
                if locationManager.isAuthorized {
                    // Present parking locations screen
                    showingParkingLocations = true
                } else {
                    // Show alert if location permissions aren't granted
                    showLocationAlert = true
                }
            }) {
                VStack {
                    Text("Find Lotcations")
                        .font(.custom("Noto Sans", size: buttonTextSize).bold())
                        .foregroundColor(.black)
                    
                    // Location status indicator
                    if locationManager.authorizationStatus == .notDetermined {
                        Text("Location: Not requested")
                            .font(.custom("Noto Sans", size: 14))
                            .foregroundColor(.gray)
                    } else if locationManager.isAuthorized {
                        Text("Location: Available")
                            .font(.custom("Noto Sans", size: 14))
                            .foregroundColor(.green)
                    } else {
                        Text("Location: Permission denied")
                            .font(.custom("Noto Sans", size: 14))
                            .foregroundColor(.red)
                    }
                }
                .frame(width: geometry.size.width * 0.85, height: 198) // Increased by 10% from 180
                .background(Color.white)
                .cornerRadius(10)
            }
            .padding(.bottom, 20)
            
            // Emergency parking button (Feature #7 from my plan)
            /**
            Button(action: {
                if locationManager.isAuthorized {
                    // Find immediate parking action
                    print("Finding immediate parking at: \(locationManager.location?.coordinate ?? CLLocationCoordinate2D())")
                } else {
                    // Show alert if location permissions aren't granted
                    showLocationAlert = true
                }
            }) {
             */
            
            Button(action: {
                if locationManager.isAuthorized {
                    // For immediate parking, find the closest available spot
                    if let userLocation = locationManager.location {
                        let mockService = MockParkingService()
                        
                        // Find closest spot
                        if let closestLocation = mockService.getClosestParkingLocation(to: userLocation) {
                            // Open Maps for immediate navigation to closest spot
                            let coordinate = closestLocation.coordinates
                            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                            mapItem.name = closestLocation.name
                            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                        } else {
                            // Fallback to showing all options if we couldn't find a closest spot
                            showingParkingLocations = true
                        }
                    } else {
                        // No location available, just show options
                        showingParkingLocations = true
                    }
                } else {
                    // Show alert if location permissions aren't granted
                    showLocationAlert = true
                }
            }) {
                Text("Immediate Parking")
                    .font(.custom("Noto Sans", size: buttonTextSize).bold())
                    .foregroundColor(.white)
                    .frame(width: geometry.size.width * 0.85, height: 198)
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
            
            // Sign Out button
            Button(action: {
                authManager.signOut()
            }) {
                Text("Sign Out")
                    .font(.custom("Noto Sans", size: 16))
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
            }
            .padding(.bottom, 16)
        }
        .padding()
    }
    
    // Unauthenticated user view (sign-in screen)
    private func unauthenticatedContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 40) {
            // App title
            Text("Lotcation")
                .font(.custom("Noto Sans", size: titleSize).bold())
                .foregroundColor(.black)
                .padding(.top, 80)
            
            // App description
            Text("Find parking spaces quickly and safely with minimal interaction while driving")
                .font(.custom("Noto Sans", size: bodySize))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // App icon or illustration (placeholder)
            Image(systemName: "car.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.black)
            
            Spacer()
            
            // Sign-in button
            GoogleSignInButton(authManager: authManager)
                .padding(.bottom, 50)
        }
        .padding()
    }
}
