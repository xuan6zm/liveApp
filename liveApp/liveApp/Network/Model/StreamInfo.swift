import Foundation

/// 示例直播流信息 DTO（Sendable，属性全 let）。
nonisolated struct StreamInfo: Codable, Sendable {
    let streamId: String
    let url: String
    let bufferTime: Double
}
