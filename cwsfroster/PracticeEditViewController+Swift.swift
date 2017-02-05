//
//  PracticeEditViewController+Swift.swift
//  rollcall
//
//  Created by Bobby Ren on 2/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import Parse
import UIKit

extension PracticeEditViewController {
 
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.practice == nil {
            constraintButtonAttendeesHeight.constant = 0
        }
    }
    
    func setupTextView() {
        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Update", style: UIBarButtonItemStyle.done, target: self, action: #selector(NotesViewController.dismissKeyboard))
        keyboardDoneButtonView.setItems([saveButton], animated: true)
        self.inputNotes.inputAccessoryView = keyboardDoneButtonView
    }
    
    func configureForPractice() {
        if let practice = self.practice {
            self.title = "Edit event"
            self.inputDate.text = practice.title
            self.inputDetails.text = practice.details
            self.inputNotes.text = practice.notes
        }
        else {
            self.title = "New event";
            self.inputDate.text = self.title(for: Date())
            self.viewEmail.isHidden = true
            self.buttonDrawing.isHidden = true
            self.inputNotes.text = nil
        }
        originalDescription = inputDetails.text;

    }
}
