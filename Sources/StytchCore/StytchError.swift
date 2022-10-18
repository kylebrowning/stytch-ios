import Foundation

/// A type representing an error within the Stytch ecosystem.
public struct StytchError: Error, Decodable, Equatable {
    /// The HTTP status code associated with the error. Nil if error originated from the client.
    public let statusCode: Int?
    /// The id of the request. Nil if error originated from the client.
    public let requestId: String?
    /// The type of the error.
    public let errorType: String
    /// The message associated with the error.
    public var message: String { errorMessage }
    private let errorMessage: String
    /// The url at which further information about the error can be found. Nil if no additional information available.
    public var url: URL? { errorUrl }
    private let errorUrl: URL?

    init(
        statusCode: Int? = nil,
        requestId: String? = nil,
        errorType: String,
        errorMessage: String,
        errorUrl: URL? = nil
    ) {
        self.statusCode = statusCode
        self.requestId = requestId
        self.errorType = errorType
        self.errorMessage = errorMessage
        self.errorUrl = errorUrl
    }
}

public extension StytchError {
    static let clientNotConfigured: Self = .init(
        errorType: "client_not_configured",
        errorMessage: "StytchClient not yet configured. Must include a `StytchConfiguration.plist` in your main bundle or call `StytchClient.configure(hostUrl:publicToken:)` prior to other StytchClient calls.",
        errorUrl: .readmeUrl(withFragment: "configuration")
    )
    static let pckeNotAvailable: Self = .init(
        errorType: "pcke_not_available",
        errorMessage: "No PKCE code_verifier available. Redirect authentication must begin/end on this device."
    )
    static let randomNumberGenerationFailed: Self = .init(
        errorType: "random_number_generation_failed",
        errorMessage: "System unable to generate a random data. Typically used for PKCE."
    )
    static let unrecognizedDeeplinkTokenType: Self = .init(
        errorType: "unrecognized_deeplink_token_type",
        errorMessage: "Deeplink received with unrecognized `stytch_token_type`. Recognized values are `magic_links`, `oauth`, or `reset_password`"
    )
    static let noCurrentSession: Self = .init(
        errorType: "no_current_session",
        errorMessage: "There is no session currently available. Must authenticate prior to calling this method."
    )
    static let noBiometricRegistrationsAvailable: Self = .init(
        errorType: "no_biometric_registrations",
        errorMessage: "There are no biometric registrations available. Must authenticate with other methods and add a new biometric registration before calling this method."
    )
    static let oauthCredentialInvalid: Self = .init(
        errorType: "oauth_apple_credential_invalid",
        errorMessage: "The Sign In With Apple authorization credential was an invalid type/format."
    )
    static let oauthCredentialMissingIdToken: Self = .init(
        errorType: "oauth_apple_missing_id_token",
        errorMessage: "The Sign In With Apple authorization credential was missing an id_token."
    )
    static let oauthInvalidStartUrl: Self = .init(
        errorType: "oauth_generic_invalid_start_url",
        errorMessage: "The start url was invalid or improperly formatted."
    )
    static let passkeysInvalidPublicKeyCredentialType: Self = .init(
        errorType: "passkeys_invalid_credential_type",
        errorMessage: "The public key credential type was not of the expected type."
    )
    static let passkeysMissingAttestationObject: Self = .init(
        errorType: "passkeys_missing_attestation_object",
        errorMessage: "The public key credential is missing the attestation object."
    )
    static let jsonDataNotConvertibleToString: Self = .init(
        errorType: "json_data_not_convertible_to_string",
        errorMessage: "JSON data unable to be converted to String type."
    )
}

private extension URL {
    static func readmeUrl(withFragment fragment: String) -> Self? {
        guard var urlComponents = URLComponents(string: "https://github.com/stytchauth/stytch-swift") else {
            return nil
        }
        urlComponents.fragment = fragment
        return urlComponents.url
    }
}
