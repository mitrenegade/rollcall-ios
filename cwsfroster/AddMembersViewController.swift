//
//  AddMembersViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 7/23/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class AddMembersViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    fileprivate enum AddMemberMode: Int {
        case manual = 0
        case contacts = 1
    }
    fileprivate var mode: AddMemberMode = .manual
    var names: [String] = []
    var emails: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        reloadTableData()
    }

    @IBAction func segmentedControlDidChange(_ sender: Any?) {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        
        reloadTableData()
    }
    
    func reloadTableData() {
        tableView.reloadData()
    }
}

extension AddMembersViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell: MemberNameInputCell = tableView.dequeueReusableCell(withIdentifier: "MemberNameInputCell", for: indexPath) as? MemberNameInputCell else { return UITableViewCell() }
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewMemberCell", for: indexPath)
            guard indexPath.row < names.count else { return cell }
            cell.textLabel?.text = names[indexPath.row]
//            cell.detailTextLabel?.text = emails[indexPath.row]
            return cell
        }
    }
}

extension AddMembersViewController: MemberNameInputDelegate {
    func didAddMember(name: String) {
        names.append(name)
        reloadTableData()
    }
}
