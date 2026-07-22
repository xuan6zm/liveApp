import Foundation

/// 登录成功返回的用户信息。
nonisolated struct UserInfo: Codable, Sendable {
    let userId: String
    let username: String
    let mobile: String
    let nickname: String
    let avatarURL: String?
    let token: String
}
