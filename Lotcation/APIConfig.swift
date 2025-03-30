import Foundation

struct APIConfig {
    static let googleMapsAPIKey: String = {
        guard let path = Bundle.main.path(forResource: ".env", ofType: "") else {
            return ""
        }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                let parts = line.components(separatedBy: "=")
                if parts.first == "GOOGLE_MAPS_API_KEY" {
                    return parts.last ?? ""
                }
            }
        } catch {
            return ""
        }
        
        return ""
    }()
}
