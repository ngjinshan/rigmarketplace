//
//  Item.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 23/04/2023.
//

import UIKit
import FirebaseFirestoreSwift

class Item: NSObject, Codable {
    @DocumentID var id: String?
    var name: String?
    var itemDescription: String?
    var picture: String?
    var price: Float?
    var category: Int?
    var user_seller: User?
    var user_buyer: User?
    var sold: Bool?
}
