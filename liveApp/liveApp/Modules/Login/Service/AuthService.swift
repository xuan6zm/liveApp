import Foundation

/// 认证业务：登录等，只依赖 `NetworkClient`。
nonisolated struct AuthService: Sendable {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    func login(_ request: LoginRequest) async throws -> UserInfo {
        try await client.requestDecodable(AuthAPI.login(request))
    }
}
