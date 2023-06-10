//
//  Item.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 23/04/2023.
//

import UIKit
import FirebaseFirestoreSwift

class Post: NSObject, Codable {
    @DocumentID var id: String?
    var postDescription: String?
    var picture: String?
    var user: User?
    var parts: [PostPart]?
}
