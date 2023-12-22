import Foundation
import StytchCore

protocol ActionableInfoViewModelDelegate {
    func launchCheckYourEmail(email: String)
    func launchForgotPassword(email: String)
}

protocol ActionableInfoViewModelProtocol {
    func forgotPassword(email: String) async throws
    func loginWithoutPassword(email: String) async throws
}

final class ActionableInfoViewModel {
    let state: ActionableInfoState

    init(state: ActionableInfoState) {
        self.state = state
    }
}

extension ActionableInfoViewModel: ActionableInfoViewModelProtocol {
    func loginWithoutPassword(email: String) async throws {
        guard let magicLink = state.config.magicLink else { return }
        let params = params(email: email, magicLink: magicLink)
        _ = try await StytchClient.magicLinks.email.loginOrCreate(parameters: params)
    }
    
    func forgotPassword(email: String) async throws {
        guard let password = state.config.password else { return }
        StytchUIClient.pendingResetEmail = email
        let params = params(email: email, password: password)
        _ = try await StytchClient.passwords.resetByEmailStart(parameters: params)
    }
}

struct ActionableInfoState {
    let config: StytchUIClient.Configuration
    let email: String
    let title: String
    let infoComponents: [AttrStringComponent]
    let actionComponents: [AttrStringComponent]
    let secondaryAction: (title: String, action: ActionableInfoAction)?
    let retryAction: RetryAction
}

extension ActionableInfoState {
    typealias RetryAction = () async throws -> Void
    static func forgotPassword(config: StytchUIClient.Configuration, email: String, retryAction: @escaping RetryAction) -> Self {
        .init(
            config: config,
            email: email,
            title: NSLocalizedString("stytch.aiForgotPW", value: "Forgot password?", comment: ""),
            infoComponents: [
                .string(NSLocalizedString("stytch.linkToResetPWSent", value: "A link to reset your password was sent to you at ", comment: "")),
                .bold(.string(email)),
            ],
            actionComponents: .didntGetItResendEmail,
            secondaryAction: nil,
            retryAction: retryAction
        )
    }

    static func checkYourEmail(config: StytchUIClient.Configuration, email: String, retryAction: @escaping RetryAction) -> Self {
        .init(
            config: config,
            email: email,
            title: .checkEmail,
            infoComponents: [.string(.loginLinkSentToYou), .bold(.string(email)), "."],
            actionComponents: .didntGetItResendEmail,
            secondaryAction: nil,
            retryAction: retryAction
        )
    }

    static func checkYourEmailCreatePWInstead(config: StytchUIClient.Configuration, email: String, retryAction: @escaping RetryAction) -> Self {
        .init(
            config: config,
            email: email,
            title: .checkEmail,
            infoComponents: [.string(.loginLinkSentToYou), .bold(.string(email)), "."],
            actionComponents: .didntGetItResendEmail,
            secondaryAction: (NSLocalizedString("stytch.aiCreatePWInstead", value: "Create a password instead", comment: ""), .didTapCreatePassword(email: email)),
            retryAction: retryAction
        )
    }

    static func checkYourEmailReset(config: StytchUIClient.Configuration, email: String, retryAction: @escaping RetryAction) -> Self {
        .init(
            config: config,
            email: email,
            title: .checkEmailForNewPW,
            infoComponents: [
                .string(.loginLinkSentToYou),
                .bold(.string(email)),
                .string(NSLocalizedString("stytch.toCreatePW", value: " to create a password for your account.", comment: "")),
            ],
            actionComponents: .didntGetItResendEmail,
            secondaryAction: nil,
            retryAction: retryAction
        )
    }

    static func checkYourEmailResetReturning(config: StytchUIClient.Configuration, email: String, retryAction: @escaping RetryAction) -> Self {
        .init(
            config: config,
            email: email,
            title: .checkEmailForNewPW,
            infoComponents: [
                .string(NSLocalizedString("stytch.aiMakeSureAcctSecure", value: "We want to make sure your account is secure and that it’s really you logging in. A login link was sent to you at ", comment: "")),
                .bold(.string(email)),
                .string(.period),
            ],
            actionComponents: .didntGetItResendEmail,
            secondaryAction: (.loginWithoutPW, .didTapLoginWithoutPassword(email: email)),
            retryAction: retryAction
        )
    }

    static func checkYourEmailResetBreached(config: StytchUIClient.Configuration, email: String, retryAction: @escaping RetryAction) -> Self {
        .init(
            config: config,
            email: email,
            title: .checkEmailForNewPW,
            infoComponents: [
                .string(NSLocalizedString("stytch.aiPWBreach", value: "A different site where you use the same password had a security issue recently. For your safety, an email was sent to you at ", comment: "")),
                .bold(.string(email)),
                .string(NSLocalizedString("stytch.toResetPW", value: " to reset your password.", comment: "")),
            ],
            actionComponents: .didntGetItResendEmail,
            secondaryAction: (.loginWithoutPW, .didTapLoginWithoutPassword(email: email)),
            retryAction: retryAction
        )
    }
}

enum ActionableInfoAction {
    case didTapCreatePassword(email: String)
    case didTapLoginWithoutPassword(email: String)
}

private extension ActionableInfoViewModel {
    var sessionDuration: Minutes {
        state.config.session?.sessionDuration ?? .defaultSessionDuration
    }

    func params(email: String, password: StytchUIClient.Configuration.Password) -> StytchClient.Passwords.ResetByEmailStartParameters {
        .init(
            email: email,
            loginUrl: password.loginURL,
            loginExpiration: password.loginExpiration,
            resetPasswordUrl: password.resetPasswordURL,
            resetPasswordExpiration: password.resetPasswordExpiration,
            resetPasswordTemplateId: password.resetPasswordTemplateId
        )
    }

    func params(email: String, magicLink: StytchUIClient.Configuration.MagicLink) -> StytchClient.MagicLinks.Email.Parameters {
        .init(
            email: email,
            loginMagicLinkUrl: magicLink.loginMagicLinkUrl,
            loginExpiration: magicLink.loginExpiration,
            loginTemplateId: magicLink.loginTemplateId,
            signupMagicLinkUrl: magicLink.signupMagicLinkUrl,
            signupExpiration: magicLink.signupExpiration,
            signupTemplateId: magicLink.signupTemplateId
        )
    }
}

private extension String {
    static let checkEmail: String = NSLocalizedString("stytch.aiCheckEmail", value: "Check your email", comment: "")
    static let checkEmailForNewPW: String = NSLocalizedString("stytch.aiCheckEmailForPW", value: "Check your email to set a new password", comment: "")
    static let loginLinkSentToYou: String = NSLocalizedString("stytch.aiLoginLinkSentAt", value: "A login link was sent to you at ", comment: "")
    static let loginWithoutPW: String = NSLocalizedString("stytch.aiLoginWithoutPW", value: "Login without a password", comment: "")
    static let period: String = NSLocalizedString("stytch.aiPeriod", value: ".", comment: "")
}
