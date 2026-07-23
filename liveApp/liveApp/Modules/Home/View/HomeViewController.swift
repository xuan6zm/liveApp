import UIKit
import SnapKit

/// 首页占位：根控制器，可弹出登录页。
@MainActor
final class HomeViewController: UIViewController {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("打开登录", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 17)
        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "首页"
        setupUI()
    }

    private func setupUI() {
        titleLabel.text = "欢迎来到 liveApp"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center

        subtitleLabel.text = "这是首页占位页\n后续在这里接直播列表 / 主功能"
        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, loginButton])
        stack.axis = .vertical
        stack.spacing = 16
        view.addSubview(stack)

        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalTo(view.layoutMarginsGuide)
        }
    }

    @objc private func loginTapped() {
        let login = LoginViewController()
        let nav = UINavigationController(rootViewController: login)
        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(nav, animated: true)
    }
}
