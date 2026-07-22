import Foundation
import Moya

/// 网络层统一错误，供 ViewModel 展示用户可读文案。
nonisolated enum NetworkError: Error, Sendable, LocalizedError {
    case cancelled
    case timeout
    case unreachable
    case unauthorized
    case http(statusCode: Int)
    case business(code: Int, message: String)
    case decoding(message: String)
    case underlying(message: String)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "请求已取消"
        case .timeout:
            return "网络请求超时，请稍后重试"
        case .unreachable:
            return "网络不可用，请检查网络连接"
        case .unauthorized:
            return "登录状态已失效，请重新登录"
        case let .http(statusCode):
            return "服务器异常（\(statusCode)）"
        case let .business(_, message):
            return message.isEmpty ? "业务处理失败" : message
        case .decoding:
            return "数据解析失败"
        case let .underlying(message):
            return message.isEmpty ? "网络请求失败" : message
        }
    }

    /// 将 Moya / URL 错误映射为 `NetworkError`。
    static func map(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }

        if error is CancellationError {
            return .cancelled
        }

        if let moyaError = error as? MoyaError {
            return mapMoyaError(moyaError)
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return mapURLErrorCode(nsError.code, fallback: nsError.localizedDescription)
        }

        return .underlying(message: error.localizedDescription)
    }

    private static func mapMoyaError(_ error: MoyaError) -> NetworkError {
        switch error {
        case let .statusCode(response):
            if response.statusCode == 401 {
                return .unauthorized
            }
            return .http(statusCode: response.statusCode)

        case let .underlying(underlying, _):
            let nsError = underlying as NSError
            if nsError.domain == NSURLErrorDomain {
                return mapURLErrorCode(nsError.code, fallback: underlying.localizedDescription)
            }
            return .underlying(message: underlying.localizedDescription)

        case let .objectMapping(underlying, _),
             let .encodableMapping(underlying),
             let .parameterEncoding(underlying):
            return .decoding(message: underlying.localizedDescription)

        case .jsonMapping, .stringMapping, .imageMapping:
            return .decoding(message: error.localizedDescription)

        case .requestMapping:
            return .underlying(message: error.localizedDescription)
        }
    }

    private static func mapURLErrorCode(_ code: Int, fallback: String) -> NetworkError {
        switch code {
        case NSURLErrorCancelled:
            return .cancelled
        case NSURLErrorTimedOut:
            return .timeout
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorDataNotAllowed,
             NSURLErrorInternationalRoamingOff:
            return .unreachable
        default:
            return .underlying(message: fallback)
        }
    }
}
