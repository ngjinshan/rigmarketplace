//
//  Item.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 23/04/2023.
//

import UIKit
import FirebaseFirestoreSwift

class Wishlist: NSObject, Codable {
    @DocumentID var id: String?
    var user: User?
    var items: [Item] = []
}
