//
//  ViewController.swift
//  liveApp
//
//  Created by mac on 2026/7/8.
//

import Moya
import UIKit

@MainActor
final class ViewController: UIViewController {
    private let sessionStore = SessionStore()
    private var demoViewModel: DemoViewModel?

    private let mobileField = UITextField()
    private let smsCodeField = UITextField()
    private let usernameField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let resultLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLoginUI()
        setupDemoNetwork()
    }

    private func setupDemoNetwork() {
        #if DEBUG
        // immediatelyStub：用 DemoAPI.sampleData 验收，不依赖真实后端
        let client = NetworkClient(
            sessionStore: sessionStore,
            stubClosure: MoyaProvider.immediatelyStub
        )
        let service = DemoService(client: client)
        let viewModel = DemoViewModel(demoService: service, sessionStore: sessionStore)
        viewModel.onChange = { [weak self] in
            self?.refreshResultUI()
        }
        demoViewModel = viewModel
        #endif
    }

    private func setupLoginUI() {
        mobileField.placeholder = "手机号"
        mobileField.keyboardType = .phonePad
        mobileField.borderStyle = .roundedRect
        mobileField.text = "13800138000"
        mobileField.autocapitalizationType = .none

        smsCodeField.placeholder = "验证码"
        smsCodeField.keyboardType = .numberPad
        smsCodeField.borderStyle = .roundedRect
        smsCodeField.text = "123456"

        usernameField.placeholder = "用户名"
        usernameField.borderStyle = .roundedRect
        usernameField.text = "demo_user"
        usernameField.autocapitalizationType = .none

        loginButton.setTitle("登录（Stub 测试）", for: .normal)
        loginButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        resultLabel.numberOfLines = 0
        resultLabel.textColor = .secondaryLabel
        resultLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        resultLabel.text = "点击登录后，这里显示返回的用户信息"

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
            resultLabel.text = "请填写手机号、验证码、用户名"
            resultLabel.textColor = .systemRed
            return
        }

        demoViewModel?.login(mobile: mobile, smsCode: smsCode, username: username)
    }

    private func refreshResultUI() {
        guard let viewModel = demoViewModel else { return }

        loginButton.isEnabled = !viewModel.isLoading
        loginButton.setTitle(viewModel.isLoading ? "登录中…" : "登录（Stub 测试）", for: .normal)

        if let error = viewModel.errorMessage {
            resultLabel.textColor = .systemRed
            resultLabel.text = "失败：\(error)"
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
            avatar: \(user.avatarURL ?? "nil")
            token: \(user.token)
            """
            return
        }

        resultLabel.textColor = .secondaryLabel
        resultLabel.text = viewModel.isLoading ? "请求中…" : "点击登录后，这里显示返回的用户信息"
    }
}
