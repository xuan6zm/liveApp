import Foundation
import Moya
import Alamofire

/// 调试用接口：httpbin POST 回显 / postman-echo GET 回显。
nonisolated enum TestAPI {
    /// POST JSON 到 httpbin，回显 body（见响应里的 `json` / `data` 字段）。
    case echoPost(LoginRequest)
    /// GET 到 postman-echo，回显 query（见响应里的 `args` 字段）。
    case echoGet(name: String, id: String)
}

extension TestAPI: TargetType {
    var baseURL: URL {
        switch self {
        case .echoPost:
            return URL(string: "https://httpbin.org")!
        case .echoGet:
            return URL(string: "https://postman-echo.com")!
        }
    }

    var path: String {
        switch self {
        case .echoPost:
            return "/post"
        case .echoGet:
            return "/get"
        }
    }

    var method: Moya.Method {
        switch self {
        case .echoPost:
            return .post
        case .echoGet:
            return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case let .echoPost(request):
            return .requestJSONEncodable(request)
        case let .echoGet(name, id):
            return .requestParameters(
                parameters: ["name": name, "id": id],
                encoding: URLEncoding.queryString
            )
        }
    }

    var headers: [String: String]? {
        defaultHeaders
    }

    var sampleData: Data {
        switch self {
        case let .echoPost(request):
            let json = """
            {
              "args": {},
              "data": "{\\"mobile\\":\\"\(request.mobile)\\",\\"sms_code\\":\\"\(request.smsCode)\\",\\"username\\":\\"\(request.username)\\"}",
              "files": {},
              "form": {},
              "headers": {
                "Content-Type": "application/json"
              },
              "json": {
                "mobile": "\(request.mobile)",
                "sms_code": "\(request.smsCode)",
                "username": "\(request.username)"
              },
              "url": "https://httpbin.org/post"
            }
            """
            return Data(json.utf8)
        case let .echoGet(name, id):
            let json = """
            {
              "args": {
                "name": "\(name)",
                "id": "\(id)"
              },
              "headers": {},
              "url": "https://postman-echo.com/get?name=\(name)&id=\(id)"
            }
            """
            return Data(json.utf8)
        }
    }
}
