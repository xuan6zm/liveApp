import Foundation

/// 登录页状态与业务编排。
@MainActor
final class LoginViewModel {
    private let authService: AuthService
    private let testService: TestService
    private let sessionStore: SessionStore
    private var loginTask: Task<Void, Never>?

    private(set) var userInfo: UserInfo?
    private(set) var errorMessage: String?
    private(set) var debugJSONText: String?
    private(set) var isLoading = false

    var onChange: (() -> Void)?

    init(authService: AuthService, testService: TestService, sessionStore: SessionStore) {
        self.authService = authService
        self.testService = testService
        self.sessionStore = sessionStore
    }

    func login(mobile: String, smsCode: String, username: String) {
        loginTask?.cancel()
        isLoading = true
        errorMessage = nil
        userInfo = nil
        debugJSONText = nil
        notify()

        let request = LoginRequest(mobile: mobile, smsCode: smsCode, username: username)

        loginTask = Task { [weak self] in
            guard let self else { return }

            do {
                let user = try await self.authService.login(request)
                await self.sessionStore.updateToken(user.token)
                self.handleSuccess(user)
            } catch let error as NetworkError {
                if case .cancelled = error {
                    self.handleFinished()
                    return
                }
                self.handleFailure(error.errorDescription)
            } catch is CancellationError {
                self.handleFinished()
            } catch {
                self.handleFailure(error.localizedDescription)
            }
        }
    }

    func loginRawJson(mobile: String, smsCode: String, username: String) {
        loginTask?.cancel()
        isLoading = true
        errorMessage = nil
        userInfo = nil
        debugJSONText = nil
        notify()

        let request = LoginRequest(mobile: mobile, smsCode: smsCode, username: username)

        loginTask = Task { [weak self] in
            guard let self else { return }

            do {
                let json = try await self.authService.loginRawJson(request)
                print("打印结果 === \(json)")
                self.handleDebugJSON(json)
            } catch let error as NetworkError {
                if case .cancelled = error {
                    self.handleFinished()
                    return
                }
                self.handleFailure(error.errorDescription)
            } catch is CancellationError {
                self.handleFinished()
            } catch {
                self.handleFailure(error.localizedDescription)
            }
        }
    }

    /// 模拟网络请求：GET https://postman-echo.com/get?name=&id=，回显 query。
    func mockPostmanEchoGet(name: String = "zhangsan", id: String = "123") {
        loginTask?.cancel()
        isLoading = true
        errorMessage = nil
        userInfo = nil
        debugJSONText = nil
        notify()

        loginTask = Task { [weak self] in
            guard let self else { return }

            do {
                let json = try await self.testService.echoGet(name: name, id: id)
                print("postman-echo GET === \(json)")
                self.handleDebugJSON(json)
            } catch let error as NetworkError {
                if case .cancelled = error {
                    self.handleFinished()
                    return
                }
                self.handleFailure(error.errorDescription)
            } catch is CancellationError {
                self.handleFinished()
            } catch {
                self.handleFailure(error.localizedDescription)
            }
        }
    }

    private func handleSuccess(_ user: UserInfo) {
        userInfo = user
        isLoading = false
        notify()
    }

    private func handleDebugJSON(_ json: Any) {
        debugJSONText = Self.prettyJSONString(from: json)
        isLoading = false
        notify()
    }

    private func handleFailure(_ message: String?) {
        errorMessage = message
        isLoading = false
        notify()
    }

    private func handleFinished() {
        isLoading = false
        notify()
    }

    private func notify() {
        onChange?()
    }

    private static func prettyJSONString(from json: Any) -> String {
        guard JSONSerialization.isValidJSONObject(json),
              let data = try? JSONSerialization.data(
                withJSONObject: json,
                options: [.prettyPrinted, .sortedKeys]
              ),
              let text = String(data: data, encoding: .utf8)
        else {
            return String(describing: json)
        }
        return text
    }

    deinit {
        loginTask?.cancel()
    }
}
