import Foundation
import SwiftData

@Model
final class PlaceToVisit {
    var id: UUID
    var name: String
    var detail: String
    var latitude: Double
    var longitude: Double
    var address: String
    var isVisited: Bool
    var targetDate: Date?
    var createdAt: Date

    init(
        name: String,
        detail: String = "",
        latitude: Double = 0,
        longitude: Double = 0,
        address: String = "",
        isVisited: Bool = false,
        targetDate: Date? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.detail = detail
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.isVisited = isVisited
        self.targetDate = targetDate
        self.createdAt = Date()
    }

    /// Google Maps URLを生成
    var googleMapsURL: URL? {
        if latitude != 0, longitude != 0 {
            return URL(string: "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)")
        } else if !name.isEmpty {
            let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "https://www.google.com/maps/search/?api=1&query=\(encoded)")
        }
        return nil
    }

    /// Google Mapsアプリ用URLスキーム
    var googleMapsAppURL: URL? {
        if latitude != 0, longitude != 0 {
            return URL(string: "comgooglemaps://?q=\(latitude),\(longitude)&zoom=15")
        } else if !name.isEmpty {
            let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "comgooglemaps://?q=\(encoded)&zoom=15")
        }
        return nil
    }

    /// Apple Maps用URL
    var appleMapsURL: URL? {
        if latitude != 0, longitude != 0 {
            return URL(string: "http://maps.apple.com/?ll=\(latitude),\(longitude)&q=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        } else if !name.isEmpty {
            let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "http://maps.apple.com/?q=\(encoded)")
        }
        return nil
    }
}
