//
//  IPaAppleSignIn+SwiftUI.swift
//  IPaAppleSignIn
//
//  Created by IPa Chen on 2020/6/3.
//  SwiftUI support
//

import SwiftUI
import AuthenticationServices

// MARK: - View Extension

public extension View {

    /// Add Apple Sign In capability to any view via tap gesture
    /// - Parameters:
    ///   - scopes: The requested scopes (default: fullName and email)
    ///   - onCompletion: Completion handler with result
    func onAppleSignIn(
        scopes: [ASAuthorization.Scope] = [.fullName, .email],
        onCompletion: @escaping (Result<IPaAppleSignInResult, Error>) -> Void
    ) -> some View {
        modifier(IPaAppleSignInModifier(scopes: scopes, onCompletion: onCompletion))
    }

    /// Add Apple Sign In capability to get identity token directly
    /// - Parameters:
    ///   - scopes: The requested scopes (default: fullName and email)
    ///   - onToken: Completion handler with token string
    ///   - onError: Error handler
    func onAppleSignInToken(
        scopes: [ASAuthorization.Scope] = [.fullName, .email],
        onToken: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) -> some View {
        modifier(IPaAppleSignInTokenModifier(scopes: scopes, onToken: onToken, onError: onError))
    }
}

// MARK: - View Modifiers

private struct IPaAppleSignInModifier: ViewModifier {
    let scopes: [ASAuthorization.Scope]
    let onCompletion: (Result<IPaAppleSignInResult, Error>) -> Void

    @State private var appleSignIn = IPaAppleSignIn()

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                Task { @MainActor in
                    do {
                        let result = try await appleSignIn.signIn(scopes: scopes)
                        onCompletion(.success(result))
                    } catch {
                        onCompletion(.failure(error))
                    }
                }
            }
    }
}

private struct IPaAppleSignInTokenModifier: ViewModifier {
    let scopes: [ASAuthorization.Scope]
    let onToken: (String) -> Void
    let onError: (Error) -> Void

    @State private var appleSignIn = IPaAppleSignIn()

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                Task { @MainActor in
                    do {
                        let token = try await appleSignIn.getIdentityToken(scopes: scopes)
                        onToken(token)
                    } catch {
                        onError(error)
                    }
                }
            }
    }
}

