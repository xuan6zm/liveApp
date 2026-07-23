import Foundation

/// 登录页状态与业务编排。
@MainActor
final class LoginViewModel {
    private let authService: AuthService
    private let sessionStore: SessionStore
    private var loginTask: Task<Void, Never>?

    private(set) var userInfo: UserInfo?
    private(set) var errorMessage: String?
    private(set) var isLoading = false

    var onChange: (() -> Void)?

    init(authService: AuthService, sessionStore: SessionStore) {
        self.authService = authService
        self.sessionStore = sessionStore
    }

    func login(mobile: String, smsCode: String, username: String) {
        loginTask?.cancel()
        isLoading = true
        errorMessage = nil
        userInfo = nil
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

    private func handleSuccess(_ user: UserInfo) {
        userInfo = user
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

    deinit {
        loginTask?.cancel()
    }
}
