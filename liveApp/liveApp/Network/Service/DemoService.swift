import Foundation

/// Demo 业务门面：只依赖 `NetworkClient`，返回 Sendable 模型。
struct DemoService: Sendable {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    /// 拉取直播流信息。
    ///
    func fetchStreamInfo(id: String) async throws -> StreamInfo {
        try await client.requestDecodable(DemoAPI.streamInfo(id: id))
    }

    /// 手机号 + 验证码 + 用户名登录。
    func login(_ request: LoginRequest) async throws -> UserInfo {
        try await client.requestDecodable(DemoAPI.login(request))
    }
}
