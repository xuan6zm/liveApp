import Foundation

/// 直播业务门面。
nonisolated struct LiveService: Sendable {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    func fetchStreamInfo(id: String) async throws -> StreamInfo {
        try await client.requestDecodable(LiveAPI.streamInfo(id: id))
    }
}
