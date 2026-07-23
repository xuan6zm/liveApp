import Foundation

/// 调试业务：httpbin / postman-echo 回显，只依赖 `NetworkClient`。
nonisolated struct TestService: Sendable {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    /// POST 登录模型到 httpbin，返回原始 JSON。
    func echoLoginPost(_ request: LoginRequest) async throws -> Any {
        try await client.requestJSON(TestAPI.echoPost(request))
    }

    /// GET 到 postman-echo，回显 query 参数。
    func echoGet(name: String, id: String) async throws -> Any {
        try await client.requestJSON(TestAPI.echoGet(name: name, id: id))
    }
}
