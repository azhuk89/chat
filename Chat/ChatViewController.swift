//
//  ChatViewController.swift
//  Chat
//
//  Created by Alexandr Zhuk on 4/19/16.
//  Copyright © 2016 Alexandr Zhuk. All rights reserved.
//

import UIKit

func getKeyboardSize(notification: NSNotification) -> CGRect {
    let dict: NSDictionary = notification.userInfo!
    let keyboardSizeValue: NSValue = dict.valueForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
    let keyboardSize: CGRect = keyboardSizeValue.CGRectValue()
    return keyboardSize
}

class ChatViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var chatScrollView: UIScrollView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var promtLabel: UILabel!
    @IBOutlet weak var chatActionView: UIView!
    @IBOutlet weak var blockUnblockBarButtonItem: UIBarButtonItem!

    var backendless = Backendless.sharedInstance()
    
    var recipientName = ""
    var recipientEmail = ""
    var recipientDeviceId = ""
    
    var currentUserImage: UIImage?
    var recipientUserImage: UIImage?
    
    var messagesArray = [String]()
    var sendersArray = [String]()
    
    var isBlocked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        messageTextView.addSubview(promtLabel)
        self.title = recipientName
        
        self.downloadChatImages()
        self.updateBlockInfo()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.keyboardDidShow), name:UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.keyboardWillHide), name: UIKeyboardDidHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.updateChat), name: "chatWillUpdate", object: nil)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.didTapScrollView))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.chatScrollView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        checkIfCurrentUserBlocked()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textViewDidChange(textView: UITextView) {
        self.promtLabel.hidden = messageTextView.hasText()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if !messageTextView.hasText() {
            self.promtLabel.hidden = false
        }
    }
    
    func didTapScrollView() {
        self.view.endEditing(true)
    }
    
    func keyboardDidShow(notification: NSNotification) {
        let keyboardSize = getKeyboardSize(notification)
        
        UIView.animateWithDuration(0.3, animations: { 
            self.chatScrollView.frame.size.height -= keyboardSize.height
            self.chatActionView.frame.origin.y -= keyboardSize.height
            
            let scrollOffset: CGPoint = CGPointMake(0, self.chatScrollView.contentSize.height - self.chatScrollView.frame.size.height)
            self.chatScrollView.setContentOffset(scrollOffset, animated: true)
            
        }) { (finished: Bool) in
            
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let keyboardSize = getKeyboardSize(notification)
        
        UIView.animateWithDuration(0.3, animations: {
            self.chatScrollView.frame.size.height += keyboardSize.height
            self.chatActionView.frame.origin.y += keyboardSize.height
            
        }) { (finished: Bool) in
            
        }
    }
    
    func downloadChatImages() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let urlString = kBackendlessApiURL + "/" + appDelegate.APP_ID + "/" + appDelegate.VERSION_NUM + "/files/profile/" + currentUserName + ".png"
        let url = NSURL(string: urlString)
        
        let request = NSURLRequest(URL: url!)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
            if error != nil { print("error: \(error?.localizedDescription)") }
            if data == nil { print("no data") }
            guard error == nil else { return }
            guard data != nil else { return }
            self.currentUserImage = UIImage(data: data!)!
            print("user image has been downloaded")
            
            let urlStringRecipient = kBackendlessApiURL + "/" + appDelegate.APP_ID + "/" + appDelegate.VERSION_NUM + "/files/profile/" + self.recipientName + ".png"
            let urlRecipient = NSURL(string: urlStringRecipient)
            let requestRecipient = NSURLRequest(URL: urlRecipient!)
            
            let taskRecipient = NSURLSession.sharedSession().dataTaskWithRequest(requestRecipient) { (data: NSData?, response: NSURLResponse?, error: NSError?) in
                guard data != nil else { return }
                self.recipientUserImage = UIImage(data: data!)!
                print("recipient image has been downloaded")
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.updateChat()
                })
            }
            taskRecipient.resume()
        }
        task.resume()
    }
    
    func updateChat() {
        var marginY: (CGFloat, CGFloat, CGFloat) = (messageMarginY: 27, bubbleMarginY: 20, imageMarginY: 5)
        
        messagesArray.removeAll(keepCapacity: false)
        sendersArray.removeAll(keepCapacity: false)
        
        let queryOptions = QueryOptions()
        queryOptions.sortBy = ["created ASC"]
        
        let query = BackendlessDataQuery()
        query.whereClause = "(sender = '\(currentUserName)' AND recipient = '\(recipientName)') OR (sender = '\(recipientName)' AND recipient = '\(currentUserName)')"
        query.queryOptions = queryOptions
        
        backendless.persistenceService.of(ChatMessages.ofClass()).find(query, response: { (chatMessages: BackendlessCollection!) in
            let currentPage = chatMessages.getCurrentPage()
            
            for chatMessage in currentPage as! [ChatMessages] {
                self.messagesArray.append(chatMessage.message!)
                self.sendersArray.append(chatMessage.sender!)
                marginY = self.createMessageWidget((chatMessage.sender == currentUserName), chatMessage: chatMessage, marginY: marginY)
                
                print("---------------")
                print("sender: \(chatMessage.sender!)")
                print("recipient: \(chatMessage.recipient!)")
                print("message: \(chatMessage.message!)")
                print("created: \(chatMessage.created!)")
            }
        }) { (fault: Fault!) in
            print("unable to get data from ChatMessages table: \(fault)")
        }
    }
    
    func updateBlockInfo() {
        let query = BackendlessDataQuery()
        query.whereClause = "user = '\(currentUserName)' AND blockedUser = '\(recipientName)'"
        
        backendless.persistenceService.of(Block.ofClass()).find(query, response: { (blocks: BackendlessCollection!) in
            let blocksArray = blocks.getCurrentPage() as! [Block]
            self.blockUnblockBarButtonItem.title = !blocksArray.isEmpty ? "Unblock" : "Block"
            
        }) { (fault: Fault!) in
            print("unable to get data from Block table: \(fault)")
        }
    }
    
    func checkIfCurrentUserBlocked() {
        let query = BackendlessDataQuery()
        query.whereClause = "user = '\(recipientName)' AND blockedUser = '\(currentUserName)'"
        
        backendless.persistenceService.of(Block.ofClass()).find(query, response: { (blocks: BackendlessCollection!) in
            let blocksArray = blocks.getCurrentPage() as! [Block]
            if blocksArray.count > 0 {
                self.isBlocked = true
                print("you are blocked")
            }
            
        }) { (fault: Fault!) in
            print("unable to get data from Block table: \(fault)")
        }
    }
    
    func createMessageWidget(fromUser: Bool, chatMessage: ChatMessages, marginY: (CGFloat, CGFloat, CGFloat)) -> (CGFloat, CGFloat, CGFloat) {
        let kMessageMarginX: CGFloat = 45
        let kBubbleMarginX: CGFloat = 40
        let kImageMarginX: CGFloat = 15
        
        let messageLabel = UILabel()
        messageLabel.text = chatMessage.message!
        messageLabel.frame = CGRectMake(0, 0, self.chatScrollView.frame.size.width - 90, CGFloat.max)
        messageLabel.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .ByWordWrapping
        messageLabel.sizeToFit()
        
        messageLabel.textAlignment = .Left
        messageLabel.font = UIFont(name: "MarkerFelt-Thin", size: 16)
        messageLabel.textColor = UIColor.darkTextColor()
        messageLabel.backgroundColor = UIColor.clearColor()
        
        messageLabel.frame.origin.x = fromUser ? self.chatScrollView.frame.width - messageLabel.frame.size.width - kMessageMarginX : kMessageMarginX
        messageLabel.frame.origin.y = marginY.0
        let newMessageMarginY = marginY.0 + messageLabel.frame.size.height + 30
        self.chatScrollView.addSubview(messageLabel)
        
        let bubbleLabel = UILabel()
        bubbleLabel.frame.size = CGSizeMake(messageLabel.frame.width + 10, messageLabel.frame.height + 10)
        bubbleLabel.frame.origin.x = fromUser ? self.chatScrollView.frame.width - bubbleLabel.frame.size.width - kBubbleMarginX : kBubbleMarginX
        bubbleLabel.frame.origin.y = marginY.1
        
        bubbleLabel.layer.cornerRadius = 10
        bubbleLabel.clipsToBounds = true
        bubbleLabel.backgroundColor = UIColor.greenColor()
        
        let newBubbleMarginY = marginY.1 + bubbleLabel.frame.size.height + 20
        self.chatScrollView.addSubview(bubbleLabel)
        
        let frameWidth = self.view.frame.size.width
        self.chatScrollView.contentSize = CGSizeMake(frameWidth, newMessageMarginY)
        self.chatScrollView.bringSubviewToFront(messageLabel)
        
        let senderImageView = UIImageView()
        senderImageView.image = fromUser ? currentUserImage : recipientUserImage
        senderImageView.frame.size = CGSizeMake(35, 35)
        senderImageView.frame.origin = CGPointMake(fromUser ? self.chatScrollView.frame.width - senderImageView.frame.size.width - kImageMarginX : kImageMarginX, marginY.2)
        senderImageView.layer.cornerRadius = senderImageView.frame.size.width / 2
        senderImageView.clipsToBounds = true
        
        let newImageMarginY = marginY.2 + bubbleLabel.frame.size.height + 20
        self.chatScrollView.addSubview(senderImageView)
        self.chatScrollView.bringSubviewToFront(senderImageView)
        
        let scrollOffset: CGPoint = CGPointMake(0, self.chatScrollView.contentSize.height - self.chatScrollView.frame.size.height)
        self.chatScrollView.setContentOffset(scrollOffset, animated: true)
        
        return (newMessageMarginY, newBubbleMarginY, newImageMarginY)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func goButtonPressed(sender: AnyObject) {
        if isBlocked {
            let alert = UIAlertController(title: "You are blocked", message: "\(recipientName) blocked you", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
            alert.addAction(okAction)
            presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        didTapScrollView()
        if messageTextView.text.isEmpty { return }
        
        let message = ChatMessages()
        message.message = messageTextView.text
        message.sender = currentUserName
        message.recipient = recipientName
        
        backendless.persistenceService.of(ChatMessages.ofClass()).save(message, response: { (result: AnyObject!) in
            let savedObject = result as! ChatMessages
            print("message has been saved: \(savedObject)")
            
            let publishOptions = PublishOptions()
            publishOptions.headers = ["ios-alert":"Chat: New message!"]
            
            let deliveryOptions = DeliveryOptions()
            deliveryOptions.pushSinglecast = [self.recipientDeviceId]
            
            self.backendless.messaging.publish("default", message: self.messageTextView.text, publishOptions: publishOptions, deliveryOptions: deliveryOptions, response: { (status: MessageStatus!) in
                print("the push notification was published succesfully: \(status)")
            }, error: { (fault: Fault!) in
                print("unable to send publish notification: \(fault)")
            })
            
            self.messageTextView.text = ""
            self.promtLabel.hidden = false
            self.updateChat()
            
        }) { (fault: Fault!) in
            print("unable to save message: \(fault)")
        }
    }
    
    @IBAction func blockUnblockButtonPressed(sender: AnyObject) {
        if self.blockUnblockBarButtonItem.title == "Block" {
            self.blockUnblockBarButtonItem.title = "Unblock"
            
            let block = Block()
            block.user = currentUserName
            block.blockedUser = recipientName
            
            self.backendless.persistenceService.save(block, response: { (savedBlock: AnyObject!) in
                print("block has been saved: \(savedBlock)")
            }, error: { (fault: Fault!) in
                print("unable to save block: \(fault)")
            })
        } else {
            self.blockUnblockBarButtonItem.title = "Block"
            
            let query = BackendlessDataQuery()
            query.whereClause = "user = '\(currentUserName)' AND blockedUser = '\(recipientName)'"
            
            backendless.persistenceService.of(Block.ofClass()).find(query, response: { (blocks: BackendlessCollection!) in
                let blocksArray = blocks.getCurrentPage() as! [Block]
                if !blocksArray.isEmpty {
                    let removeBlock = blocksArray.first
                    
                    self.backendless.persistenceService.remove(removeBlock, response: { (count: NSNumber!) in
                        print("the block was removed succesfully: \(removeBlock), current count - \(count)")
                    }, error: { (fault: Fault!) in
                        print("unable to delete the block: \(fault)")
                    })
                }
                
            }) { (fault: Fault!) in
                print("unable to get data from Block table: \(fault)")
            }
        }
    }
    
}
