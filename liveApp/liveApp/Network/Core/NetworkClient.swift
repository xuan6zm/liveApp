import Foundation
import Moya

typealias MoyaTask = Moya.Task


/// 网络客户端：仅在 Actor 内持有 `MoyaProvider`，对外仅暴露 `async throws`。
actor NetworkClient {
    private let provider: MoyaProvider<MultiTarget>
    private let decoder: JSONDecoder
    private let successCode: Int

    init(
        sessionStore: SessionStore,
        stubClosure: @escaping MoyaProvider<MultiTarget>.StubClosure = MoyaProvider.neverStub,
        decoder: JSONDecoder = JSONDecoderFactory.make(),
        successCode: Int = NetworkConstant.successCode
    ) {
        self.provider = MoyaProviderFactory.make(
            tokenProvider: sessionStore.tokenProvider,
            stubClosure: stubClosure
        )
        self.decoder = decoder
        self.successCode = successCode
    }

    /// 发起原始请求，返回 Moya `Response`。
    func request<Target: TargetType>(_ target: Target) async throws -> Response {
        
        let multiTarget = MultiTarget(target)
        let bridge = ContinuableRequestBridge()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                bridge.attach(continuation)

                let cancellable = self.provider.request(multiTarget) { result in
                    bridge.resume(with: result)
                }
                bridge.store(cancellable)

               
            }
        } onCancel: {
            bridge.cancel()
        }
    }

    /// HTTP 校验 → 解信封 → 业务码校验 → 返回 `data`。
    func requestDecodable<Target: TargetType, Value: Decodable & Sendable>(
        _ target: Target
    ) async throws -> Value {
        let response = try await request(target)
        let filtered: Response
        do {
            filtered = try response.filterSuccessfulStatusCodes()
        } catch {
            throw NetworkError.map(error)
        }

        let envelope: APIEnvelope<Value>
        do {
            envelope = try JSONDecoderFactory.decode(
                APIEnvelope<Value>.self,
                from: filtered.data,
                using: decoder
            )
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.decoding(message: error.localizedDescription)
        }

        guard envelope.code == successCode else {
            throw NetworkError.business(code: envelope.code, message: envelope.message)
        }

        guard let data = envelope.data else {
            throw NetworkError.decoding(message: "Response data is null")
        }

        return data
    }

    /// 仅校验信封业务码，允许 `data` 为空。
    func requestWithoutData<Target: TargetType>(_ target: Target) async throws {
        let response = try await request(target)
        let filtered: Response
        do {
            filtered = try response.filterSuccessfulStatusCodes()
        } catch {
            throw NetworkError.map(error)
        }

        let envelope: APIEnvelope<EmptyData>
        do {
            envelope = try JSONDecoderFactory.decode(
                APIEnvelope<EmptyData>.self,
                from: filtered.data,
                using: decoder
            )
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.decoding(message: error.localizedDescription)
        }

        guard envelope.code == successCode else {
            throw NetworkError.business(code: envelope.code, message: envelope.message)
        }
    }

    /// HTTP 校验后返回原始 JSON（整段响应体，不解信封、不校验业务码）。
    func requestJSON<Target: TargetType>(_ target: Target) async throws -> Any {
        let response = try await request(target)
        let filtered: Response
        do {
            filtered = try response.filterSuccessfulStatusCodes()
        } catch {
            throw NetworkError.map(error)
        }

        guard !filtered.data.isEmpty else {
            throw NetworkError.decoding(message: "Response data is empty")
        }

        do {
            return try JSONSerialization.jsonObject(
                with: filtered.data,
                options: [.fragmentsAllowed]
            )
        } catch {
            throw NetworkError.decoding(message: error.localizedDescription)
        }
    }
}

// MARK: - ContinuableRequestBridge

/// 防护 continuation 重复 resume，并在 cancel 时取消底层 Moya 请求。
private nonisolated final class ContinuableRequestBridge: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Response, Error>?
    private var cancellable: Moya.Cancellable?
    private var isFinished = false

    func attach(_ continuation: CheckedContinuation<Response, Error>) {
        lock.lock()
        self.continuation = continuation
        lock.unlock()
    }

    func store(_ cancellable: Moya.Cancellable) {
        lock.lock()
        if isFinished {
            lock.unlock()
            cancellable.cancel()
            return
        }
        self.cancellable = cancellable
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        let activeCancellable = cancellable
        lock.unlock()
        activeCancellable?.cancel()
        finish(throwing: NetworkError.cancelled)
    }

    func resume(with result: Result<Response, MoyaError>) {
        switch result {
        case let .success(response):
            if response.statusCode == 401 {
                finish(throwing: NetworkError.unauthorized)
                return
            }
            finish(returning: response)
        case let .failure(error):
            finish(throwing: NetworkError.map(error))
        }
    }

    private func finish(returning response: Response) {
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return
        }
        isFinished = true
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(returning: response)
    }

    private func finish(throwing error: Error) {
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return
        }
        isFinished = true
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(throwing: error)
    }
}
