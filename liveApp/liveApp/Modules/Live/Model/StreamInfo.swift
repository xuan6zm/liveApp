import Foundation

/// 直播流信息。
nonisolated struct StreamInfo: Codable, Sendable {
    let streamId: String
    let url: String
    let bufferTime: Double
}
