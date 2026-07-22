import Foundation
import Moya

/// Token 注入插件：通过 `@Sendable` 闭包动态读取 token，内部不持有可变登录态。
nonisolated struct AuthPlugin: PluginType {
    let tokenProvider: @Sendable () -> String?

    init(tokenProvider: @escaping @Sendable () -> String?) {
        self.tokenProvider = tokenProvider
    }

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let token = tokenProvider(), !token.isEmpty else {
            return request
        }

        var request = request
        let value = "Bearer \(token)"
        request.setValue(value, forHTTPHeaderField: NetworkConstant.HeaderKey.authorization)
        return request
    }
}
