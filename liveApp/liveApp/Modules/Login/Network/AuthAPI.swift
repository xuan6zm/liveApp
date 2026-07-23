import Foundation
import Moya
import Alamofire

/// 认证相关接口。
nonisolated enum AuthAPI {
    case login(LoginRequest)
}

extension AuthAPI: TargetType {
    var baseURL: URL {
        APIHost.current.baseURL
    }

    var path: String {
        switch self {
        case .login:
            return "/v1/auth/login"
        }
    }

    var method: Moya.Method {
        switch self {
        case .login:
            return .post
        }
    }

    var task: Moya.Task {
        switch self {
        case let .login(request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        defaultHeaders
    }

    var sampleData: Data {
        switch self {
        case let .login(request):
            let json = """
            {
              "code": 0,
              "message": "ok",
              "data": {
                "user_id": "u_10086",
                "username": "\(request.username)",
                "mobile": "\(request.mobile)",
                "nickname": "直播小助手",
                "avatar_url": "https://cdn.example.com/avatar/default.png",
                "token": "demo_token_\(request.mobile)"
              }
            }
            """
            return Data(json.utf8)
        }
    }
}
