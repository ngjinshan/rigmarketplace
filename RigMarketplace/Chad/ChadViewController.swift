//
//  ChadViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 18/05/2023.
//

import MessageKit
import InputBarAccessoryView
import Foundation
import UIKit

/**
 using messagekit and tutorial from week 8
 */
class ChadViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, InputBarAccessoryViewDelegate {

    var sender: Sender = Sender(id: "Me", name: "Me")
    var messagesList = [ChatMessage]()
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm dd/MM/yy"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        scrollsToLastItemOnKeyboardBeginsEditing = true
        maintainPositionOnInputBarHeightChanged = true
    }
    
    func sendMessage(message: ChatMessage) async {
        
        self.setTypingIndicatorViewHidden(false, animated: true)
        //get reply from chad
        var query = ""
        switch message.kind {
        case .text(let messageText):
            query = messageText
        default:
            break
        }
        
        //call api
        let apiResponse = await chatGPT(query: query)
        
        //add reply message to the message list
        let sentDate = Date.init()
        let sender = Sender(id: "Chad", name: "Chad")
        let reply = ChatMessage(sender: sender, messageId: "", sentDate: sentDate, message: apiResponse)
        self.messagesList.append(reply)
        self.messagesCollectionView.insertSections([self.messagesList.count - 1])
        self.messagesCollectionView.scrollToLastItem()
        self.setTypingIndicatorViewHidden(true, animated: true)
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messagesList[indexPath.section]
    }
    
    var currentSender: SenderType {
        return Sender(id: "Me", name: "Me")
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messagesList.count
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        if text.isEmpty {
            return
        }
        
        let sentDate = Date.init()
        let sender = Sender(id: "Me", name: "Me")
        let message = ChatMessage(sender: sender, messageId: "", sentDate: sentDate, message: text)
        self.messagesList.append(message)
        self.messagesCollectionView.insertSections([self.messagesList.count - 1])
        
        //disable messaging while waiting for reply
        inputBar.inputTextView.isEditable = false
        inputBar.sendButton.isEnabled = false
        
        Task {
            await sendMessage(message: message)
                
            //enable messaging after getting reply from API
            DispatchQueue.main.async {
                inputBar.inputTextView.isEditable = true
                inputBar.sendButton.isEnabled = true
            }
        }
        
        //clear input bar
        inputBar.inputTextView.text = ""
    }
    
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 18
    }
    
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 17
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        
        return .bubbleTail(tail, .curved)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
