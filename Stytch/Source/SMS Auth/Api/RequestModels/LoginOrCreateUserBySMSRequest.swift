import Foundation

struct LoginOrCreateUserBySMSRequest: Codable {
    var phone_number: String?
    var expiration_minutes: Int?
    var create_user_as_pending: Bool?
}
