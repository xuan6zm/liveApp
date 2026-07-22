import Foundation

/// `data` 为空（null / 缺省）时的占位结构。
nonisolated struct EmptyData: Codable, Sendable {
    init() {}

    init(from decoder: Decoder) throws {
        if var container = try? decoder.singleValueContainer() {
            if container.decodeNil() {
                return
            }
        }
        _ = try? decoder.container(keyedBy: EmptyCodingKeys.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }

    private enum EmptyCodingKeys: CodingKey {}
}
