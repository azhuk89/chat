//
//  ChatsTableViewController.swift
//  Chat
//
//  Created by Alexandr Zhuk on 5/3/16.
//  Copyright © 2016 Alexandr Zhuk. All rights reserved.
//

import UIKit

class ChatsTableViewController: UITableViewController {
    
    var backendless = Backendless.sharedInstance()
    
    var sendersArray = [String]()
    var recipientsArray = [String]()
    var namesArray = [String]()
    
    var messagesArray = [String]()
    var messageDatesArray = [NSDate]()
    var lastMessagesArray = [String]()
    
    var userImagesArray: [UIImage?]?
    
    var selectedIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        sendersArray.removeAll(keepCapacity: false)
        recipientsArray.removeAll(keepCapacity: false)
        namesArray.removeAll(keepCapacity: false)
        messagesArray.removeAll(keepCapacity: false)
        lastMessagesArray.removeAll(keepCapacity: false)
        userImagesArray?.removeAll(keepCapacity: false)
        
        let queryOptions = QueryOptions()
        queryOptions.sortBy = ["created DESC"]
        
        let query = BackendlessDataQuery()
        query.whereClause = "sender = '\(currentUserName)' OR recipient = '\(currentUserName)'"
        query.queryOptions = queryOptions
        
        backendless.persistenceService.of(ChatMessages.ofClass()).find(query, response: { (chatMessages: BackendlessCollection!) in
            let currentPage = chatMessages.getCurrentPage()
            
            for chatMessage in currentPage as! [ChatMessages] {
                self.sendersArray.append(chatMessage.sender!)
                self.recipientsArray.append(chatMessage.recipient!)
                self.messagesArray.append(chatMessage.message!)
                self.messageDatesArray.append(chatMessage.created!)
                
                print("message: \(chatMessage.message!)")
                print("created: \(chatMessage.created!)")
            }
            
            for i in 0..<self.sendersArray.count {
                if self.sendersArray[i] != currentUserName {
                    self.namesArray.append(self.sendersArray[i])
                } else {
                    self.namesArray.append(self.recipientsArray[i])
                }
            }
            
            self.namesArray = Array(Set(self.namesArray))
            self.userImagesArray = [UIImage?](count: self.namesArray.count, repeatedValue: nil)
           
            for name in self.namesArray {
                var lastMessageAsSender = ""
                var lastMessageAsRecipient = ""
                var senderMessageIndex = 0
                var recipientMessageIndex = 0
                for i in 0..<self.sendersArray.count {
                    if name == self.sendersArray[i] {
                        lastMessageAsSender = self.messagesArray[i]
                        senderMessageIndex = i
                        break
                    }
                }
                
                for i in 0..<self.recipientsArray.count {
                    if name == self.recipientsArray[i] {
                        lastMessageAsRecipient = self.messagesArray[i]
                        recipientMessageIndex = i
                        break
                    }
                }
                if !lastMessageAsSender.isEmpty && !lastMessageAsRecipient.isEmpty {
                    if self.messageDatesArray[senderMessageIndex].compare(self.messageDatesArray[recipientMessageIndex]) == NSComparisonResult.OrderedDescending {
                        self.lastMessagesArray.append(lastMessageAsSender)
                    } else {
                        self.lastMessagesArray.append(lastMessageAsRecipient)
                    }
                } else if !lastMessageAsSender.isEmpty && lastMessageAsRecipient.isEmpty {
                    self.lastMessagesArray.append(lastMessageAsSender)
                } else if lastMessageAsSender.isEmpty && !lastMessageAsRecipient.isEmpty {
                    self.lastMessagesArray.append(lastMessageAsRecipient)
                }
            }
            
            self.loadImages()
            
        }) { (fault: Fault!) in
            print("unable to get data from ChatMessages table: \(fault)")
        }
    }
    
    func loadImages() {
        for index in 0..<self.namesArray.count {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let urlString = kBackendlessApiURL + "/" + appDelegate.APP_ID + "/" + appDelegate.VERSION_NUM + "/files/profile/" + self.namesArray[index] + ".png"
            let url = NSURL(string: urlString)
            
            let request = NSURLRequest(URL: url!)
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
                guard error == nil else { return }
                guard data != nil else { return }
                
                let fileName = response?.suggestedFilename!
                let indexOfStr = fileName?.endIndex.advancedBy(-4)
                let userName = fileName?.substringToIndex(indexOfStr!)
                print("image has been downloaded for user: \(userName)")
                
                let nameIndex = self.namesArray.indexOf(userName!)
                self.userImagesArray![nameIndex!] = UIImage(data: data!)!
                    
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                })
            }
            task.resume()

        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return namesArray.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! ChatsTableViewCell
        cell.nameLabel.text = namesArray[indexPath.row]
        cell.messageLabel.text = lastMessagesArray[indexPath.row]
        cell.chatImageView.image = userImagesArray![indexPath.row] != nil ? userImagesArray![indexPath.row] : UIImage(named: "add")
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedIndex = indexPath.row
        self.performSegueWithIdentifier("ChatSegue2", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ChatSegue2" {
            let destinationVC = segue.destinationViewController as! ChatViewController
            destinationVC.recipientName = self.namesArray[selectedIndex]
        }
    }
}
