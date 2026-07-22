import Foundation

/// Demo 接入样例：持有可取消 Task，调用 Service。
@MainActor
final class DemoViewModel {
    private let demoService: DemoService
    private let sessionStore: SessionStore
    private var loadTask: Task<Void, Never>?

    private(set) var streamInfo: StreamInfo?
    private(set) var userInfo: UserInfo?
    private(set) var errorMessage: String?
    private(set) var isLoading = false

    /// 状态变化回调，供 VC 刷新 UI。
    var onChange: (() -> Void)?

    init(demoService: DemoService, sessionStore: SessionStore) {
        self.demoService = demoService
        self.sessionStore = sessionStore
    }

    func loadStreamInfo(id: String) {
        loadTask?.cancel()
        isLoading = true
        errorMessage = nil
        notify()

        loadTask = Task { @Sendable [weak self] in
            guard let self else { return }

            do {
                let info = try await self.demoService.fetchStreamInfo(id: id)
                handleStreamSuccess(info)
            } catch let error as NetworkError {
                if case .cancelled = error {
                    handleFinished()
                    return
                }
                handleFailure(error.errorDescription)
            } catch is CancellationError {
                handleFinished()
            } catch {
                handleFailure(error.localizedDescription)
            }
        }
    }

    /// 测试登录：手机号 / 验证码 / 用户名。
    func login(mobile: String, smsCode: String, username: String) {
        loadTask?.cancel()
        isLoading = true
        errorMessage = nil
        notify()

        let request = LoginRequest(mobile: mobile, smsCode: smsCode, username: username)

        loadTask = Task { @Sendable [weak self] in
            guard let self else { return }

            do {
                let user = try await self.demoService.login(request)
                await self.sessionStore.updateToken(user.token)
                handleLoginSuccess(user)
            } catch let error as NetworkError {
                if case .cancelled = error {
                    handleFinished()
                    return
                }
                handleFailure(error.errorDescription)
            } catch is CancellationError {
                handleFinished()
            } catch {
                handleFailure(error.localizedDescription)
            }
        }
    }

    private func handleStreamSuccess(_ info: StreamInfo) {
        streamInfo = info
        isLoading = false
        notify()
    }

    private func handleLoginSuccess(_ user: UserInfo) {
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
        loadTask?.cancel()
    }
}
