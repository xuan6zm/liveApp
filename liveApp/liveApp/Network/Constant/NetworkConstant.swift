import Foundation

/// 网络层常量：超时、业务成功码、公共 Header Key、各环境 baseURL。
nonisolated enum NetworkConstant {
    static let timeoutInterval: TimeInterval = 30
    static let successCode = 0

    static let debugBaseURL = "https://api-dev.example.com"
    static let stagingBaseURL = "https://api-staging.example.com"
    static let releaseBaseURL = "https://api.example.com"

    enum HeaderKey {
        static let accept = "Accept"
        static let contentType = "Content-Type"
        static let authorization = "Authorization"
        static let appVersion = "X-App-Version"
        static let deviceId = "X-Device-Id"
    }

    enum HeaderValue {
        static let json = "application/json"
    }

    /// 日志脱敏时匹配的敏感 JSON 字段名（小写比较）。
    static let sensitiveJSONKeys: Set<String> = [
        "token",
        "access_token",
        "refresh_token",
        "password",
        "mobile",
        "phone",
        "authorization"
    ]
}
