import Foundation
import Moya

#if DEBUG
/// Debug 专用日志插件：后置执行，并对 token / 手机号等敏感字段脱敏。
nonisolated struct DebugLoggerPlugin: PluginType {
    func willSend(_ request: RequestType, target: TargetType) {
        let url = request.request?.url?.absoluteString ?? "nil"
        let method = request.request?.httpMethod ?? "nil"
        let headers = redactedHeaders(request.request?.allHTTPHeaderFields ?? [:])
        let body = redactedBodyString(from: request.request?.httpBody)

        print(
            """
            [Network] ➡️ \(method) \(url)
            [Network] Headers: \(headers)
            [Network] Body: \(body)
            """
        )
    }

    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        switch result {
        case let .success(response):
            let body = redactedBodyString(from: response.data)
            print(
                """
                [Network] ⬅️ \(response.statusCode) \(target.path)
                [Network] Response: \(body)
                """
            )
        case let .failure(error):
            print("[Network] ❌ \(target.path) \(error.localizedDescription)")
        }
    }

    private func redactedHeaders(_ headers: [String: String]) -> [String: String] {
        headers.reduce(into: [String: String]()) { result, entry in
            let key = entry.key
            if key.caseInsensitiveCompare(NetworkConstant.HeaderKey.authorization) == .orderedSame {
                result[key] = "***"
            } else {
                result[key] = entry.value
            }
        }
    }

    private func redactedBodyString(from data: Data?) -> String {
        guard let data, !data.isEmpty else {
            return "<empty>"
        }

        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let redacted = redactJSON(object),
            let pretty = try? JSONSerialization.data(withJSONObject: redacted, options: [.prettyPrinted, .sortedKeys]),
            let text = String(data: pretty, encoding: .utf8)
        else {
            return String(data: data, encoding: .utf8).map(redactPlainText) ?? "<binary \(data.count) bytes>"
        }

        return text
    }

    private func redactJSON(_ value: Any) -> Any? {
        switch value {
        case let dictionary as [String: Any]:
            return dictionary.reduce(into: [String: Any]()) { result, entry in
                if NetworkConstant.sensitiveJSONKeys.contains(entry.key.lowercased()) {
                    result[entry.key] = "***"
                } else if let nested = redactJSON(entry.value) {
                    result[entry.key] = nested
                }
            }
        case let array as [Any]:
            return array.compactMap { redactJSON($0) }
        default:
            return value
        }
    }

    private func redactPlainText(_ text: String) -> String {
        // 粗粒度脱敏：连续 11 位数字（常见手机号）替换为 ***
        let pattern = #"\b\d{11}\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "***")
    }
}
#endif
