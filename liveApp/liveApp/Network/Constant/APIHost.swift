import Foundation

/// API 环境，映射到 `NetworkConstant` 中的 baseURL。
nonisolated enum APIHost: Sendable {
    case debug
    case staging
    case release

    var baseURL: URL {
        let raw: String
        switch self {
        case .debug:
            raw = NetworkConstant.debugBaseURL
        case .staging:
            raw = NetworkConstant.stagingBaseURL
        case .release:
            raw = NetworkConstant.releaseBaseURL
        }

        guard let url = URL(string: raw) else {
            preconditionFailure("Invalid base URL for \(self): \(raw)")
        }
        return url
    }

    /// 当前编译环境对应的 Host。
    static var current: APIHost {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }
}
