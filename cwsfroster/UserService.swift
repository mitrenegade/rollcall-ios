//
//  UserService.swift
//  rollcall
//
//  Created by Bobby Ren on 5/20/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase
import RxSwift
import RxCocoa

/// Manages Firebase Auth as well as the /user table
class UserService {

    /// Firebase error codes:
    /// https://firebase.google.com/docs/reference/ios/firebaseauth/api/reference/Enums/FIRAuthErrorCode

    enum LoginSignupError: Error {
        case invalidUser
        case invalidFormat
        case unreachable
        case invalidPassword
        case unknown(Int)
    }

    static let shared = UserService()

    // MARK: - FirAuth

    /// Login in using email and password
    /// - Returns: Success if login worked, or a UserService.LoginError
    func loginWithEmail(_ email: String, password: String, completion: ((Result<Void, LoginSignupError>)->Void)?) {
        firAuth.signIn(withEmail: email, password: password) { [weak self] auth, error in
            if let auth = auth {
                self?.createOrUpdateFirebaseUser(id: auth.user.uid)
                completion?(.success(()))
            } else if let error = error as NSError? {
                LoggingService.log(event: .login, error: error)
                switch error.code {
                case 17009:
                    completion?(.failure(.invalidPassword))
                case 17011:
                    completion?(.failure(.invalidUser))
                case 17008:
                    completion?(.failure(.invalidFormat))
                case 17020:
                    completion?(.failure(.unreachable))
                default:
                    completion?(.failure(.unknown(error.code)))
                }
            }
        }
    }

    /// Sign up using email and password
    /// - Returns: User's UID and email if signup worked, or a UserService.SignupError
    func createEmailUser(_ email: String, password: String, completion: ((Result<(String, String), LoginSignupError>)->Void)? ) {
        firAuth.createUser(withEmail: email, password: password) { [weak self] auth, error in
            if let auth = auth {
                self?.createOrUpdateFirebaseUser(id: auth.user.uid)
                completion?(.success((auth.user.uid, auth.user.email ?? "unknown")))
            } else if let error = error as NSError? {
                LoggingService.log(event: .createEmailUser, info: ["email": email], error: error)
                switch error.code {
                case 17007:
                    completion?(.failure(.invalidUser))
                case 17008:
                    completion?(.failure(.invalidFormat))
                case 17020:
                    completion?(.failure(.unreachable))
                case 17026:
                    completion?(.failure(.invalidPassword)) // weak password
                default:
                    completion?(.failure(.unknown(error.code)))
                }
            }
        }
    }

    func logout() {
        do {
            LoggingService.log(event: .logout, message: "Logout")
            try firAuth.signOut()
            stopObservingUser()

            // notify logout success
            NotificationCenter.default.post(name: NotificationType.LogoutSuccess.name(),
                                            object: nil,
                                            userInfo: nil)

            OrganizationService.shared.onLogout()
        } catch let error {
            LoggingService.log(event: .logout, message: "Logout failure", info: nil, error: error as NSError)
            fatalError("Logout failed! \(error)")
        }
    }

    func updateEmail(_ email: String, completion: ((Error?)->Void)?) {
        firAuth.currentUser?.updateEmail(to: email, completion: completion)
    }

    func updatePassword(_ password: String, completion: ((Error?)->Void)?) {
        firAuth.currentUser?.updatePassword(to: password, completion: completion)
    }

    // TODO: use loginState
    var isLoggedIn: Bool {
        return firAuth.currentUser != nil
    }
    
    // MARK: - FirebaseUser (User details)
    var currentUserID: String? {
        guard let user = firAuth.currentUser else {
            return nil
        }

        return user.uid
    }

    var currentUserEmail: String? {
        guard let user = firAuth.currentUser else {
            return nil
        }

        return user.email
    }

    private let userRelay: BehaviorRelay<FirebaseUser?> = BehaviorRelay<FirebaseUser?>(value: nil)
    var currentUser: FirebaseUser? {
        userRelay.value
    }
    var userObservable: Observable<FirebaseUser> {
        userRelay
            .filterNil()
            .distinctUntilChanged()
    }

    private var userHandle: DatabaseHandle?
    func startObservingUser() {
        guard let userID = currentUserID else {
            return
        }

        let ref = firRef.child("users").child(userID)
        userHandle = ref.observe(.value, with: { [weak self] snapshot in
            guard snapshot.exists() else {
                return
            }
            self?.userRelay.accept(FirebaseUser(snapshot: snapshot))
        })
    }

    /// On logout, stop observing the user endpoint
    func stopObservingUser() {
        if let handle = userHandle {
            firRef.child("users").removeObserver(withHandle: handle)
        }
    }

    // MARK: - FirebaseUser (User details)
    func createOrUpdateFirebaseUser(id: String) {
        let ref = firRef.child("users").child(id)
        let params: [String: Any] = ["createdAt": Date().timeIntervalSince1970]
        ref.updateChildValues(params)
    }

    
}
