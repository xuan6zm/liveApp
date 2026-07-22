import Foundation

/// 登录会话：Actor 维护 token；对外提供同步 `@Sendable` 读取闭包供 AuthPlugin 使用。
actor SessionStore {
    private let tokenBox = TokenBox()

    /// 同步读取当前 token（无可变全局静态变量）。
    nonisolated var tokenProvider: @Sendable () -> String? {
        { [tokenBox] in
            tokenBox.current()
        }
    }

    func updateToken(_ token: String?) {
        tokenBox.update(token)
    }

    func clearToken() {
        tokenBox.update(nil)
    }
}

/// 线程安全 token 容器，供同步插件闭包读取。
private nonisolated final class TokenBox: @unchecked Sendable {
    private let lock = NSLock()
    private var token: String?

    func update(_ token: String?) {
        lock.lock()
        self.token = token
        lock.unlock()
    }

    func current() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return token
    }
}
