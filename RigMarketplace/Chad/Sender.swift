//
//  Sender.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 18/05/2023.
//

import UIKit
import MessageKit

class Sender: SenderType {
    var senderId: String
    var displayName: String
    
    init(id: String, name: String) {
        self.senderId = id
        self.displayName = name
    }
}
