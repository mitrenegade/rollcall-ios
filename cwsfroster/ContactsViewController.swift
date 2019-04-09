//
//  ContactsViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 7/23/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Contacts

protocol ContactsDelegate: class {
    func didSelectContacts(_ contacts: [CNContact])
}
class ContactsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var contacts: [(contact: CNContact, selected: Bool)] = []
    
    weak var delegate: ContactsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(didClickSave(_:)))
        loadContacts()
    }

    func reloadTableData() {
        tableView.reloadData()
    }

    func loadContacts() {
        let contactStore = CNContactStore()
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey] as [Any]

        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch let error {
            print("Error fetching containers \(error)")
        }

        var results: [CNContact] = []

        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)

            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                results.append(contentsOf: containerResults)
            } catch let error {
                print("Error fetching results for container \(error)")
            }
        }

        contacts.removeAll()
        for contact in results {
            contacts.append((contact, false))
        }
        reloadTableData()
    }
    
    @objc func didClickSave(_ sender: Any?) {
        let results = contacts.filter { (tuple) -> Bool in
            return tuple.selected
            }.compactMap() { return $0.contact }
        delegate?.didSelectContacts(results)
        LoggingService.log(event: .contactsAdded, message: nil, info: ["count": results.count], error: nil)
    }
}

extension ContactsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
        guard indexPath.row < contacts.count else { return cell }
        let contact = contacts[indexPath.row].contact
        let selected = contacts[indexPath.row].selected
        let name = "\(contact.givenName) \(contact.familyName)"
        let email = contact.emailAddresses.first?.value as String?
        cell.configure(name: name, email: email, selected: selected)
        return cell
    }
}

extension ContactsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selected = contacts[indexPath.row].selected
        contacts[indexPath.row].selected = !selected
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
