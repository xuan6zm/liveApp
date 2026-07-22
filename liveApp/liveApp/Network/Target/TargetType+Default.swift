import Foundation
import Moya

/// `TargetType` 公共默认：公共 Header、空 sampleData 模板。
extension TargetType {
    var defaultHeaders: [String: String] {
        var headers: [String: String] = [
            NetworkConstant.HeaderKey.accept: NetworkConstant.HeaderValue.json,
            NetworkConstant.HeaderKey.contentType: NetworkConstant.HeaderValue.json
        ]

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            headers[NetworkConstant.HeaderKey.appVersion] = version
        }

        return headers
    }

    var emptySampleData: Data {
        Data()
    }
}
