//
//  IPaAppleSignIn.swift
//  IPaAppleSignIn
//
//  Created by IPa Chen on 2020/6/3.
//

import UIKit
import AuthenticationServices
@available(iOS 13.0, *)
@objc public protocol IPaAppleSignInDelegate
{
    @objc optional func authorizationComplete(_ appleSignIn:IPaAppleSignIn, withAppleSignIn credential:ASAuthorizationAppleIDCredential)
    @objc optional func authorizationComplete(_ appleSignIn:IPaAppleSignIn, withPassword credential:ASPasswordCredential)
    @objc optional func authorizationComplete(appleSignIn:IPaAppleSignIn, with error:Error)
}
@available(iOS 13.0, *)
@objc open class IPaAppleSignIn: NSObject {
    var delegate:IPaAppleSignInDelegate
    var authorizationController:ASAuthorizationController
    @objc public init(_ requests:[ASAuthorizationRequest],delegate:IPaAppleSignInDelegate) {
        
        self.delegate = delegate
        self.authorizationController = ASAuthorizationController(authorizationRequests:requests)
        super.init()
        self.authorizationController.delegate = self
        self.authorizationController.presentationContextProvider = self
    }
    @objc public func createAppleIDButton(_ type:ASAuthorizationAppleIDButton.ButtonType, style:ASAuthorizationAppleIDButton.Style) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.addTarget(self, action: #selector(self.onAppleSignIn(_:)), for: .touchUpInside)
        return button
    }
    @objc public func bindAppleIDButton(_ button:UIButton) {
        button.addTarget(self, action: #selector(self.onAppleSignIn(_:)), for: .touchUpInside)
    }
    @objc func onAppleSignIn(_ sender:Any) {
        
        self.authorizationController.performRequests()
    }
    
}
@available(iOS 13.0, *)
extension IPaAppleSignIn:ASAuthorizationControllerDelegate
{
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            self.delegate.authorizationComplete?(self, withAppleSignIn: appleIDCredential)
            
        }
        else if let _ = authorization.provider as? ASAuthorizationPasswordProvider, let passwordCredential = authorization.credential as? ASPasswordCredential {
            self.delegate.authorizationComplete?(self, withPassword: passwordCredential)
        }
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
//        switch (error) {
//        case ASAuthorizationError.canceled:
//            break
//        case ASAuthorizationError.failed:
//            break
//        case ASAuthorizationError.invalidResponse:
//            break
//        case ASAuthorizationError.notHandled:
//            break
//        case ASAuthorizationError.unknown:
//            break
//        default:
//            break
//        }
//
     //   print("didCompleteWithError: \(error.localizedDescription)")
        self.delegate.authorizationComplete?(appleSignIn: self, with: error)
        
    }
}
@available(iOS 13.0, *)
extension IPaAppleSignIn:ASAuthorizationControllerPresentationContextProviding
{
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor
    {
        return UIApplication.shared.windows.first!
    }
}
