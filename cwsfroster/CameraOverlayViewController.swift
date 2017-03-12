//
//  CameraOverlayViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 3/12/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit


@objc protocol CameraControlsDelegate: class {
    func didTakePhoto(image: UIImage)
    func dismissCamera()
}
class CameraOverlayViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet var button: UIButton!
    weak var delegate: CameraControlsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func takePhoto(from controller: UIViewController) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera // use rear camera because the organizer is taking photos
        }
        else if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            picker.sourceType = .photoLibrary
        }
        else {
            picker.sourceType = .savedPhotosAlbum
        }
        
        // HACK: this controller is only used for the view and to handle photo library
        // the photo library button does not appear exactly where you want, but always seems to be in the top right corner
        controller.present(picker, animated: true, completion: nil)
        
        // add overlayview
//        let customView:CameraControlsOverlayView = self.view as! CameraControlsOverlayView
//        customView.frame = picker.view.frame
        
        picker.cameraOverlayView = self.view
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let img = info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]
        guard let photo = img as? UIImage else { return }
        delegate?.didTakePhoto(image: photo)
        
        // TODO: edit photo does not click through; library button still exists when editing
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.dismissCamera()
    }
    
    @IBAction func didClickButton(_ sender: AnyObject?) {
        print("button")
    }
}
