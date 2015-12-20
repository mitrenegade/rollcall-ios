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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
        
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
