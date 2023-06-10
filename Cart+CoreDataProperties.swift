//
//  Cart+CoreDataProperties.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 25/04/2023.
//
//

import Foundation
import CoreData


extension Cart {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Cart> {
        return NSFetchRequest<Cart>(entityName: "Cart")
    }

    @NSManaged public var itemID: String?
    @NSManaged public var itemName: String?
    @NSManaged public var itemPrice: Float
    @NSManaged public var itemPicture: String?

}

extension Cart : Identifiable {

}
