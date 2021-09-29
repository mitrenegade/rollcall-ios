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
import Balizinha

protocol UserServiceProtocol {
    var isLoggedIn: Bool { get }
    var currentSubscription: SubscriptionProduct? { get }
    var userObservable: Observable<FirebaseUser> { get }
}

/// Manages Firebase Auth as well as the /user table
class UserService: UserServiceProtocol {

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

    private let disposeBag = DisposeBag()

    private let loginStateRelay: BehaviorRelay<LoginState> = BehaviorRelay<LoginState>(value: .loggedOut)

    var loginStateObserver: Observable<LoginState> {
        loginStateRelay
            .distinctUntilChanged()
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

    /// On login, observe the user/id endpoint for user details
    func startObservingUser(_ userID: String) {
        guard !OFFLINE_MODE else {
            userRelay.accept(FirebaseOfflineParser.shared.offlineUser())
            return
        }

        print("\(self) - startObservingUser \(userID)")
        let ref = firRef.child("users").child(userID)
        userHandle = ref.observe(.value, with: { [weak self] snapshot in
            guard snapshot.exists() else {
                return
            }
            self?.userRelay.accept(FirebaseUser(snapshot: snapshot))
        })
    }

    /// On logout, stop observing the user endpoint
    private func stopObservingUser() {
        print("\(self) - stopObservingUser")
        if let handle = userHandle {
            firRef.child("users").removeObserver(withHandle: handle)
        }
    }

    // MARK: - FirAuth
    func startup() {
        guard !OFFLINE_MODE else {
            loginStateRelay.accept(.loggedIn)
            return
        }

        AuthService.shared.startup()
        AuthService.shared.loginState
            .asDriver()
            .drive(loginStateRelay)
            .disposed(by: disposeBag)
    }


    /// Login in using email and password
    /// - Returns: Success if login worked, or a UserService.LoginError
    func loginWithEmail(_ email: String, password: String, completion: ((Result<Void, LoginSignupError>)->Void)?) {
        firAuth.signIn(withEmail: email, password: password) { [weak self] auth, error in
            if let auth = auth {
                self?.startObservingUser(auth.user.uid)
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

            OrganizationService.shared.onLogout()
            userRelay.accept(nil)
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

    var isLoggedIn: Bool {
        loginStateRelay.value == .loggedIn
    }
    
    // MARK: - FirebaseUser (User details)
    var currentUserID: String? {
        guard !OFFLINE_MODE else {
            return FirebaseOfflineParser.shared.offlineUser()!.id
        }

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

    var currentSubscription: SubscriptionProduct? {
        currentUser?.subscription
    }

    // MARK: - FirebaseUser (User details)
    func createOrUpdateFirebaseUser(id: String) {
        let ref = firRef.child("users").child(id)
        let params: [String: Any] = ["createdAt": Date().timeIntervalSince1970]
        ref.updateChildValues(params)
    }

    func updateUserSubscription(_ subscriptionTier: SubscriptionProduct) {
        guard let userId = currentUserID else {
            return
        }
        let ref = firRef.child("users").child(userId)
        let params: [String: Any] = ["subscription": subscriptionTier.tier.rawValue]
        ref.updateChildValues(params)
    }
}
