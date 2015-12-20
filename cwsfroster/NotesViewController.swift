//
//  NotesViewController.swift
//  cwsfroster
//
//  Created by Bobby Ren on 12/19/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//

import UIKit

class NotesViewController: UIViewController {

    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var inputNotes: UITextView!
    
    @IBOutlet weak var constraintTopOffset: NSLayoutConstraint!
    @IBOutlet weak var constraintBottomOffset: NSLayoutConstraint!
    
    var practice: Practice?
    var member: Member?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.        
        
        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.Black
        keyboardDoneButtonView.tintColor = UIColor.whiteColor()
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Update", style: UIBarButtonItemStyle.Done, target: self, action: "dismissKeyboard")
        keyboardDoneButtonView.setItems([saveButton], animated: true)
        self.inputNotes.inputAccessoryView = keyboardDoneButtonView
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        if self.practice != nil {
            if self.practice!.title != nil {
                self.labelTitle.text = "Notes about \(self.practice!.title!)"
                if self.practice!.details != nil {
                    self.labelTitle.text = "Notes about \(self.practice!.title!) \(self.practice!.details!)"
                }
            }
            else if self.practice!.details != nil {
                self.labelTitle.text = "Notes about \(self.practice!.details!)"
            }
            else {
                self.labelTitle.text = "Notes about this event"
            }
            
            if self.practice!.notes != nil {
                self.inputNotes.text = self.practice!.notes
            }
            else {
                self.inputNotes.text = "Enter some notes here"
            }
        }
        else if self.member != nil {
            if self.member!.name != nil {
                self.labelTitle.text = "Notes about \(self.member!.name!)"
            }
            else {
                self.labelTitle.text = "Notes about this member"
            }

            if self.member!.notes != nil {
                self.inputNotes.text = self.member!.notes
            }
            else {
                self.inputNotes.text = "Enter some notes here"
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
        
        if self.practice != nil {
            self.practice!.notes = self.inputNotes.text
            self.practice!.saveOrUpdateToParseWithCompletion(nil)
            PFAnalytics.trackEvent("notes entered", dimensions: ["for": "practice"])
        }
        if self.member != nil {
            self.member!.notes = self.inputNotes.text
            self.member!.saveOrUpdateToParseWithCompletion(nil)
            PFAnalytics.trackEvent("notes entered", dimensions: ["for": "member"])
        }
        
    }
    
    // MARK: - keyboard notifications
    func keyboardWillShow(n: NSNotification) {
        let size = n.userInfo![UIKeyboardFrameBeginUserInfoKey]?.CGRectValue.size
        
        // these values come from the position/offsets of the current textfields
        // offsets bring the top of the email field to the top of the screen
        self.constraintBottomOffset.constant = size!.height
        self.constraintTopOffset.constant = -size!.height
        self.view.layoutIfNeeded()
    }
    
    func keyboardWillHide(n: NSNotification) {
        self.constraintBottomOffset.constant = 0 // by default, from iboutlet settings
        self.constraintTopOffset.constant = 0
        self.view.layoutIfNeeded()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
