import Combine

public extension StytchB2BClient {
    /// The interface for interacting with sessions products.
    static var sessions: StytchB2BClientSessions {
        .init(router: router.scopedRouter { $0.sessions })
    }
}

/// The SDK may be used to check whether a user has a cached session, view the current session, refresh the session, and revoke the session. To authenticate a session on your backend, you must use either the Stytch API or a Stytch server-side library. **NOTE**: - After a successful authentication, the session will be automatically refreshed in the background to ensure the sessionJwt remains valid (it expires after 5 minutes.) Session polling will be stopped after a session is revoked or after an unauthenticated error response is received.
public struct StytchB2BClientSessions {
    let router: NetworkingRouter<StytchB2BClient.B2BSessionsRoute>
    @Dependency(\.sessionStorage) var sessionStorage
    @Dependency(\.localStorage) var localStorage

    public var memberSession: MemberSession? {
        get {
            localStorage.memberSession
        }
        set {
            localStorage.memberSession = newValue
        }
    }

    /// An opaque token representing your session, which your servers can check with Stytch's servers to verify your session status.
    public var sessionToken: SessionToken? {
        sessionStorage.sessionToken
    }

    /// A session JWT (JSON Web Token), which your servers can check locally to verify your session status.
    public var sessionJwt: SessionToken? {
        sessionStorage.sessionJwt
    }

    /// A publisher which emits following a change in authentication status and returns either the opaque session token or nil. You can use this as an indicator to set up or tear down your UI accordingly.
    public var onAuthChange: AnyPublisher<String?, Never> {
        sessionStorage.onAuthChange.eraseToAnyPublisher()
    }

    // sourcery: AsyncVariants, (NOTE: - must use /// doc comment styling)
    /// Wraps Stytch's [authenticate](https://stytch.com/docs/api/session-auth) Session endpoint and validates that the session issued to the user is still valid, returning both an opaque sessionToken and sessionJwt for this session. The sessionJwt will have a fixed lifetime of five minutes regardless of the underlying session duration, though it will be refreshed automatically in the background after a successful authentication.
    public func authenticate(parameters: Sessions.AuthenticateParameters) async throws -> B2BAuthenticateResponse {
        try await router.post(to: .authenticate, parameters: parameters)
    }

    /// If your app has cookies disabled or simply receives updated session tokens from your backend via means other than
    /// `Set-Cookie` headers, you must call this method after receiving the updated tokens to ensure the `StytchClient`
    /// and persistent storage are kept up-to-date. You are required to include both the opaque token and the jwt.
    public func update(sessionTokens: SessionTokens) {
        sessionStorage.updatePersistentStorage(tokens: sessionTokens)
    }

    // sourcery: AsyncVariants, (NOTE: - must use /// doc comment styling)
    /// Wraps Stytch's [revoke](https://stytch.com/docs/api/session-revoke) Session endpoint and revokes the user's current session. This method should be used to log out a user. A successful revocation will terminate session-refresh polling.
    public func revoke(parameters: Sessions.RevokeParameters = .init()) async throws -> BasicResponse {
        do {
            let response: BasicResponse = try await router.post(to: .revoke, parameters: EmptyCodable())
            sessionStorage.reset()
            return response
        } catch {
            if parameters.forceClear { sessionStorage.reset() }
            throw error
        }
    }

    // sourcery: AsyncVariants, (NOTE: - must use /// doc comment styling)
    /// Use this endpoint to exchange a Member's existing session for another session in a different Organization.
    public func exchange(parameters: ExchangeParameters) async throws -> B2BMFAAuthenticateResponse {
        try await router.post(to: .exchange, parameters: parameters)
    }
}

public extension StytchB2BClientSessions {
    /// The dedicated parameters type for session `exchange` calls.
    struct ExchangeParameters: Codable {
        /// The ID of the organization that the new session should belong to.
        public let organizationID: String
        /// The duration, in minutes, for the requested session. Defaults to 30 minutes.
        public let sessionDurationMinutes: Minutes
        /// The locale will be used if an OTP code is sent to the member's phone number as part of a secondary authentication requirement.
        public let locale: String?

        public init(organizationID: String, sessionDurationMinutes: Minutes = .defaultSessionDuration, locale: String? = nil) {
            self.organizationID = organizationID
            self.sessionDurationMinutes = sessionDurationMinutes
            self.locale = locale
        }
    }
}
