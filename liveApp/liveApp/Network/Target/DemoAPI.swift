import Alamofire
import Foundation
import Moya

/// 示例 API：可按业务域继续拆分为 UserAPI / LiveAPI。
nonisolated enum DemoAPI {
    case streamInfo(id: String)
    case login(LoginRequest)
}

extension DemoAPI: TargetType {
    var baseURL: URL {
        APIHost.current.baseURL
    }

    var path: String {
        switch self {
        case let .streamInfo(id):
            return "/v1/streams/\(id)"
        case .login:
            return "/v1/auth/login"
        }
    }

    var method: Moya.Method {
        switch self {
        case .streamInfo:
            return .get
        case .login:
            return .post
        }
    }

    var task: Moya.Task {
        switch self {
        case .streamInfo:
            return .requestPlain
        case let .login(request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        defaultHeaders
    }

    var sampleData: Data {
        switch self {
        case let .streamInfo(id):
            let json = """
            {
              "code": 0,
              "message": "ok",
              "data": {
                "stream_id": "\(id)",
                "url": "https://live.example.com/\(id).m3u8",
                "buffer_time": 2.0
              }
            }
            """
            return Data(json.utf8)

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
