//
//  IPaAppleSignIn.swift
//  IPaAppleSignIn
//
//  Created by IPa Chen on 2020/6/3.
//  Updated for async/await and SwiftUI support
//

import UIKit
import AuthenticationServices

// MARK: - Result Types

public enum IPaAppleSignInResult {
    case appleID(ASAuthorizationAppleIDCredential)
    case password(ASPasswordCredential)
}

public enum IPaAppleSignInError: Error, LocalizedError {
    case canceled
    case failed
    case invalidResponse
    case notHandled
    case unknown
    case noWindow
    case other(Error)

    public var errorDescription: String? {
        switch self {
        case .canceled:
            return "User canceled sign in"
        case .failed:
            return "Sign in failed"
        case .invalidResponse:
            return "Invalid response"
        case .notHandled:
            return "Request not handled"
        case .unknown:
            return "Unknown error"
        case .noWindow:
            return "No window available"
        case .other(let error):
            return error.localizedDescription
        }
    }

    init(from error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                self = .canceled
            case .failed:
                self = .failed
            case .invalidResponse:
                self = .invalidResponse
            case .notHandled:
                self = .notHandled
            case .unknown:
                self = .unknown
            @unknown default:
                self = .other(error)
            }
        } else {
            self = .other(error)
        }
    }
}

// MARK: - IPaAppleSignIn

open class IPaAppleSignIn: NSObject {

    // MARK: - Properties

    private var authorizationController: ASAuthorizationController?
    private var continuation: CheckedContinuation<IPaAppleSignInResult, Error>?

    // MARK: - Initialization

    public override init() {
        super.init()
    }

    private func setupController(with requests: [ASAuthorizationRequest]) {
        authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController?.delegate = self
        authorizationController?.presentationContextProvider = self
    }

    // MARK: - Async API

    /// Perform Apple Sign In with async/await
    /// - Parameter scopes: The requested scopes (default: fullName and email)
    /// - Returns: The sign in result containing the credential
    @MainActor
    public func signIn(scopes: [ASAuthorization.Scope] = [.fullName, .email]) async throws -> IPaAppleSignInResult {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = scopes

        return try await signIn(with: [request])
    }

    /// Perform Apple Sign In with custom requests using async/await
    /// - Parameter requests: The authorization requests
    /// - Returns: The sign in result containing the credential
    @MainActor
    public func signIn(with requests: [ASAuthorizationRequest]) async throws -> IPaAppleSignInResult {
        setupController(with: requests)

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.authorizationController?.performRequests()
        }
    }

    /// Get the identity token string from Apple Sign In
    /// - Parameter scopes: The requested scopes (default: fullName and email)
    /// - Returns: The identity token as a string
    @MainActor
    public func getIdentityToken(scopes: [ASAuthorization.Scope] = [.fullName, .email]) async throws -> String {
        let result = try await signIn(scopes: scopes)

        switch result {
        case .appleID(let credential):
            guard let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                throw IPaAppleSignInError.invalidResponse
            }
            return token
        case .password:
            throw IPaAppleSignInError.invalidResponse
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension IPaAppleSignIn: ASAuthorizationControllerDelegate {

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation?.resume(returning: .appleID(appleIDCredential))
            continuation = nil
        } else if let passwordCredential = authorization.credential as? ASPasswordCredential {
            continuation?.resume(returning: .password(passwordCredential))
            continuation = nil
        }
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let signInError = IPaAppleSignInError(from: error)
        continuation?.resume(throwing: signInError)
        continuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension IPaAppleSignIn: ASAuthorizationControllerPresentationContextProviding {

    @MainActor
    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return MainActor.assumeIsolated {
            keyWindow ?? UIWindow()
        }
    }
}
