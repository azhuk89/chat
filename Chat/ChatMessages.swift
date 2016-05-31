//
//  ChatMessages.swift
//  Chat
//
//  Created by Alexandr Zhuk on 4/20/16.
//  Copyright © 2016 Alexandr Zhuk. All rights reserved.
//

import Foundation

class ChatMessages : NSObject {
    var objectId: String?
    var ownerId: String?
    var created: NSDate?
    var updated: NSDate?
    
    var sender: String?
    var recipient: String?
    var message: String?
}