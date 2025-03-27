import SwiftUI
import CoreLocation
import MapKit

/**
 * ParkingLocationsView
 *
 * Main view for displaying parking locations in Pasadena.
 * Features:
 * - Toggle between map and list views
 * - Shows real-time parking availability
 * - Allows selection of parking locations for details
 * - Provides user reporting functionality
 */
struct ParkingLocationsView: View {
    // Service that provides parking data
    @ObservedObject var parkingService = MockParkingService()
    
    // Service that handles user location
    @ObservedObject var locationManager: LocationManager
    
    // UI state management
    @State private var selectedParkingLocation: ParkingLocation?
    @State private var showingParkingDetails = false
    @State private var showingMap = false
    
    // Navigation management
    @Environment(\.dismiss) private var dismiss
    
    // Font sizes for consistent UI
    let titleSize: CGFloat = 24
    let subtitleSize: CGFloat = 18
    let bodySize: CGFloat = 16
    
    var body: some View {
        ZStack {
            // Yellow background matching the app's color scheme
            Color(hex: "fffc00")
                .ignoresSafeArea()
            
            VStack {
                // MARK: - Header Bar
                HStack {
                    // Back button with dismiss functionality
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    // Title showing the current location focus
                    Text("Parking in Pasadena")
                        .font(.custom("Noto Sans", size: titleSize).bold())
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // Toggle button between map and list views
                    Button(action: {
                        showingMap.toggle()
                    }) {
                        Image(systemName: showingMap ? "list.bullet" : "map")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                    .padding(.trailing)
                }
                .padding(.vertical)
                
                // MARK: - Content Area (Map or List)
                if showingMap {
                    // MARK: Map View
                    ParkingMapView(
                        parkingLocations: parkingService.parkingLocations,
                        userLocation: locationManager.location,
                        selectedLocation: $selectedParkingLocation
                    )
                    .ignoresSafeArea(edges: .bottom)
                    .onTapGesture {
                        // Show details when a location is selected
                        if selectedParkingLocation != nil {
                            showingParkingDetails = true
                        }
                    }
                } else {
                    // MARK: List View States
                    
                    // Loading State
                    if parkingService.isLoading {
                        loadingView()
                    }
                    // Error State
                    else if let errorMessage = parkingService.errorMessage {
                        errorView(message: errorMessage)
                    }
                    // Empty State
                    else if parkingService.parkingLocations.isEmpty {
                        emptyStateView()
                    }
                    // List of Parking Locations
                    else {
                        parkingListView()
                    }
                }
            }
            // MARK: - Detail Sheet
            .sheet(isPresented: $showingParkingDetails) {
                if let location = selectedParkingLocation {
                    ParkingDetailView(
                        parkingLocation: location,
                        userLocation: locationManager.location,
                        onUpdateAvailability: { newAvailable in
                            // Update the availability when user reports new data
                            parkingService.updateAvailability(for: location.placeID, availableSpaces: newAvailable)
                        },
                        onReportFull: {
                            // Mark lot as full when reported by user
                            parkingService.reportParkingFull(for: location.placeID)
                        }
                    )
                }
            }
        }
        .onAppear {
            // Always force refresh location permissions when view appears
            locationManager.requestLocationPermission()
            
            // Start receiving location updates
            locationManager.startLocationUpdates()
            
            // Ensure we're using Pasadena location
            locationManager.resetToDefaultLocation()
            
            // Load parking data when view appears
            // Slight delay to ensure location is set
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let location = locationManager.location {
                    parkingService.findNearbyParkingLocations(location: location)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    /// Loading state view with spinner
    private func loadingView() -> some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Finding parking locations...")
                .font(.custom("Noto Sans", size: subtitleSize))
                .foregroundColor(.black)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Error state view with retry button
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text(message)
                .font(.custom("Noto Sans", size: subtitleSize))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // Try again with current location
                if let location = locationManager.location {
                    parkingService.findNearbyParkingLocations(location: location)
                } else {
                    // If no location available, force reset to Pasadena default
                    locationManager.resetToDefaultLocation()
                    
                    // Short delay then try again
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if let location = locationManager.location {
                            parkingService.findNearbyParkingLocations(location: location)
                        }
                    }
                }
            }) {
                Text("Try Again")
                    .font(.custom("Noto Sans", size: bodySize).bold())
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Empty state view when no parking locations are found
    private func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 60))
                .foregroundColor(.black.opacity(0.6))
            
            Text("No parking locations found in Pasadena")
                .font(.custom("Noto Sans", size: subtitleSize))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // Try again with current location
                if let location = locationManager.location {
                    parkingService.findNearbyParkingLocations(location: location)
                } else {
                    // Reset to default location if needed
                    locationManager.resetToDefaultLocation()
                    
                    // Short delay then try again
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if let location = locationManager.location {
                            parkingService.findNearbyParkingLocations(location: location)
                        }
                    }
                }
            }) {
                Text("Search Again")
                    .font(.custom("Noto Sans", size: bodySize).bold())
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// List view showing available parking locations
    private func parkingListView() -> some View {
        // Sort locations by distance directly in the view
        let sortedLocations = parkingService.parkingLocations.sorted { location1, location2 in
            guard let userLocation = locationManager.location else { return false }
            
            let distance1 = location1.distance(from: userLocation)
            let distance2 = location2.distance(from: userLocation)
            return distance1 < distance2
        }
        
        return List {
            Section(header:
                Text("Tap to view details")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
            ) {
                ForEach(sortedLocations) { location in
                    Button(action: {
                        selectedParkingLocation = location
                        showingParkingDetails = true
                    }) {
                        ParkingLocationRow(location: location, userLocation: locationManager.location)
                    }
                    .listRowBackground(Color.white)
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
    }
}

/**
 * ParkingLocationRow
 *
 * Row item for displaying a parking location in the list view.
 * Shows key information like name, price, availability, and distance.
 */
struct ParkingLocationRow: View {
    let location: ParkingLocation
    let userLocation: CLLocation?
    
    /// Formats distance to be user-friendly (meters or kilometers)
    var formattedDistance: String {
        guard let userLocation = userLocation else {
            return "Unknown distance"
        }
        
        let distanceInMeters = location.distance(from: userLocation)
        
        if distanceInMeters < 1000 {
            return "\(Int(distanceInMeters))m away"
        } else {
            let distanceInKm = distanceInMeters / 1000
            return String(format: "%.1f km away", distanceInKm)
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // MARK: - Icon with color-coded availability
            ZStack {
                Circle()
                    .fill(Color(location.availabilityColor))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconForParkingType(location.type))
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // MARK: - Location details (name, address, metadata)
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.custom("Noto Sans", size: 18).bold())
                    .foregroundColor(.black)
                
                Text(location.address)
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                // MARK: - Metadata row (price, rating, availability)
                HStack(spacing: 8) {
                    // Price indicator
                    if let price = location.pricePerHour {
                        Text("$\(String(format: "%.2f", price))/hr")
                            .font(.custom("Noto Sans", size: 14))
                            .foregroundColor(.black)
                    }
                    
                    // Rating indicator
                    if let rating = location.googleRating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.custom("Noto Sans", size: 14))
                                .foregroundColor(.black)
                        }
                    }
                    
                    // Availability indicator
                    if let available = location.availableSpaces, let total = location.totalSpaces {
                        HStack(spacing: 2) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 12))
                                .foregroundColor(available > 10 ? .green : .red)
                            
                            Text("\(available)/\(total)")
                                .font(.custom("Noto Sans", size: 14))
                                .foregroundColor(.black)
                        }
                    }
                }
            }
            
            Spacer()
            
            // MARK: - Distance and status indicators
            VStack(alignment: .trailing) {
                Text(formattedDistance)
                    .font(.custom("Noto Sans", size: 14).bold())
                    .foregroundColor(.black)
                
                // Data freshness indicator
                if location.isDataStale {
                    Text("Data may be stale")
                        .font(.custom("Noto Sans", size: 12))
                        .foregroundColor(.orange)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
    
    /// Returns the appropriate SF Symbol icon for each parking type
    private func iconForParkingType(_ type: ParkingType) -> String {
        switch type {
        case .street:
            return "road.lanes"
        case .garage:
            return "building.2.fill"
        case .lot:
            return "parkingsign"
        case .metered:
            return "timer"
        }
    }
}

/**
 * ParkingMapView
 *
 * Map view for displaying parking locations visually.
 * Uses MapKit to show interactive markers for parking locations.
 */
struct ParkingMapView: View {
    let parkingLocations: [ParkingLocation]
    let userLocation: CLLocation?
    @Binding var selectedLocation: ParkingLocation?
    
    // Default region centered on Pasadena
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.1478, longitude: -118.1445),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        // Use the older Map style which is more compatible with Xcode 16.2
        Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: parkingLocations) { location in
            // Create a custom annotation for each parking location
            MapAnnotation(coordinate: location.coordinates) {
                // Custom marker view that handles its own tap
                Button(action: {
                    selectedLocation = location
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            // More visible pin with shadow
                            Circle()
                                .fill(Color(location.availabilityColor))
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                            
                            Image(systemName: iconForParkingType(location.type))
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .overlay(
                            Circle()
                                .stroke(selectedLocation?.id == location.id ? Color.black : Color.clear, lineWidth: 3)
                        )
                        
                        // Show label for selected pin
                        if selectedLocation?.id == location.id {
                            // Show name for selected location
                            Text(location.name)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(4)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(4)
                                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 120)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle()) // Prevents default button styling
            }
        }
        .onAppear {
            // Always force center map on Pasadena
            let pasadenaCoords = CLLocationCoordinate2D(latitude: 34.1478, longitude: -118.1445)
            
            // Use user location if available, otherwise default to Pasadena
            let centerCoords = userLocation?.coordinate ?? pasadenaCoords
            
            // Update region with a slight delay for smooth loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                region = MKCoordinateRegion(
                    center: centerCoords,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
        .onDisappear {
            // Reset selected location when map disappears to avoid UI issues
            if selectedLocation != nil {
                selectedLocation = nil
            }
        }
    }
    
    /// Returns the appropriate SF Symbol icon for each parking type
    private func iconForParkingType(_ type: ParkingType) -> String {
        switch type {
        case .street:
            return "road.lanes"
        case .garage:
            return "building.2.fill"
        case .lot:
            return "parkingsign"
        case .metered:
            return "timer"
        }
    }
}

/**
 * ParkingDetailView
 *
 * Detailed view for a selected parking location.
 * Shows comprehensive information and provides action buttons.
 */
struct ParkingDetailView: View {
    let parkingLocation: ParkingLocation
    let userLocation: CLLocation?
    let onUpdateAvailability: (Int) -> Void
    let onReportFull: () -> Void
    
    @State private var showingAvailabilityReport = false
    @State private var reportedAvailableSpaces: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Header Section
                VStack(alignment: .center, spacing: 8) {
                    Text(parkingLocation.name)
                        .font(.custom("Noto Sans", size: 24).bold())
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    Text(parkingLocation.type.rawValue)
                        .font(.custom("Noto Sans", size: 18))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                // MARK: - Availability Indicator
                availabilityView()
                
                // MARK: - Details Section
                detailsSection()
                
                // MARK: - Action Buttons
                actionButtons()
            }
        }
        .background(Color(hex: "fffc00"))
        .sheet(isPresented: $showingAvailabilityReport) {
            // MARK: - Reporting Sheet
            reportingSheet()
        }
    }
    
    // MARK: - Helper Views
    
    /// Visual indicator of parking availability
    private func availabilityView() -> some View {
        HStack {
            if let available = parkingLocation.availableSpaces, let total = parkingLocation.totalSpaces {
                VStack(alignment: .center, spacing: 8) {
                    // Circular percentage indicator
                    ZStack {
                        Circle()
                            .fill(Color(parkingLocation.availabilityColor))
                            .frame(width: 80, height: 80)
                        
                        Text("\(Int((Double(available) / Double(total)) * 100))%")
                            .font(.custom("Noto Sans", size: 24).bold())
                            .foregroundColor(.white)
                    }
                    
                    // Availability counts
                    Text("\(available) of \(total) spots available")
                        .font(.custom("Noto Sans", size: 16))
                        .foregroundColor(.black)
                    
                    // Status description
                    Text(parkingLocation.availabilityStatus)
                        .font(.custom("Noto Sans", size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            } else {
                // Fallback for missing data
                Text("Availability information not available")
                    .font(.custom("Noto Sans", size: 16))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    /// Location details with icons
    private func detailsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                // Address information
                HStack(alignment: .top) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                    
                    VStack(alignment: .leading) {
                        Text("Address")
                            .font(.custom("Noto Sans", size: 16).bold())
                            .foregroundColor(.black)
                        
                        Text(parkingLocation.address)
                            .font(.custom("Noto Sans", size: 16))
                            .foregroundColor(.gray)
                    }
                }
                
                // Pricing information (if available)
                if let price = parkingLocation.pricePerHour {
                    HStack(alignment: .top) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                        
                        VStack(alignment: .leading) {
                            Text("Pricing")
                                .font(.custom("Noto Sans", size: 16).bold())
                                .foregroundColor(.black)
                            
                            Text("$\(String(format: "%.2f", price)) per hour")
                                .font(.custom("Noto Sans", size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Hours/restrictions information (if available)
                if let restrictions = parkingLocation.timeRestriction {
                    HStack(alignment: .top) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                        
                        VStack(alignment: .leading) {
                            Text("Hours")
                                .font(.custom("Noto Sans", size: 16).bold())
                                .foregroundColor(.black)
                            
                            Text(restrictions)
                                .font(.custom("Noto Sans", size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Distance information (if user location available)
                if let userLocation = userLocation {
                    let distance = parkingLocation.distance(from: userLocation)
                    HStack(alignment: .top) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                        
                        VStack(alignment: .leading) {
                            Text("Distance")
                                .font(.custom("Noto Sans", size: 16).bold())
                                .foregroundColor(.black)
                            
                            // Format distance appropriately
                            if distance < 1000 {
                                Text("\(Int(distance)) meters away")
                                    .font(.custom("Noto Sans", size: 16))
                                    .foregroundColor(.gray)
                            } else {
                                Text(String(format: "%.1f km away", distance / 1000))
                                    .font(.custom("Noto Sans", size: 16))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Rating information (if available)
                if let rating = parkingLocation.googleRating {
                    HStack(alignment: .top) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading) {
                            Text("Rating")
                                .font(.custom("Noto Sans", size: 16).bold())
                                .foregroundColor(.black)
                            
                            Text(String(format: "%.1f out of 5", rating))
                                .font(.custom("Noto Sans", size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    /// Action buttons for user interactions
    private func actionButtons() -> some View {
        VStack(spacing: 16) {
            // Navigate button
            Button(action: {
                openInMaps()
            }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Navigate")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            // Report availability button
            Button(action: {
                showingAvailabilityReport = true
            }) {
                HStack {
                    Image(systemName: "exclamationmark.bubble.fill")
                    Text("Report Availability")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.black)
                .cornerRadius(10)
            }
            
            // Report full button
            Button(action: {
                onReportFull()
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Report Lot Full")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.2))
                .foregroundColor(.red)
                .cornerRadius(10)
            }
        }
        .padding()
    }
    
    /// Reporting sheet for user-submitted availability
    private func reportingSheet() -> some View {
        VStack(spacing: 20) {
            Text("Report Available Spaces")
                .font(.custom("Noto Sans", size: 24).bold())
            
            Text("How many spaces are available at \(parkingLocation.name)?")
                .font(.custom("Noto Sans", size: 16))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("Available spaces", text: $reportedAvailableSpaces)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)
            
            Button(action: {
                if let availableSpaces = Int(reportedAvailableSpaces), availableSpaces >= 0 {
                    onUpdateAvailability(availableSpaces)
                    showingAvailabilityReport = false
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Text("Submit Report")
                    .font(.custom("Noto Sans", size: 16).bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(reportedAvailableSpaces.isEmpty || Int(reportedAvailableSpaces) == nil)
            
            Button(action: {
                showingAvailabilityReport = false
            }) {
                Text("Cancel")
                    .font(.custom("Noto Sans", size: 16))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.top, 40)
        .background(Color(hex: "fffc00"))
    }
    
    /// Opens the location in Apple Maps for navigation
    private func openInMaps() {
        let coordinate = parkingLocation.coordinates
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = parkingLocation.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
