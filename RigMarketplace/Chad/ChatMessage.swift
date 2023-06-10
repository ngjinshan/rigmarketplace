//
//  ChatMessage.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 18/05/2023.
//

import UIKit
import MessageKit

class ChatMessage: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    init(sender: SenderType, messageId: String, sentDate: Date, message: String) {
        self.sender = sender
        self.messageId = messageId
        self.sentDate = sentDate
        self.kind = .text(message)
    }
}
