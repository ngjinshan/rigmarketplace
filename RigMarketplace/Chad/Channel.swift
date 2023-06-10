//
//  Channel.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 18/05/2023.
//

import UIKit

class Channel: NSObject {
    let id: String
    let name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
