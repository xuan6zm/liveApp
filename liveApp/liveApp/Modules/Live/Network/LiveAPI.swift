import Foundation
import Moya
import Alamofire

/// 直播相关接口。
nonisolated enum LiveAPI {
    case streamInfo(id: String)
}

extension LiveAPI: TargetType {
    var baseURL: URL {
        APIHost.current.baseURL
    }

    var path: String {
        switch self {
        case let .streamInfo(id):
            return "/v1/streams/\(id)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .streamInfo:
            return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case .streamInfo:
            return .requestPlain
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
        }
    }
}
