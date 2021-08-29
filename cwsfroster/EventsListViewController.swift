//
//  EventsListViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 8/21/2021.
//

import Foundation
import UIKit

var _practices: [FirebaseEvent]?
class EventsListViewController: UITableViewController {
    open override func viewDidLoad() {
        super.viewDidLoad()

        setupSettingsNavButton()
        setupPlusNavButton()
        reloadPractices()
        listenFor("practice:info:updated", action: #selector(reloadPractices), object: nil)
    }

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if segue.identifier == "toNewEvent" {
            let nav = segue.destination as? UINavigationController
            let controller = nav?.viewControllers.first as? EventEditViewController
            controller?.delegate = self
        } else if segue.identifier == "EventListToDetail" {
            let nav = segue.destination as? UINavigationController
            let controller = nav?.viewControllers.first as? EventEditViewController
            if let indexPath = tableView.indexPathForSelectedRow {
                controller?.practice = practice(for: indexPath.row)
            }
            controller?.delegate = self
        }
    }

    @objc func setupSettingsNavButton() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(UIImage(named: "hamburger4-square"), for: .normal)
        button.addTarget(self, action: #selector(goToSettings), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    @objc func setupPlusNavButton() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(UIImage(named: "plus"), for: .normal)
        button.addTarget(self, action: #selector(goToAddEvent), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    @objc func goToSettings() {
        notify("goToSettings", object: nil, userInfo: nil)
    }
    
    @objc func goToAddEvent() {
        performSegue(withIdentifier: "toNewEvent", sender: nil)
    }
}
extension EventsListViewController {
    var practices: [FirebaseEvent] {
        return _practices ?? []
    }
    
    open override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return practices.count
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PracticeCell", for: indexPath)

        // Configure the cell...
        guard let practice = self.practice(for: indexPath.row) else { return cell }
        var title: String = practice.title ?? ""
        if TESTING, let dateString = practice.date?.dateString() {
            title = "\(title) - \(dateString)"
        }
        cell.textLabel?.text = title
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        cell.textLabel?.textColor = .black
        
        var details: String = practice.details ?? ""
        if TESTING {
            details = "\(details) - \(practice.id)"
        }
        cell.detailTextLabel?.text = details
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.detailTextLabel?.textColor = UIColor.darkGray

        return cell
    }

    open override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    open override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        self.deletePracticeAt(indexPath: indexPath as NSIndexPath)
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "EventListToDetail", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
extension EventsListViewController {
    @objc func reloadPractices() {
        OrganizationService.shared.events { [weak self] (events, error) in
            if let error = error as NSError?, let reason = error.userInfo["reason"] as? String, reason == "no org" {
                // this can happen on first login when the user is transitioned over to firebase and the org listener has not completed
                print("uh oh this shouldn't happen. org must be loaded before loading events")
            } else {
                _practices = events.sorted(by: { (p1, p2) -> Bool in
                    guard let t1 = p1.date else { return false }
                    guard let t2 = p2.date else { return true }
                    return t1.compare(t2) == .orderedDescending
                })
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        }
    }

    @objc func practice(for row: Int) -> FirebaseEvent? {
        return practices[row]
    }
}

extension EventsListViewController: PracticeEditDelegate {
    public func didCreatePractice() {
        // query from web
        self.reloadPractices()
    }
    
    public func didEditPractice() {
        // query from web
        self.reloadPractices()
    }

    func deletePracticeAt(indexPath: NSIndexPath) {
        guard let practices = _practices else {
            self.tableView.reloadData()
            return
        }
        let event = practices[indexPath.row] as FirebaseEvent
        EventService.shared.deleteEvent(event) { [weak self] result in
            switch result {
            case .failure(let error):
                print("BOBBYTEST event delete failed \(error)")
                self?.tableView.reloadData()
                LoggingService.log(event: .deleteEvent, error: error as NSError)
            case .success:
                self?.tableView.reloadData()
                LoggingService.log(event: .deleteEvent)
            }
        }
    }

}

// MARK: - Power user feedback
extension EventsListViewController {
    func promptForPowerUserFeedback() {
        let alert = UIAlertController(title: "Congratulations, Power User", message: "Thanks for using RollCall! You have created at least 5 events. As a Power User, your feedback is really important to us. How can we improve?", preferredStyle: .alert)
        alert.addTextField { (textField) in
        }
        alert.addAction(UIAlertAction(title: "Send Feedback", style: .cancel, handler: { (action) in
            if let textField = alert.textFields?.first, let text = textField.text {
                LoggingService.log(type: "PowerUserFeedback", message: text)
            }
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .default, handler: { (action) in
            let deferDate = Date(timeIntervalSinceNow: 3600*24*7)
            UserDefaults.standard.set(deferDate, forKey: powerUserPromptDeferDate)
            UserDefaults.standard.synchronize()
            LoggingService.log(type: "PowerUserFeedbackLater")
        }))
        alert.addAction(UIAlertAction(title: "No Thanks", style: .default, handler: { (action) in
            let deferDate = Date(timeIntervalSinceNow: 3600*24*7*52)
            UserDefaults.standard.set(deferDate, forKey: powerUserPromptDeferDate)
            UserDefaults.standard.synchronize()
            LoggingService.log(type: "PowerUserFeedbackNever")
        }))
        self.present(alert, animated: true, completion: nil)
    }

}
