import Foundation
import CoreLocation

/**
 * LocationManager
 *
 * Handles all location-related functionality including:
 * - Requesting and managing location permissions
 * - Providing real-time location updates
 * - Handling simulator vs. device location differences
 */
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    // Pasadena coordinates for default location
    private let defaultLatitude: Double = 34.1478
    private let defaultLongitude: Double = -118.1445
    
    // Published properties for SwiftUI to observe
    @Published var location: CLLocation? {
        didSet {
            print("Location updated: \(location?.coordinate.latitude ?? 0), \(location?.coordinate.longitude ?? 0)")
        }
    }
    @Published var isAuthorized = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // CRITICAL: Always use default Pasadena location, ignoring real device location
    // Change to false only for production with real users
    private let forceDefaultLocation = true
    
    override init() {
        super.init()
        
        // Configure the core location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location every 10 meters
        
        // Always initialize with default location for Pasadena
        self.location = CLLocation(latitude: defaultLatitude, longitude: defaultLongitude)
        
        // Request permission immediately on initialization
        requestLocationPermission()
    }
    
    /**
     * Request permission to access device location
     */
    func requestLocationPermission() {
        print("Requesting location permission...")
        locationManager.requestWhenInUseAuthorization()
    }
    
    /**
     * Start receiving location updates
     */
    func startLocationUpdates() {
        print("Starting location updates...")
        locationManager.startUpdatingLocation()
        
        // Immediately ensure we're using the correct location
        if forceDefaultLocation {
            resetToDefaultLocation()
        }
    }
    
    /**
     * Stop receiving location updates to conserve battery
     */
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Location authorization status changed: \(manager.authorizationStatus.rawValue)")
        authorizationStatus = manager.authorizationStatus
        
        isAuthorized = (authorizationStatus == .authorizedWhenInUse ||
                        authorizationStatus == .authorizedAlways)
        
        if isAuthorized {
            startLocationUpdates()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        print("Received location update: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        
        // Only use real location updates if we're not forcing default location
        if !forceDefaultLocation {
            DispatchQueue.main.async {
                self.location = newLocation
            }
        } else {
            print("Using default Pasadena location instead of real update")
            // Always reset to default location to ensure consistency
            resetToDefaultLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        
        // If location services fail, ensure we still have a usable location
        if self.location == nil || forceDefaultLocation {
            resetToDefaultLocation()
        }
    }
    
    /**
     * For testing - manually set a specific location
     */
    func setCustomLocation(latitude: Double, longitude: Double) {
        DispatchQueue.main.async {
            self.location = CLLocation(latitude: latitude, longitude: longitude)
        }
    }
    
    /**
     * Reset to Pasadena default location
     */
    func resetToDefaultLocation() {
        DispatchQueue.main.async {
            self.location = CLLocation(latitude: self.defaultLatitude, longitude: self.defaultLongitude)
        }
    }
}
