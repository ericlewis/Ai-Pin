import Foundation

public struct Session: Codable {
    let accessToken: String
    let expires: Date
}
