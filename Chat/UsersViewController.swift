//
//  UsersViewController.swift
//  Chat
//
//  Created by Alexandr Zhuk on 4/18/16.
//  Copyright © 2016 Alexandr Zhuk. All rights reserved.
//

import UIKit

let kBackendlessApiURL = "https://api.backendless.com"

var currentUserName = ""

class UsersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var backendless = Backendless.sharedInstance()
    
    var userEmailsArray = [String]()
    var userNamesArray = [String]()
    var imageFilesArray = [String]()
    var userDevicesArray = [String]()
    
    var recipientUserName = ""
    var recipientUserEmail = ""
    var recipientUserDeviceId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.tableHeaderView?.frame = CGRectZero
        
        currentUserName = backendless.userService.currentUser.name
        let dataStore = backendless.persistenceService.of(BackendlessUser.ofClass())
        
        dataStore.find({ (users: BackendlessCollection!) in
            print("users list was obtained")
            
            let currentPage = users.getCurrentPage()
            
            for user in currentPage as! [BackendlessUser] {
                if user.name != currentUserName {
                    self.userEmailsArray.append(user.email)
                    self.userNamesArray.append(user.name)
                    self.imageFilesArray.append("profile/" + user.name + ".png")
                    
                    if let deviceId = user.getProperty("deviceId") as? String {
                        self.userDevicesArray.append(deviceId)
                    } else {
                        self.userDevicesArray.append("")
                    }
                }
            }
            self.tableView.reloadData()
            
        }) { (fault: Fault!) in
            print("unable to get users list: \(fault)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //self.navigationItem.hidesBackButton = true
    }
    
    func downloadImageForTableView(url: NSURL, indexPath: NSIndexPath, cell: UserTableViewCell) {
        let request = NSURLRequest(URL: url)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
            guard error == nil else { return }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let image = UIImage(data: data!)!
                cell.profileImageView.image = image
                self.tableView.reloadData()
            })
        }
        task.resume()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userEmailsArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! UserTableViewCell
        
        cell.emailLabel.text = userEmailsArray[indexPath.row]
        cell.nameLabel.text = userNamesArray[indexPath.row]
        //cell.profileImageView.image = UIImage(named: "add")
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let urlString = kBackendlessApiURL + "/" + appDelegate.APP_ID + "/" + appDelegate.VERSION_NUM + "/files/" + imageFilesArray[indexPath.row]
        let url = NSURL(string: urlString)
        self.downloadImageForTableView(url!, indexPath: indexPath, cell: cell)
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! UserTableViewCell
        
        self.recipientUserName = cell.nameLabel.text!
        self.recipientUserEmail = cell.emailLabel.text!
        self.recipientUserDeviceId = self.userDevicesArray[indexPath.row]
        
        self.performSegueWithIdentifier("ChatSegue", sender: self)
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ChatSegue" {
            let destinationVC = segue.destinationViewController as! ChatViewController
            destinationVC.recipientName = self.recipientUserName
            destinationVC.recipientEmail = self.recipientUserEmail
            destinationVC.recipientDeviceId = self.recipientUserDeviceId
        }
    }
    
    @IBAction func exitBarButtonPressed(sender: AnyObject) {
        backendless.userService.logout()
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
}
