import UIKit
import SnapKit

/// 登录页：手机号 / 验证码 / 用户名。
@MainActor
final class LoginViewController: UIViewController {
    private let sessionStore: SessionStore
    private var viewModel: LoginViewModel?

    private let mobileField = UITextField()
    private let smsCodeField = UITextField()
    private let usernameField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let quickLoginButton = UIButton(type: .system)
    private let mockButton = UIButton(type: .system)
    private let resultLabel = UILabel()
    private let stackView = UIStackView()

    init(sessionStore: SessionStore = SessionStore()) {
        self.sessionStore = sessionStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.sessionStore = SessionStore()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "登录"
        setupNavigationBar()
        setupUI()
        setupViewModel()
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "关闭",
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
    }

    private func setupViewModel() {
        let client = NetworkClient(sessionStore: sessionStore)
        let authService = AuthService(client: client)
        let testService = TestService(client: client)
        let viewModel = LoginViewModel(
            authService: authService,
            testService: testService,
            sessionStore: sessionStore
        )
        viewModel.onChange = { [weak self] in
            self?.refreshUI()
        }
        self.viewModel = viewModel
    }

    private func setupUI() {
        mobileField.placeholder = "手机号"
        mobileField.keyboardType = .phonePad
        mobileField.borderStyle = .roundedRect
        mobileField.autocapitalizationType = .none
        mobileField.textContentType = .telephoneNumber

        smsCodeField.placeholder = "验证码"
        smsCodeField.keyboardType = .numberPad
        smsCodeField.borderStyle = .roundedRect
        smsCodeField.textContentType = .oneTimeCode

        usernameField.placeholder = "用户名"
        usernameField.borderStyle = .roundedRect
        usernameField.autocapitalizationType = .none
        usernameField.textContentType = .username

        loginButton.setTitle("登录", for: .normal)
        loginButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        quickLoginButton.setTitle("一键登录", for: .normal)
        quickLoginButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        quickLoginButton.addTarget(self, action: #selector(quickLoginTapped), for: .touchUpInside)

        mockButton.setTitle("模拟请求 (postman-echo GET)", for: .normal)
        mockButton.titleLabel?.font = .systemFont(ofSize: 16)
        mockButton.addTarget(self, action: #selector(mockTapped), for: .touchUpInside)

        resultLabel.numberOfLines = 0
        resultLabel.textColor = .secondaryLabel
        resultLabel.font = .preferredFont(forTextStyle: .footnote)
        resultLabel.text = "填写信息后点击登录，或用模拟请求调试 GET 参数"

        mobileField.text = "13800138000"
        smsCodeField.text = "123456"
        usernameField.text = "testuser"

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.addArrangedSubview(mobileField)
        stackView.addArrangedSubview(smsCodeField)
        stackView.addArrangedSubview(usernameField)
        stackView.addArrangedSubview(loginButton)
        stackView.addArrangedSubview(quickLoginButton)
        stackView.addArrangedSubview(mockButton)
        stackView.addArrangedSubview(resultLabel)
        view.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.leading.trailing.equalTo(view.layoutMarginsGuide)
        }
    }

    @objc private func loginTapped() {
        view.endEditing(true)

        guard let params = validatedParams() else { return }
        viewModel?.login(mobile: params.mobile, smsCode: params.smsCode, username: params.username)
    }

    @objc private func quickLoginTapped() {
        view.endEditing(true)
        finishLogin()
    }

    @objc private func closeTapped() {
        view.endEditing(true)
        dismiss(animated: true)
    }

    @objc private func mockTapped() {
        view.endEditing(true)
        // https://postman-echo.com/get?name=zhangsan&id=123
        viewModel?.mockPostmanEchoGet(name: "zhangsan", id: "123")
    }

    /// 登录完成，关闭弹窗回到首页。
    private func finishLogin() {
        dismiss(animated: true)
    }

    private func validatedParams() -> (mobile: String, smsCode: String, username: String)? {
        let mobile = mobileField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let smsCode = smsCodeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let username = usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !mobile.isEmpty, !smsCode.isEmpty, !username.isEmpty else {
            resultLabel.textColor = .systemRed
            resultLabel.text = "请填写手机号、验证码、用户名"
            return nil
        }

        return (mobile, smsCode, username)
    }

    private func refreshUI() {
        guard let viewModel else { return }

        let loading = viewModel.isLoading
        loginButton.isEnabled = !loading
        quickLoginButton.isEnabled = !loading
        mockButton.isEnabled = !loading
        loginButton.setTitle(loading ? "登录中…" : "登录", for: .normal)
        mockButton.setTitle(loading ? "请求中…" : "模拟请求 (postman-echo GET)", for: .normal)

        if let error = viewModel.errorMessage {
            resultLabel.textColor = .systemRed
            resultLabel.text = error
            return
        }

        if let debugJSON = viewModel.debugJSONText {
            resultLabel.textColor = .label
            resultLabel.text = debugJSON
            return
        }

        if viewModel.userInfo != nil {
            finishLogin()
            return
        }

        resultLabel.textColor = .secondaryLabel
        resultLabel.text = loading
            ? "请求中…"
            : "填写信息后点击登录，或用模拟请求调试 GET 参数"
    }
}
