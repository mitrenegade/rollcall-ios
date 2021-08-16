//
//  MembersTableViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 6/10/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

protocol MemberDelegate: class {
    func didCreateMember(_ member: FirebaseMember)
    func didUpdateMember(_ member: FirebaseMember)
}

class MembersTableViewController: UITableViewController {
    fileprivate var _members: [FirebaseMember] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        listenFor("payment:updated", action: #selector(reloadMembers), object: nil)
        listenFor("member:created", action: #selector(reloadMembers), object: nil)

        setupSettingsNavButton()
        setupPlusNavButton()
        reloadMembers()
    }
    
    fileprivate func setupSettingsNavButton() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(UIImage(named: "hamburger4-square"), for: .normal)
        button.addTarget(self, action: #selector(goToSettings), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    fileprivate func setupPlusNavButton() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(UIImage(named: "plus"), for: .normal)
        button.addTarget(self, action: #selector(goToAddMembers), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    @objc func reloadMembers() {
        OrganizationService.shared.members { [weak self] (members, error) in
            self?._members = members.sorted{
                guard let n1 = $0.name?.uppercased() else { return false }
                guard let n2 = $1.name?.uppercased() else { return true }
                return n1 < n2
            }
            self?.tableView.reloadData()
        }
    }
    
    @objc func goToSettings() {
        notify("goToSettings", object: nil, userInfo: nil)
    }
    
    @objc func goToAddMembers() {
        performSegue(withIdentifier: "toAddMembers", sender: nil)
    }
    
    fileprivate func deleteMember(at row: Int) {
        guard row < _members.count else { return }
        let member = _members[row]
        OrganizationService.shared.deleteMember(member) { [weak self] (success, error) in
            self?.reloadMembers()
            if !success {
                self?.simpleAlert("Could not delete member", message: "There was an issue deleting this member. No changes have been made.")
            }
        }
    }
    
    func close() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension MembersTableViewController {
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _members.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: MemberCell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath) as? MemberCell else { return UITableViewCell() }

        let row = indexPath.row
        guard row < _members.count else { return cell }
        cell.configure(member: _members[row], row: row)

        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            deleteMember(at: indexPath.row)
            reloadMembers()
        }
    }
}

extension MembersTableViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toEditMember", let row = tableView.indexPathForSelectedRow?.row {
            guard let nav = segue.destination as? UINavigationController, let controller = nav.viewControllers.first as? MemberInfoViewController else { return }
            controller.delegate = self
            let member = _members[row]
            controller.member = member
        } else if segue.identifier == "toAddMembers" {
            guard let nav = segue.destination as? UINavigationController, let _ = nav.viewControllers.first as? AddMembersViewController else { return }
//            controller.delegate = self
        }
    }
}

extension MembersTableViewController: MemberDelegate {
    func didCreateMember(_ member: FirebaseMember) {
        _members.append(member)
        _members = _members.sorted {
            guard let n1 = $0.name?.uppercased() else { return false }
            guard let n2 = $1.name?.uppercased() else { return true }
            return n1 < n2
        }
        tableView.reloadData()
        notify("member:updated", object: nil, userInfo: nil)
    }
    
    func didUpdateMember(_ member: FirebaseMember) {
        tableView.reloadData()
        notify("member:updated", object: nil, userInfo: nil)
    }
}
