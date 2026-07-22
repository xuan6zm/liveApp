import Foundation

/// 统一响应信封：`{ code, message, data }`。
nonisolated struct APIEnvelope<T: Decodable & Sendable>: Decodable, Sendable {
    let code: Int
    let message: String
    let data: T?

    var isSuccess: Bool {
        code == NetworkConstant.successCode
    }
}
