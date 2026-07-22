import Foundation

/// 统一 `JSONDecoder`：snake_case、日期多格式、数字/字符串兼容预处理。
nonisolated enum JSONDecoderFactory {
    static func make() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom(decodeDate)
        return decoder
    }

    /// 对 JSON Data 做数字/字符串宽松归一化后再解码。
    static func decode<T: Decodable>(_ type: T.Type, from data: Data, using decoder: JSONDecoder? = nil) throws -> T {
        let activeDecoder = decoder ?? make()
        let normalized = normalizeNumberStringCompatibility(data) ?? data
        do {
            return try activeDecoder.decode(type, from: normalized)
        } catch {
            throw NetworkError.decoding(message: error.localizedDescription)
        }
    }

    private static func decodeDate(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()

        if let timestamp = try? container.decode(Double.self) {
            if timestamp > 1_000_000_000_000 {
                return Date(timeIntervalSince1970: timestamp / 1000)
            }
            return Date(timeIntervalSince1970: timestamp)
        }

        if let timestamp = try? container.decode(Int.self) {
            let value = Double(timestamp)
            if value > 1_000_000_000_000 {
                return Date(timeIntervalSince1970: value / 1000)
            }
            return Date(timeIntervalSince1970: value)
        }

        let raw = try container.decode(String.self)
        if let date = iso8601Fractional.date(from: raw) ?? iso8601.date(from: raw) {
            return date
        }
        if let value = Double(raw) {
            if value > 1_000_000_000_000 {
                return Date(timeIntervalSince1970: value / 1000)
            }
            return Date(timeIntervalSince1970: value)
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unrecognized date format: \(raw)"
        )
    }

    /// 将 JSON 中「数字字段写成字符串 / 字符串字段写成数字」做一轮宽松转换（仅一层对象与数组递归）。
    private static func normalizeNumberStringCompatibility(_ data: Data) -> Data? {
        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        let normalized = normalizeJSONValue(object)
        return try? JSONSerialization.data(withJSONObject: normalized, options: [])
    }

    private static func normalizeJSONValue(_ value: Any) -> Any {
        switch value {
        case let dictionary as [String: Any]:
            return dictionary.mapValues { normalizeJSONValue($0) }
        case let array as [Any]:
            return array.map { normalizeJSONValue($0) }
        case let number as NSNumber:
            // 保持数字；布尔也是 NSNumber，原样返回
            return number
        case let string as String:
            if let intValue = Int(string) {
                return intValue
            }
            if let doubleValue = Double(string), string.contains(".") {
                return doubleValue
            }
            return string
        default:
            return value
        }
    }

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let iso8601Fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
