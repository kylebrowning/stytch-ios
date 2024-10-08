extension StytchClient {
    struct Bootstrap {
        let router: NetworkingRouter<BootstrapRoute>

        #if os(iOS)
        @Dependency(\.captcha) private var captcha
        #endif
        @Dependency(\.networkingClient) private var networkingClient
        @Dependency(\.localStorage) private var localStorage

        func fetch() async throws {
            guard let publicToken = StytchClient.instance.configuration?.publicToken else {
                throw StytchSDKError.consumerSDKNotConfigured
            }
            let bootstrapData = try await router.get(route: .fetch(Path(rawValue: publicToken))) as BootstrapResponse
            localStorage.bootstrapData = bootstrapData.wrapped
            #if os(iOS)
            networkingClient.dfpEnabled = bootstrapData.wrapped.dfpProtectedAuthEnabled
            networkingClient.dfpAuthMode = bootstrapData.wrapped.dfpProtectedAuthMode ?? DFPProtectedAuthMode.observation
            guard let siteKey = bootstrapData.wrapped.captchaSettings.siteKey else {
                return
            }
            await captcha.setCaptchaClient(siteKey: siteKey)
            #endif
        }
    }
}

internal extension StytchClient {
    /// The interface for interacting with magic-links products.
    static var bootstrap: Bootstrap { .init(router: router.scopedRouter { $0.bootstrap }) }
}
