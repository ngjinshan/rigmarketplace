//
//  DatabaseController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 23/04/2023.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import FirebaseStorage
import UIKit

enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case items
    case posts
    case parts
    case wishlist
    case cart
    case all
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    func onItemsChange(change: DatabaseChange, items: [Item])
    func onPostsChange(change: DatabaseChange, posts: [Post])
//    func onPartsChange(change: DatabaseChange, parts: [PostPart])
    func onWishlistChange(change: DatabaseChange, wishlist: [Item])
}

protocol DatabaseProtocol: AnyObject {
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    
    func addItem(name: String, itemDescription: String, picture: String, price: Float, category: Int?, sold: Bool) -> Item
    func removeItem(item: Item)
    func updateItem(item: Item)
    func getItemById(_ id: String) -> Item?
    func getItemImage(item: Item, imageView: UIImageView) -> StorageDownloadTask?
    func updateItemImage(item: Item, image: UIImage?) -> StorageUploadTask?

    func addPost(postDescription: String, picture: String, parts: [PostPart]) -> Post
    func removePost(post: Post)
    func updatePost(post: Post)
    func getPostById(_ id: String) -> Post?
    func getPostImage(post: Post, imageView: UIImageView) -> StorageDownloadTask?
    func updatePostImage(post: Post, image: UIImage?) -> StorageUploadTask?
    func getPostPrice(_ id: String) -> Float
    
    func getPartImage(part: PostPart, imageView: UIImageView) -> StorageDownloadTask?
    func updatePartImage(part: PostPart, image: UIImage?) -> StorageUploadTask?
    
    func addWishlist() -> Wishlist
    func removeWishlist(wishlist: Wishlist)
    func getWishlist() -> Wishlist
    func setupWishlistListener()
    func addItemToWishlist(wishlist: Wishlist, item: Item)
    func removeItemFromWishlist(wishlist: Wishlist, item: Item)
    
    func removeImage(path: String)
    
    func signIn(_ email: String, _ password: String) async
    func signInAnnonymously() async
    func signOut() async
    
    var postParts: [PostPart] {get set}
    
    var authController: Auth {get set}
    var currentUser: FirebaseAuth.User? {get set}
    var storage: Storage? {get set}
    var imageCache: [String: UIImage] {get set}
}

protocol CDatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    func onCartChange(change: DatabaseChange, cart: [Cart])
}

protocol CDatabaseProtocol: AnyObject {
    func cleanup()
    func addListener(listener: CDatabaseListener)
    func removeListener(listener: CDatabaseListener)
    
    func addItemToCart(item: Item) -> Cart
    func deleteItemFromCart(cart: Cart)
}

