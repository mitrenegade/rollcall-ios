//
//  AddMembersViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 7/23/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class AddMembersViewController: UIViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var constraintBottomOffset: NSLayoutConstraint!

    @IBOutlet weak var constraintNameInputHeight: NSLayoutConstraint!
    @IBOutlet weak var inputName: UITextField!

    fileprivate enum AddMemberMode: Int {
        case manual = 0
        case contacts = 1
    }
    fileprivate var mode: AddMemberMode = .manual
    var names: [String] = []
    var emails: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Close", style: UIBarButtonItemStyle.done, target: self, action: #selector(dismissKeyboard))
        keyboardDoneButtonView.setItems([saveButton], animated: true)
        self.inputName.inputAccessoryView = keyboardDoneButtonView

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(didClickCancel(_:))) // hide/disable back button

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didClickSave(_:))) // hide/disable back button

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        reloadTableData()
    }

    @IBAction func segmentedControlDidChange(_ sender: Any?) {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        
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
    
    func didClickCancel(_ sender: Any?) {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    func didClickSave(_ sender: Any?) {
        // TODO: save
        navigationController?.dismiss(animated: true, completion: nil)
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
        cell.textLabel?.text = names[indexPath.row]
        return cell
    }
}

extension AddMembersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let row = indexPath.row
        guard row < names.count else { return }
        names.remove(at: row)
        tableView.reloadData()
    }
}

extension AddMembersViewController: UITextFieldDelegate {
    func dismissKeyboard() {
        didAddMember()
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
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
