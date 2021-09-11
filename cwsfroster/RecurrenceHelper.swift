//
//  RecurrenceHelper.swift
//  rollcall
//
//  Created by Bobby Ren on 9/10/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

import Foundation

protocol RecurrenceCellDelegate: class {
    func didSelectRecurrence(_ recurrence: Date.Recurrence, _ recurrenceEndDate: Date?)
    func refreshToggleEnabled()
    func refresh()
}

internal final class RecurrenceHelper {
    private (set) var datesForPicker: [Date] = []

    var recurrence: Date.Recurrence = .none
    var recurrenceStartDate: Date? {
        didSet {
            delegate?.refreshToggleEnabled()
        }
    }
    var recurrenceEndDate: Date?
    weak var presenter: UIViewController?
    weak var delegate: RecurrenceCellDelegate?

    private var datePickerView: UIPickerView = UIPickerView()
    private var keyboardDoneButtonView: UIToolbar = UIToolbar()

    func promptForRecurrence() {
        let alert = UIAlertController(title: "Select recurrence", message: nil, preferredStyle: .actionSheet)
        for option in [Date.Recurrence.daily, Date.Recurrence.weekly, Date.Recurrence.monthly] {
            alert.addAction(UIAlertAction(title: option.rawValue.capitalized, style: .default, handler: { (action) in
                self.selectRecurrence(option)
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            self.cancelRecurrence()
        })
        if (UIDevice.current.userInterfaceIdiom == .pad)
        {
            alert.popoverPresentationController?.sourceView = self.presenter?.view
            alert.popoverPresentationController?.sourceRect = self.presenter?.view.frame ?? <#default value#>
        }
        presenter?.present(alert, animated: true, completion: nil)
    }

    func selectRecurrence(_ recurrence: Date.Recurrence) {
        self.recurrence = recurrence
        delegate?.refresh()

        // select date
        delegate?.didSelectRecurrence(recurrence, nil)
        if recurrence != .none {
            promptForDate()
        }
    }

    func promptForDate() {
        generatePickerDates()
        self.recurrenceField.becomeFirstResponder()
    }

    @objc func done() {
        // on button click on toolbar for day, time pickers
        recurrenceField.resignFirstResponder()
        let row = datePickerView.selectedRow(inComponent: 0)
        guard row < self.datesForPicker.count else { return }
        recurrenceEndDate = self.datesForPicker[row]
        recurrenceDelegate?.didSelectRecurrence(recurrence, recurrenceEndDate)
        refresh()
    }

    @objc func cancelRecurrence() {
        selectRecurrence(.none)
        recurrenceField.resignFirstResponder()
    }

    // MARK: - UIPickerViewDataSource, UIPickerViewDelegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 10 // how many total recurrence dates?
    }

    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row < self.datesForPicker.count {
            return self.datesForPicker[row].dateStringForPicker()
        }
        return ""
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // let user pick more dates and click done
        print("Didselectrow")
    }
}

extension RecurrenceHelper {
    func datesForRecurrence(_ recurrence: Date.Recurrence, startDate: Date, endDate: Date) -> [Date] {
        guard recurrence != .none else {
            return [startDate]
        }
        guard endDate > startDate else {
            return []
        }
        var dates: [Date] = []
        var date: Date = startDate
        while date <= endDate {
            dates.append(date)
            let date2 = date.getNextRecurrence(recurrence: recurrence, from: date.addingTimeInterval(1))
            guard let nextDate = date2, nextDate != date else { break }
            date = nextDate
        }

        return dates
    }
}
