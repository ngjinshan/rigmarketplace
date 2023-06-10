//
//  Item.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 23/04/2023.
//

import UIKit
import FirebaseFirestoreSwift

class PostPart: NSObject, Codable {
    var id: UUID?
    var name: String?
    var price: Float?
    var picture: String?
    var category: Int?
    var postID: Int?
}
