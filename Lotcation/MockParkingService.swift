import Foundation
import CoreLocation
import SwiftUI

/**
 * MockParkingService
 *
 * This service simulates a real parking API by providing realistic parking data
 * for locations in Pasadena. It includes features for finding nearby parking options,
 * real-time availability updates, and crowdsourced reporting functionality.
 */
class MockParkingService: ObservableObject {
    /// Published array of parking locations that automatically updates the UI when modified
    @Published var parkingLocations: [ParkingLocation] = []
    
    /// Indicates if data is currently being loaded (for showing loading indicators)
    @Published var isLoading = false
    
    /// Stores error messages if data retrieval fails
    @Published var errorMessage: String?
    
    /// Timer for simulating real-time availability updates
    private var availabilityTimer: Timer?
    
    /**
     * Initializes the service with mock data and starts the availability simulation
     */
    init() {
        loadMockPasadenaData()
        startAvailabilitySimulation()
    }
    
    /**
     * Cleans up by invalidating the timer when the object is deallocated
     */
    deinit {
        availabilityTimer?.invalidate()
    }
    
    /**
     * Finds and sorts parking locations by their distance from the user's current position
     * Simulates a network delay for realism
     *
     * - Parameter location: The user's current location
     */
    func findNearbyParkingLocations(location: CLLocation) {
        isLoading = true
        
        // Simulate network delay for a realistic API experience
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Sort locations by proximity to user
            self.parkingLocations = self.parkingLocations.sorted {
                $0.distance(from: location) < $1.distance(from: location)
            }
            
            self.isLoading = false
        }
    }
    
    /**
     * Updates the availability of a specific parking location based on user reports
     * Part of the crowdsourced reporting feature
     *
     * - Parameters:
     *   - placeID: The unique identifier of the parking location
     *   - availableSpaces: The new number of available parking spaces
     */
    func updateAvailability(for placeID: String, availableSpaces: Int) {
        if let index = parkingLocations.firstIndex(where: { $0.placeID == placeID }) {
            parkingLocations[index].availableSpaces = availableSpaces
            parkingLocations[index].lastUpdated = Date()
        }
    }
    
    /**
     * Marks a parking location as full or nearly full based on user reports
     * Sets available spaces to 5% of total capacity to indicate very limited availability
     *
     * - Parameter placeID: The unique identifier of the parking location
     */
    func reportParkingFull(for placeID: String) {
        if let index = parkingLocations.firstIndex(where: { $0.placeID == placeID }) {
            if let totalSpaces = parkingLocations[index].totalSpaces {
                // Set to a low value (not 0 to avoid division issues in percentage calculations)
                parkingLocations[index].availableSpaces = Int(Double(totalSpaces) * 0.05)
                parkingLocations[index].lastUpdated = Date()
            }
        }
    }
    
    /**
     * Finds the closest parking location to the user's position
     * Used by the "Immediate Parking" emergency feature to quickly direct users
     * to the nearest available parking
     *
     * - Parameter userLocation: The user's current location
     * - Returns: The closest parking location, or nil if none are available
     */
    func getClosestParkingLocation(to userLocation: CLLocation) -> ParkingLocation? {
        // Ensure data is loaded
        if parkingLocations.isEmpty {
            loadMockPasadenaData()
        }
        
        // Sort by distance and return the closest location
        return parkingLocations.sorted {
            $0.distance(from: userLocation) < $1.distance(from: userLocation)
        }.first
    }
    
    /**
     * Simulates real-time parking availability updates
     * Creates a timer that randomly adjusts available spaces every 30 seconds
     * to mimic data that would come from sensors or other users' reports
     */
    private func startAvailabilitySimulation() {
        availabilityTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Update each location's availability with random changes
                self.parkingLocations = self.parkingLocations.map { location in
                    var updatedLocation = location
                    
                    if let totalSpaces = location.totalSpaces {
                        // Random change in available spaces (-5 to +5)
                        let change = Int.random(in: -5...5)
                        var newAvailable = (location.availableSpaces ?? 0) + change
                        
                        // Ensure available spaces stays within logical bounds
                        newAvailable = max(0, min(totalSpaces, newAvailable))
                        updatedLocation.availableSpaces = newAvailable
                        updatedLocation.lastUpdated = Date()
                    }
                    
                    return updatedLocation
                }
            }
        }
    }
    
    /**
     * Loads realistic mock parking data for Pasadena
     * Each location includes accurate coordinates, pricing, and capacity information
     */
    private func loadMockPasadenaData() {
        parkingLocations = [
            // Pasadena Parking Garages
            ParkingLocation(
                placeID: "plaza-pasadena-garage",
                name: "Plaza Las Fuentes Garage",
                address: "121 S Los Robles Ave, Pasadena, CA 91101",
                coordinates: CLLocationCoordinate2D(latitude: 34.1457, longitude: -118.1419),
                type: .garage,
                pricePerHour: 4.00,
                googleRating: 4.2,
                totalSpaces: 650,
                availableSpaces: 248,
                timeRestriction: "Open 24 hours",
                imageNames: []
            ),
            
            ParkingLocation(
                placeID: "marriott-pasadena-garage",
                name: "Marriott Pasadena Parking",
                address: "231 S Lake Ave, Pasadena, CA 91101",
                coordinates: CLLocationCoordinate2D(latitude: 34.1411, longitude: -118.1326),
                type: .garage,
                pricePerHour: 6.00,
                googleRating: 4.0,
                totalSpaces: 400,
                availableSpaces: 85,
                timeRestriction: "Open 24 hours, hotel guests priority",
                imageNames: []
            ),
            
            ParkingLocation(
                placeID: "paseo-colorado-garage",
                name: "Paseo Colorado Garage",
                address: "300 E Colorado Blvd, Pasadena, CA 91101",
                coordinates: CLLocationCoordinate2D(latitude: 34.1456, longitude: -118.1398),
                type: .garage,
                pricePerHour: 3.00,
                googleRating: 4.3,
                totalSpaces: 720,
                availableSpaces: 235,
                timeRestriction: "Mon-Thu: 7AM-12AM, Fri-Sat: 7AM-2AM, Sun: 10AM-10PM",
                imageNames: []
            ),
            
            ParkingLocation(
                placeID: "schoolhouse-garage",
                name: "Schoolhouse Garage",
                address: "33 E Green St, Pasadena, CA 91105",
                coordinates: CLLocationCoordinate2D(latitude: 34.1448, longitude: -118.1480),
                type: .garage,
                pricePerHour: 3.00,
                googleRating: 4.1,
                totalSpaces: 1200,
                availableSpaces: 560,
                timeRestriction: "Open 24 hours, $6 daily maximum",
                imageNames: []
            ),
            
            // Pasadena Parking Lots
            ParkingLocation(
                placeID: "delacey-parking-lot",
                name: "DeLacey Parking Lot",
                address: "45 S DeLacey Ave, Pasadena, CA 91105",
                coordinates: CLLocationCoordinate2D(latitude: 34.1444, longitude: -118.1510),
                type: .lot,
                pricePerHour: 2.50,
                googleRating: 3.9,
                totalSpaces: 175,
                availableSpaces: 42,
                timeRestriction: "Mon-Fri: 6AM-7PM, Sat-Sun: 8AM-7PM",
                imageNames: []
            ),
            
            ParkingLocation(
                placeID: "marengo-parking-lot",
                name: "Marengo Parking Lot",
                address: "155 S Marengo Ave, Pasadena, CA 91101",
                coordinates: CLLocationCoordinate2D(latitude: 34.1433, longitude: -118.1398),
                type: .lot,
                pricePerHour: 2.00,
                googleRating: 3.8,
                totalSpaces: 150,
                availableSpaces: 32,
                timeRestriction: "Mon-Fri: 7AM-6PM",
                imageNames: []
            ),
            
            // Street Parking
            ParkingLocation(
                placeID: "colorado-blvd-meters",
                name: "Colorado Blvd Metered Parking",
                address: "Colorado Blvd, Pasadena, CA 91105",
                coordinates: CLLocationCoordinate2D(latitude: 34.1459, longitude: -118.1456),
                type: .metered,
                pricePerHour: 2.00,
                googleRating: 3.5,
                totalSpaces: 60,
                availableSpaces: 8,
                timeRestriction: "Mon-Sat: 8AM-8PM, 2 hour limit",
                imageNames: []
            ),
            
            ParkingLocation(
                placeID: "lake-ave-meters",
                name: "Lake Avenue Metered Parking",
                address: "Lake Ave, Pasadena, CA 91101",
                coordinates: CLLocationCoordinate2D(latitude: 34.1417, longitude: -118.1328),
                type: .metered,
                pricePerHour: 2.00,
                googleRating: 3.6,
                totalSpaces: 45,
                availableSpaces: 12,
                timeRestriction: "Mon-Sat: 8AM-8PM, 2 hour limit",
                imageNames: []
            ),
            
            // Free Parking
            ParkingLocation(
                placeID: "sierra-madre-villa-parking",
                name: "Sierra Madre Villa Metro Parking",
                address: "149 N Halstead St, Pasadena, CA 91107",
                coordinates: CLLocationCoordinate2D(latitude: 34.1484, longitude: -118.0806),
                type: .lot,
                pricePerHour: 0.00,
                googleRating: 4.4,
                totalSpaces: 950,
                availableSpaces: 422,
                timeRestriction: "Free parking with Metro validation",
                imageNames: []
            ),
            
            // Pasadena Convention Center
            ParkingLocation(
                placeID: "convention-center-garage",
                name: "Pasadena Convention Center Garage",
                address: "300 E Green St, Pasadena, CA 91101",
                coordinates: CLLocationCoordinate2D(latitude: 34.1428, longitude: -118.1393),
                type: .garage,
                pricePerHour: 3.50,
                googleRating: 4.2,
                totalSpaces: 550,
                availableSpaces: 175,
                timeRestriction: "Event rates may apply",
                imageNames: []
            ),
            
            // Old Pasadena Parking
            ParkingLocation(
                placeID: "old-pasadena-garage",
                name: "Old Pasadena Parking Garage",
                address: "35 S Raymond Ave, Pasadena, CA 91105",
                coordinates: CLLocationCoordinate2D(latitude: 34.1448, longitude: -118.1496),
                type: .garage,
                pricePerHour: 3.00,
                googleRating: 4.1,
                totalSpaces: 700,
                availableSpaces: 215,
                timeRestriction: "Open 24 hours, first 90 minutes free",
                imageNames: []
            ),
            
            // Playhouse District
            ParkingLocation(
                placeID: "playhouse-parking",
                name: "Playhouse District Parking",
                address: "686 E Union St, Pasadena, CA 91101",
                coordinates: CLLocationCoordinate2D(latitude: 34.1481, longitude: -118.1367),
                type: .garage,
                pricePerHour: 2.50,
                googleRating: 4.0,
                totalSpaces: 400,
                availableSpaces: 162,
                timeRestriction: "Open 24 hours",
                imageNames: []
            )
        ]
    }
}
