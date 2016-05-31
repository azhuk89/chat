//
//  Block.swift
//  Chat
//
//  Created by Alexandr Zhuk on 5/2/16.
//  Copyright © 2016 Alexandr Zhuk. All rights reserved.
//

import Foundation

class Block : NSObject {
    var objectId: String?
    var ownerId: String?
    var created: NSDate?
    var updated: NSDate?
    
    var user: String?
    var blockedUser: String?
}