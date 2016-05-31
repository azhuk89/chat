//
//  LoginViewController.swift
//  Chat
//
//  Created by Alexandr Zhuk on 4/12/16.
//  Copyright © 2016 Alexandr Zhuk. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.didTapView))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didTapView() {
        self.view.endEditing(true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func loginButtonPressed(sender: AnyObject) {
        let backendless = Backendless.sharedInstance()
        
        backendless.userService.login(nameTextField.text!, password: passwordTextField.text!, response: { (user: BackendlessUser!) in
            print("user has been logged in: \(user)")
            
            if let deviceId = user.getProperty("deviceId") as? String {
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                if appDelegate.deviceId != nil && deviceId != appDelegate.deviceId {
                    user.updateProperties(["deviceId" : appDelegate.deviceId!])
                    backendless.userService.update(user, response: { (updatedUser: BackendlessUser!) in
                        print("user has been updated: \(updatedUser)")
                    }, error: { (fault: Fault!) in
                        print("unable to update current user due to error: \(fault)")
                    })
                }
            }
            
            self.performSegueWithIdentifier("ToUsersSegue1", sender: self)
        }) { (fault: Fault!) in
            print("unable to lo log in due to error: \(fault)")
        }
    }
    
    @IBAction func createAccountButtonPressed(sender: AnyObject) {
        
    }
}
