import Foundation

/// 登录成功返回的用户信息。
/// `convertFromSnakeCase` 下 `avatar_url` 对应属性名应为 `avatarUrl`。
nonisolated struct UserInfo: Codable, Sendable {
    let userId: String
    let username: String
    let mobile: String
    let nickname: String
    let avatarUrl: String?
    let token: String
}
