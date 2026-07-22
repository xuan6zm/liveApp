import Alamofire
import Foundation
import Moya

/// 组装 `MoyaProvider`：Session 超时、插件顺序固定为 Auth → DebugLogger。
nonisolated enum MoyaProviderFactory {
    static func make(
        timeoutInterval: TimeInterval = NetworkConstant.timeoutInterval,
        tokenProvider: @escaping @Sendable () -> String?,
        stubClosure: @escaping MoyaProvider<MultiTarget>.StubClosure = MoyaProvider.neverStub
    ) -> MoyaProvider<MultiTarget> {
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = timeoutInterval
        configuration.timeoutIntervalForResource = timeoutInterval

        let session = Session(configuration: configuration)
        let plugins = makePlugins(tokenProvider: tokenProvider)

        return MoyaProvider<MultiTarget>(
            stubClosure: stubClosure,
            session: session,
            plugins: plugins
        )
    }

    private static func makePlugins(
        tokenProvider: @escaping @Sendable () -> String?
    ) -> [PluginType] {
        var plugins: [PluginType] = [
            AuthPlugin(tokenProvider: tokenProvider)
        ]

        #if DEBUG
        plugins.append(DebugLoggerPlugin())
        #endif

        return plugins
    }
}
