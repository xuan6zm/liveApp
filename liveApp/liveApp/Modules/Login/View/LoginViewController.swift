import UIKit

/// 登录页：手机号 / 验证码 / 用户名。
@MainActor
final class LoginViewController: UIViewController {
    private let sessionStore: SessionStore
    private var viewModel: LoginViewModel?

    private let mobileField = UITextField()
    private let smsCodeField = UITextField()
    private let usernameField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let resultLabel = UILabel()

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
        setupUI()
        setupViewModel()
    }

    private func setupViewModel() {
        let client = NetworkClient(sessionStore: sessionStore)
        let authService = AuthService(client: client)
        let viewModel = LoginViewModel(authService: authService, sessionStore: sessionStore)
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

        resultLabel.numberOfLines = 0
        resultLabel.textColor = .secondaryLabel
        resultLabel.font = .preferredFont(forTextStyle: .footnote)
        resultLabel.text = "填写信息后点击登录"

        let stack = UIStackView(arrangedSubviews: [
            mobileField,
            smsCodeField,
            usernameField,
            loginButton,
            resultLabel
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
    }

    @objc private func loginTapped() {
        view.endEditing(true)

        let mobile = mobileField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let smsCode = smsCodeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let username = usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !mobile.isEmpty, !smsCode.isEmpty, !username.isEmpty else {
            resultLabel.textColor = .systemRed
            resultLabel.text = "请填写手机号、验证码、用户名"
            return
        }

        viewModel?.login(mobile: mobile, smsCode: smsCode, username: username)
    }

    private func refreshUI() {
        guard let viewModel else { return }

        loginButton.isEnabled = !viewModel.isLoading
        loginButton.setTitle(viewModel.isLoading ? "登录中…" : "登录", for: .normal)

        if let error = viewModel.errorMessage {
            resultLabel.textColor = .systemRed
            resultLabel.text = error
            return
        }

        if let user = viewModel.userInfo {
            resultLabel.textColor = .label
            resultLabel.text = """
            登录成功
            userId: \(user.userId)
            username: \(user.username)
            mobile: \(user.mobile)
            nickname: \(user.nickname)
            avatar: \(user.avatarUrl ?? "—")
            """
            return
        }

        resultLabel.textColor = .secondaryLabel
        resultLabel.text = viewModel.isLoading ? "请求中…" : "填写信息后点击登录"
    }
}
