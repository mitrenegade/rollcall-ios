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
    static let shared = UserService()

    // MARK: - FirAuth
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
    func createFirebaseUser(id: String) {
        // TODO: does this need to be a user? can it be in the organization?
        let ref = firRef.child("users").child(id)
        let params: [String: Any] = ["createdAt": Date().timeIntervalSince1970]
        ref.updateChildValues(params)
    }

    
}
