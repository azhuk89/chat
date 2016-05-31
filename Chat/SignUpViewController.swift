//
//  SignUpViewController.swift
//  Chat
//
//  Created by Alexandr Zhuk on 4/12/16.
//  Copyright © 2016 Alexandr Zhuk. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        let viewHeight = self.view.bounds.size.height
        let viewWidth = self.view.bounds.size.width
        
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveLinear, animations: {
            let yOffset: CGFloat = UIScreen.mainScreen().bounds.size.height > 568 ? 40 : 140
            self.view.center = CGPointMake(viewWidth / 2, viewHeight / 2 - yOffset)
        }) { (Bool) in }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        let viewHeight = self.view.bounds.size.height
        let viewWidth = self.view.bounds.size.width
        
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveLinear, animations: {
            self.view.center = CGPointMake(viewWidth / 2, viewHeight / 2)
        }) { (Bool) in }
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        nameTextField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func signUpButtonPressed(sender: AnyObject) {
        let backendless = Backendless.sharedInstance()
        
        let user: BackendlessUser = BackendlessUser()
        user.email = emailTextField.text
        user.password = passwordTextField.text
        user.name = nameTextField.text
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if appDelegate.deviceId != nil {
            user.setProperty("deviceId", object: appDelegate.deviceId)
        }
        
        backendless.userService.registering(user,
            response: { (user: BackendlessUser!) in
                print("user has been registered")
            },
            error: { (fault: Fault!) in
                print("unable to register the user due to error: \(fault)")
            }
        )
        
        let imageData = UIImagePNGRepresentation(profileImageView.image!)
        backendless.fileService.saveFile("profile/\(nameTextField.text!).png", content: imageData, response: { (file: BackendlessFile!) in
            print("File has been uploaded: \(file.fileURL)")
            backendless.userService.login(self.emailTextField.text!, password: self.passwordTextField.text!, response: { (user: BackendlessUser!) in
                print("user has been logged in: \(user)")
                self.performSegueWithIdentifier("ToUsersSegue2", sender: self)
            }) { (fault: Fault!) in
                print("unable to lo log in due to error: \(fault)")
            }
        }) { (fault: Fault!) in
            print("unable to upload the file due to error: \(fault)")
        }
    }
    
    @IBAction func addImageButtonPressed(sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.allowsEditing = true
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        profileImageView.image = image
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}
