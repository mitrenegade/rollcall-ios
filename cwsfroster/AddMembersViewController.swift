//
//  AddMembersViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 7/23/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Contacts

class AddMembersViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var constraintBottomOffset: NSLayoutConstraint!

    @IBOutlet weak var constraintNameInputHeight: NSLayoutConstraint!
    @IBOutlet weak var inputName: UITextField!
    
    var alert: UIAlertController?

    var names: [String] = []
    var emails: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Close", style: UIBarButtonItem.Style.done, target: self, action: #selector(dismissKeyboard))
        keyboardDoneButtonView.setItems([saveButton], animated: true)
        self.inputName.inputAccessoryView = keyboardDoneButtonView

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(didClickCancel(_:))) // hide/disable back button

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didClickSave(_:))) // hide/disable back button

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIResponder.keyboardWillHideNotification, object: nil)

        reloadTableData()
    }
    
    func reloadTableData() {
        tableView.reloadData()
    }

    func didAddMember() {
        print("Add member \(inputName.text)")
        defer {
            inputName.text = nil
        }
        
        guard let name = inputName.text, !name.isEmpty else {
            return
        }

        guard !names.contains(name) else {
            simpleAlert("This name has been added", message: "\(name) is already in your new members list.")
            return
        }

        names.append(name)
        reloadTableData()
    }
    
    @objc func didClickCancel(_ sender: Any?) {
        LoggingService.log(event: .addMembersCancelled, message: nil, info: nil, error: nil)
        navigationController?.dismiss(animated: true, completion: nil)
    }

    @objc func didClickSave(_ sender: Any?) {
        dismissKeyboard()
        showProgress("Adding new members")
        OrganizationService.shared.members { [weak self] (members, error) in
            if let error = error as NSError? {
                DispatchQueue.main.async {
                    self?.simpleAlert("Could not add members", defaultMessage: "There was an error adding new members.", error: error)
                }
                return
            } else {
                let filtered = self?.names.filter() { name in
                    let existing = members.filter() { return $0.name == name }
                    return existing.isEmpty
                }
                self?.addNewMembers(newNames: filtered ?? [])
            }
        }
    }
    
    fileprivate func addNewMembers(newNames: [String]) {
        let dispatchGroup = DispatchGroup()
        var count: Double = 0
        LoggingService.log(event: .addMembersSaved, message: nil, info: ["count": newNames.count], error: nil)
        for name in newNames {
            dispatchGroup.enter()
            let email = emails[name]
            OrganizationService.shared.createMember(email: email, name: name, notes: nil, status: .active) { [weak self] (member, error) in
                print("member added")
                count += 1
                DispatchQueue.main.async {
                    let progress: Double = count / Double(newNames.count)
                    self?.updateProgress(percent: progress )
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            self?.notify("member:created", object: nil, userInfo: nil)
            self?.hideProgress({
                self?.navigationController?.dismiss(animated: true, completion: nil)
            })
        }
    }
}

extension AddMembersViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewMemberCell", for: indexPath)
        guard indexPath.row < names.count else { return cell }
        let name = names[indexPath.row]
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = emails[name]
        return cell
    }
}

extension AddMembersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let row = indexPath.row
        guard row < names.count else { return }
        names.remove(at: row)
        tableView.reloadData()
    }
}

// MARK: - Contacts
extension AddMembersViewController: ContactsDelegate {
    @IBAction func didClickContacts(_ sender: Any?) {
        requestAccess { (success) in
            print("Access granted \(success)")
            if success {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "toContacts", sender: nil)
                }
            }
            LoggingService.log(event: .contactsButtonClicked, message: nil, info: ["granted": success], error: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toContacts", let controller = segue.destination as? ContactsViewController {
            controller.delegate = self
        }
    }
    
    fileprivate func requestAccess(completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            completionHandler(true)
        case .denied:
            showSettingsAlert(completionHandler)
        case .restricted, .notDetermined:
            let store = CNContactStore()
            store.requestAccess(for: .contacts) { granted, error in
                if granted {
                    completionHandler(true)
                } else {
                    DispatchQueue.main.async {
                        self.showSettingsAlert(completionHandler)
                    }
                }
            }
        }
    }
    
    private func showSettingsAlert(_ completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        let alert = UIAlertController(title: "Access to contacts needed", message: "RollCall needs permission to add members from your contacts. Would you like to grant permissions?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { action in
            LoggingService.log(event: .contactsPermissionSettings, message: nil, info: ["opened settings": true], error: nil)
            completionHandler(false)
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
            LoggingService.log(event: .contactsPermissionSettings, message: nil, info: ["opened settings": false], error: nil)
            completionHandler(false)
        })
        present(alert, animated: true)
    }
    
    func didSelectContacts(_ contacts: [CNContact]) {
        for contact in contacts {
            let name = "\(contact.givenName) \(contact.familyName)"
            let email = contact.emailAddresses.first?.value as? String
            if !names.contains(name) {
                names.append(name)
                emails[name] = email
            }
        }
        navigationController?.popToViewController(self, animated: true)
        reloadTableData()
    }
}

extension AddMembersViewController: UITextFieldDelegate {
    @objc func dismissKeyboard() {
        didAddMember()
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        constraintBottomOffset.constant = keyboardHeight
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.constraintBottomOffset.constant = 0
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didAddMember()
        return false
    }
}

extension AddMembersViewController {
    func showProgress(_ title: String?) {
        guard self.alert == nil else {
            self.alert?.title = title
            return
        }
        
        let alert = UIAlertController(title: title ?? "Progress", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { [weak self] (action) in
            self?.alert = nil
        })
        
        present(alert, animated: true, completion: nil)
        self.alert = alert
    }
    
    func hideProgress(_ completion:(()->Void)? = nil) {
        if alert == nil {
            completion?()
        } else {
            alert?.dismiss(animated: true, completion: completion)
            alert = nil
        }
    }
    
    func updateProgress(percent: Double = 0) {
        alert?.message = "\(percent * 100)%"
    }
}
