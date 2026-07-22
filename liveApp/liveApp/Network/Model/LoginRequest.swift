import Foundation

/// 登录请求参数：手机号、验证码、用户名。
nonisolated struct LoginRequest: Encodable, Sendable {
    let mobile: String
    let smsCode: String
    let username: String

    enum CodingKeys: String, CodingKey {
        case mobile
        case smsCode = "sms_code"
        case username
    }
}
