import Foundation
import CoreLocation

/**
 * ParkingType
 *
 * Enum representing different types of parking locations.
 * Used for categorization and appropriate icon selection.
 */
enum ParkingType: String, Codable, CaseIterable {
    case street = "Street Parking"
    case garage = "Parking Garage"
    case lot = "Parking Lot"
    case metered = "Metered Parking"
}

/**
 * ParkingLocation
 *
 * Model representing a parking location with its details.
 * Includes properties for location, availability, pricing, and metadata.
 */
struct ParkingLocation: Identifiable, Equatable {
    // MARK: - Properties
    
    /// Unique identifier for the location
    let id = UUID()
    
    /// Google Places ID or other unique identifier
    let placeID: String
    
    /// Name of the parking location
    let name: String
    
    /// Full address
    let address: String
    
    /// Geographic coordinates
    let coordinates: CLLocationCoordinate2D
    
    /// Type of parking (garage, lot, street, etc.)
    let type: ParkingType
    
    /// Hourly rate (nil if unknown or free)
    let pricePerHour: Double?
    
    /// Rating from Google (nil if unknown)
    let googleRating: Double?
    
    /// Total parking capacity
    var totalSpaces: Int?
    
    /// Currently available spaces (updated in real-time)
    var availableSpaces: Int?
    
    /// Operating hours or time limitations
    let timeRestriction: String?
    
    /// Names of images for this location
    let imageNames: [String]
    
    /// Timestamp of the last availability update
    var lastUpdated: Date = Date()
    
    // MARK: - Codable
    
    /// Define which properties to include in encoding/decoding
    enum CodingKeys: String, CodingKey {
        case placeID, name, address, coordinates, type
        case pricePerHour, googleRating, totalSpaces, availableSpaces
        case timeRestriction, imageNames
        // Note: 'id' and 'lastUpdated' are excluded to avoid the warnings
    }
    
    // MARK: - Methods
    
    /**
     * Calculate the distance from a specific location
     *
     * - Parameter location: The reference location to measure from
     * - Returns: Distance in meters
     */
    func distance(from location: CLLocation) -> CLLocationDistance {
        let parkingLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        return location.distance(from: parkingLocation)
    }
    
    // MARK: - Computed Properties
    
    /**
     * Calculate the percentage of available parking spaces
     * Returns nil if total or available spaces are unknown
     */
    var availabilityPercentage: Double? {
        guard let total = totalSpaces, let available = availableSpaces, total > 0 else {
            return nil
        }
        return Double(available) / Double(total) * 100.0
    }
    
    /**
     * Get a human-readable status description based on availability
     */
    var availabilityStatus: String {
        guard let percentage = availabilityPercentage else {
            return "Unknown availability"
        }
        
        if percentage > 50 {
            return "Plenty of spaces"
        } else if percentage > 20 {
            return "Moderate availability"
        } else if percentage > 5 {
            return "Limited spaces"
        } else {
            return "Nearly full"
        }
    }
    
    /**
     * Get color name for UI visualization of availability
     */
    var availabilityColor: String {
        guard let percentage = availabilityPercentage else {
            return "gray"  // Unknown - gray
        }
        
        if percentage > 50 {
            return "green" // High availability - green
        } else if percentage > 20 {
            return "orange" // Medium availability - orange
        } else {
            return "red" // Low availability - red
        }
    }
    
    /**
     * Format price for display with proper currency symbol
     */
    var formattedPrice: String {
        guard let price = pricePerHour else {
            return "Price unavailable"
        }
        return "$\(String(format: "%.2f", price))/hr"
    }
    
    /**
     * Check if the availability data might be stale (older than 15 minutes)
     */
    var isDataStale: Bool {
        return Date().timeIntervalSince(lastUpdated) > 900 // 15 minutes in seconds
    }
    
    /**
     * Equatable implementation - two locations are equal if they have the same placeID
     */
    static func == (lhs: ParkingLocation, rhs: ParkingLocation) -> Bool {
        lhs.placeID == rhs.placeID
    }
}

// Extension to make CLLocationCoordinate2D conform to Codable
extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}

/**
 * ParkingReport
 *
 * Model for user-submitted reports about parking availability.
 * Used for crowdsourced updates to parking data.
 */
struct ParkingReport: Identifiable, Codable {
    // MARK: - Properties
    
    /// Unique identifier for the report
    let id = UUID()
    
    /// ID of the parking location being reported
    let placeID: String
    
    /// When the report was submitted
    let timestamp: Date
    
    /// Number of available spaces (nil if unknown)
    let availableSpaces: Int?
    
    /// Flag indicating if the lot is completely full
    let isFull: Bool
    
    /// Optional additional information from the user
    let note: String?
    
    /// Anonymous ID to track report sources
    let userID: String?
    
    // MARK: - Codable
    
    /// Define which properties to include in encoding/decoding
    enum CodingKeys: String, CodingKey {
        case placeID, timestamp, availableSpaces, isFull, note, userID
        // Note: 'id' is excluded to avoid the warning
    }
    
    // MARK: - Initializers
    
    /**
     * Initialize with specific available spaces count
     */
    init(placeID: String, availableSpaces: Int, note: String? = nil, userID: String? = nil) {
        self.placeID = placeID
        self.timestamp = Date()
        self.availableSpaces = availableSpaces
        self.isFull = false
        self.note = note
        self.userID = userID
    }
    
    /**
     * Initialize for a full parking lot report
     */
    init(placeID: String, isFull: Bool = true, note: String? = nil, userID: String? = nil) {
        self.placeID = placeID
        self.timestamp = Date()
        self.availableSpaces = 0
        self.isFull = isFull
        self.note = note
        self.userID = userID
    }
}

/**
 * ParkingHistoryItem
 *
 * Model for tracking a user's parking history.
 * Used to show recent parking locations and provide quick access to favorites.
 */
struct ParkingHistoryItem: Identifiable, Codable {
    // MARK: - Properties
    
    /// Unique identifier for this history item
    let id = UUID()
    
    /// ID of the parking location
    let placeID: String
    
    /// Name of the parking location
    let name: String
    
    /// Address of the parking location
    let address: String
    
    /// Geographic coordinates of the parking location
    let coordinates: CLLocationCoordinate2D
    
    /// When the user parked here
    let timestamp: Date
    
    /// How long they stayed (if known)
    let durationMinutes: Int?
    
    // MARK: - Codable
    
    /// Define which properties to include in encoding/decoding
    enum CodingKeys: String, CodingKey {
        case placeID, name, address, coordinates, timestamp, durationMinutes
        // Note: 'id' is excluded to avoid the warning
    }
    
    // MARK: - Computed Properties
    
    /**
     * Format the date for readable display
     */
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /**
     * Format time ago in a relative, human-readable form
     * For example, "2 hours ago" or "3 days ago"
     */
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
