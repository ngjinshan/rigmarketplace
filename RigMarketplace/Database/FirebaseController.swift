//
//  FirebaseController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 23/04/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import FirebaseStorage
import UserNotifications
import SwiftUI

class FirebaseController: NSObject, DatabaseProtocol {
    
    var listeners = MulticastDelegate<DatabaseListener>()
    var items: [Item] //items from database
    var posts: [Post] //posts from database
    var postParts: [PostPart] //local cache of post parts
    var wishlist: Wishlist //wishlist from database
    var authController: Auth //auth
    var database: Firestore
    var itemsRef: CollectionReference?
    var postsRef: CollectionReference?
    var partsRef: CollectionReference?
    var wishlistRef: CollectionReference?
    //listener active trackers to prevent listening more than once
    var itemsSnapshotListener: ListenerRegistration?
    var postsSnapshotListener: ListenerRegistration?
    var wishlistSnapshotListener: ListenerRegistration?
    
    var currentUser: FirebaseAuth.User? //current user
    var storage: Storage? //firestore storage
    var imageCache: [String : UIImage] //image cache dictionary
    
    override init() {
        //setup and initialization
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
        storage = Storage.storage()
        items = [Item]()
        posts = [Post]()
        postParts = [PostPart]()
        imageCache = [String: UIImage]()
        wishlist = Wishlist()
        
        super.init()
        
        Task {
            if let email = UserDefaults.standard.string(forKey: "email"), let password = UserDefaults.standard.string(forKey: "password") {
                await self.signIn(email, password)
            } else {
                await self.signInAnnonymously()
            }
//            await self.signInAnnonymously()
            
            //setup listeners
            if(currentUser?.uid != nil) {
                setupItemListener()
                setupPostListener()
            }
            
            if(currentUser?.isAnonymous == false) {
                setupWishlistListener()
            }
        }
    }
    
    func signIn(_ email: String, _ password: String) async {
        do {
            let authResult = try await authController.signIn(withEmail: email, password: password)
            currentUser = authResult.user
            
        } catch {
            print("error signing in: \(error)")
            //if fail at start up then sign in annonymously
            await self.signInAnnonymously()
        }
    }
    
    func signInAnnonymously() async {
        do {
            let authResult = try await authController.signInAnonymously()
            currentUser = authResult.user

        } catch {
            fatalError("error signing in: \(error)")
        }
    }
    
    func signOut() async {
        do {
            try authController.signOut()
            
            UserDefaults.standard.removeObject(forKey: "email")
            UserDefaults.standard.removeObject(forKey: "password")
            
            await self.signInAnnonymously()
        } catch {
            fatalError("Error signing out: \(error)")
        }
    }
    
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        
        if listener.listenerType == .items || listener.listenerType == .all{
            listener.onItemsChange(change: .update, items: items)
        }
        
        if listener.listenerType == .posts || listener.listenerType == .all{
            listener.onPostsChange(change: .update, posts: posts)
        }
        
        if listener.listenerType == .wishlist || listener.listenerType == .all{
            listener.onWishlistChange(change: .update, wishlist: wishlist.items)
        }
    }
    
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    func removeSnapshotListeners() {
        //remove listeners
        if let itemsSnapshotListener = itemsSnapshotListener {
            itemsSnapshotListener.remove()
            self.itemsSnapshotListener = nil
        }
        
        if let postsSnapshotListener = postsSnapshotListener {
            postsSnapshotListener.remove()
            self.postsSnapshotListener = nil
        }
        
        if let wishlistSnapshotListener = wishlistSnapshotListener {
            wishlistSnapshotListener.remove()
            self.wishlistSnapshotListener = nil
        }
    }
    
    /**
     function to add item to database
     @params:
     name: item name
     itemDescription: item description
     picture: item picture string
     price: item price
     category: item category
     @return
     Item: item object created
     */
    func addItem(name: String, itemDescription: String, picture: String, price: Float, category: Int?, sold: Bool) -> Item {
        //create user
        let user = User()
        user.email = currentUser?.email
        user.uid = currentUser?.uid
        
        //create item
        let item = Item()
        item.name = name
        item.itemDescription = itemDescription
        item.picture = picture

        item.price = price
        item.category = category
        item.user_seller = user
        item.sold = sold
        
        do {
            //add item
            if let itemRef = try itemsRef?.addDocument(from: item) {
                item.id = itemRef.documentID
            }
        } catch {
            print("Failed to serialize item")
        }
        return item
    }
    
    /**
     function to remove item from database
     @params:
     item: Item to be removed
     */
    func removeItem(item: Item) {
        //delete from reference
        if let itemID = item.id {
            itemsRef?.document(itemID).delete()
        }
    }
    
    /**
     function to update item
     @params:
     item: Item to be updated
     */
    func updateItem(item: Item) {
        //update item
        if let itemID = item.id {
            do {
                try itemsRef?.document(itemID).setData(from: item)
            } catch {
                print("error updating \(error)")
            }
        }
    }
    
    /**
     function to get item by id
     @params:
     id: id of item
     @return:
     Item: Item object returned (optional)
     */
    func getItemById(_ id:String) -> Item? {
        for item in items {
            if item.id == id {
                return item
            }
        }
        
        return nil
    }
    
    /**
     function to get item image and set imageview's image to the retrieved image
     @params:
     item: Item whose image is to be found
     imageView: imageView to be set
     @return
     StorageDownloadTask: download task to observe
     */
    func getItemImage(item: Item, imageView: UIImageView) -> StorageDownloadTask? {
        var downloadTask: StorageDownloadTask?
        
        //if item has picture
        if item.picture?.isEmpty == false {
            //get file path
            let filepath = "\(item.id!)/itemPhoto"
            
            //if imageCache has the filepath, then just update
            if imageCache[filepath] != nil {
                imageView.image = imageCache[filepath]
            } else {
                //download image
                downloadTask = storage?.reference().child(filepath).getData(maxSize: 10000*1024*1024) { data, error in
                    
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    
                    if let data = data {
                        //set imageView's image
                        imageView.image = UIImage(data: data)
                        //add to imageCache
                        self.imageCache[filepath] = UIImage(data: data)
                    }
                    
                }
            }
        }
        
        return downloadTask
    }
    
    /**
     function to update item's image
     @params:
     item: Item to be updated
     image: new image
     @return:
     StorageUploadTask: upload task to be observed
     */
    func updateItemImage(item: Item, image: UIImage?) -> StorageUploadTask? {
        if let image {
            if let itemID = item.id {
                //set picture to exists (arbitrary string)
                itemsRef?.document(itemID).updateData(["picture": "exists"])
                
                //get storage reference, upload data, filepath and metadata
                let storageRef = storage!.reference()
                let uploadData = image.pngData()! as Data
                let filePath = "\(itemID)/\("itemPhoto")"
                let metaData = StorageMetadata()
                metaData.contentType = "image/jpg"
                
                //upload image
                let uploadTask = storageRef.child(filePath).putData(uploadData, metadata: metaData){(metaData, error) in
                    if let error = error {
                        print("error uploading photo: \(error.localizedDescription)")
                        return
                    }
                    
                    //add to imagecache
                    self.imageCache[filePath] = image
                }
                
                return uploadTask
            }
        }
        return nil
    }
    
    //set up item listener
    func setupItemListener() {
        itemsRef = database.collection("items")
        itemsSnapshotListener = itemsRef?.addSnapshotListener() {
            (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                print("failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            self.parseItemsSnapshot(snapshot: querySnapshot)
        }
    }
    
    //set up item snapshot
    func parseItemsSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach{ (change) in
            var parsedItem: Item?
            
            do {
                parsedItem = try change.document.data(as: Item.self)
            } catch {
                print("unable to decode item")
                return
            }
            
            guard let item = parsedItem else {
                print("document doesnt exist")
                return
            }
            
            if change.type == .added {
                items.insert(item, at: Int(change.newIndex))
            } else if change.type == .removed {
                items.remove(at: Int(change.oldIndex))
                //update wishlist
                self.removeItemFromWishlist(wishlist: wishlist, item: parsedItem!)
                
            } else if change.type == .modified {
                items.remove(at: Int(change.oldIndex))
                items.insert(item, at: Int(change.newIndex))
                
                //local notification for when items are sold
                if(item.user_seller?.uid == currentUser?.uid && item.sold == true) {
                    let notificationContent = UNMutableNotificationContent()
                    notificationContent.title = "Item sold!"
                    notificationContent.body = "Item: \(item.name!)"
                    let timeInterval = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: "SOLD", content: notificationContent, trigger: timeInterval)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
            }
        }
        
        listeners.invoke{ (listener) in
            if listener.listenerType == ListenerType.items || listener.listenerType == .all {
                listener.onItemsChange(change: .update, items: items)
            }
        }
    }
    
    /**
     function to add post
     @params:
     postDescription: post description
     picture: post picture
     parts: post parts
     @return
     Post: post object created
     */
    func addPost(postDescription: String, picture: String, parts: [PostPart]) -> Post {
        //create user
        let user = User()
        user.email = currentUser?.email
        user.uid = currentUser?.uid
        
        //create post
        let post = Post()
        post.postDescription = postDescription
        post.picture = picture
        
        post.user = user
        post.parts = parts
        
        do {
            //add post
            if let postRef = try postsRef?.addDocument(from: post) {
                post.id = postRef.documentID
            }
        } catch {
            print("Failed to serialize post")
        }
        return post
    }
    
    /**
     function to remove post
     @params:
     post: post to be removed
     */
    func removePost(post: Post) {
        if let postID = post.id {
            //delete post
            postsRef?.document(postID).delete()
        }
    }
    
    /**
     function to update post
     @params
     post: post to be updated
     */
    func updatePost(post: Post) {
        if let postID = post.id {
            do {
                //update post
                try postsRef?.document(postID).setData(from: post)
            } catch {
                print("error updating \(error)")
            }
        }
    }
    
    /**
     function to get post by id
     @params:
     id: id of post to be found
     @return
     Post: optional Post object found
     */
    func getPostById(_ id: String) -> Post? {
        for post in posts {
            if post.id == id {
                return post
            }
        }
        
        return nil
    }
    
    /**
     function to get post price by calculating prices of each part
     @params:;
     id: id of post
     @return
     Float: total price
     */
    func getPostPrice(_ id: String) -> Float {
        for post in posts {
            //find parts which belong to this post
            if post.id == id {
                var price: Float = 0
                if let parts = post.parts {
                    // add price to total price
                    for part in parts {
                        price += part.price!
                    }
                    
                    return price
                }
            }
        }
        return 0
    }
    
    /**
     function to get post image and set imageview's image to the retrieved image
     @params:
     post: post whose image is to be found
     imageView: imageView to be set
     @return
     StorageDownloadTask: download task to observe
     */
    func getPostImage(post: Post, imageView: UIImageView) -> StorageDownloadTask? {
        var downloadTask: StorageDownloadTask?
        if post.picture?.isEmpty == false {
            let filepath = "\(post.id!)/postPhoto"
 
            if imageCache[filepath] != nil {
                imageView.image = imageCache[filepath]
            } else {
                downloadTask = storage?.reference().child(filepath).getData(maxSize: 10000*1024*1024) { data, error in
                    
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    
                    if let data = data {
                        imageView.image = UIImage(data: data)
                        self.imageCache[filepath] = UIImage(data: data)
                    }
                }
            }
        }
        
        return downloadTask
    }
    
    /**
     function to update post's image
     @params:
     post: post to be updated
     image: new image
     @return:
     StorageUploadTask: upload task to be observed
     */
    func updatePostImage(post: Post, image: UIImage?) -> StorageUploadTask? {
        if let image {
            if let postID = post.id {
                postsRef?.document(postID).updateData(["picture": "exists"])
                
                let storageRef = storage!.reference()
                let uploadData = image.pngData()! as Data
                let filePath = "\(postID)/\("postPhoto")"
                let metaData = StorageMetadata()
                metaData.contentType = "image/jpg"
                
                let uploadTask = storageRef.child(filePath).putData(uploadData, metadata: metaData){(metaData, error) in
                    if let error = error {
                        print("error uploading photo: \(error.localizedDescription)")
                        return
                    }
                    self.imageCache[filePath] = image
                }
                
                return uploadTask
            }
        }
        return nil
    }
    
    //set up post listener
    func setupPostListener() {
        postsRef = database.collection("posts")
        postsSnapshotListener = postsRef?.addSnapshotListener() {
            (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                print("failed to fetch documents with error: \(String(describing: error))")
                return
            }
            
            self.parsePostsSnapshot(snapshot: querySnapshot)
        }
    }
    
    //set up post snapshot
    func parsePostsSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach{ (change) in
            var parsedPost: Post?
            
            do {
                parsedPost = try change.document.data(as: Post.self)
            } catch {
                print("unable to decode post")
                return
            }
            
            guard let post = parsedPost else {
                print("document doesnt exist")
                return
            }
            
            if change.type == .added {
                posts.insert(post, at: Int(change.newIndex))
            } else if change.type == .removed {
                posts.remove(at: Int(change.oldIndex))
            } else if change.type == .modified {
                posts.remove(at: Int(change.oldIndex))
                posts.insert(post, at: Int(change.newIndex))
            }
        }
        
        listeners.invoke{ (listener) in
            if listener.listenerType == ListenerType.posts || listener.listenerType == ListenerType.all{
                listener.onPostsChange(change: .update, posts: posts)
            }
        }
    }
    
    /**
     function to get postpart image and set imageview's image to the retrieved image
     @params:
     part: postpart whose image is to be found
     imageView: imageView to be set
     @return
     StorageDownloadTask: download task to observe
     */
    func getPartImage(part: PostPart, imageView: UIImageView) -> StorageDownloadTask? {
        var downloadTask: StorageDownloadTask?
        if part.picture?.isEmpty == false {
            let filepath = "\(part.id!)/partPhoto"
            if imageCache[filepath] != nil {
                imageView.image = imageCache[filepath]
            } else {
                downloadTask = storage?.reference().child(filepath).getData(maxSize: 10000*1024*1024) { data, error in
                    
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    
                    if let data = data {
                        imageView.image = UIImage(data: data)
                    }
                }
            }
        }
        
        return downloadTask
    }
    
    /**
     function to update postpart's image
     @params:
     part: postpart to be updated
     image: new image
     @return:
     StorageUploadTask: upload task to be observed
     */
    func updatePartImage(part: PostPart, image: UIImage?) -> StorageUploadTask? {
        if let image {
            if let partID = part.id {
                let storageRef = storage!.reference()
                let uploadData = image.pngData()! as Data
                let filePath = "\(partID)/\("partPhoto")"
                let metaData = StorageMetadata()
                metaData.contentType = "image/jpg"

                let uploadTask = storageRef.child(filePath).putData(uploadData, metadata: metaData){(metaData, error) in
                    if let error = error {
                        print("error uploading photo: \(error.localizedDescription)")
                        return
                    }
                    self.imageCache[filePath] = image
                }

                return uploadTask
            }
        }
        return nil
    }
    
    //function to add wishlist
    func addWishlist() -> Wishlist {
        let user = User()
        user.email = currentUser?.email
        user.uid = currentUser?.uid
        
        let newWishlist = Wishlist()
        newWishlist.user = user
        
        do {
            //add wishlist
            if let wishlistRef = try wishlistRef?.addDocument(from: newWishlist) {
                newWishlist.id = wishlistRef.documentID
            }
        } catch {
            print("Failed to serialize item")
        }
        
        return newWishlist
    }
    
    //function to delete wishlist
    func removeWishlist(wishlist: Wishlist) {
        if let wishlistID = wishlist.id {
            wishlistRef?.document(wishlistID).delete()
        }
    }
    
    //function to get current user's wishlist
    func getWishlist() -> Wishlist {
        return wishlist
    }
    
    //function to add item to wishlist
    func addItemToWishlist(wishlist: Wishlist, item: Item) {
        guard let wishlistID = wishlist.id, let itemID = item.id else {
            return
        }
        
        if let newItemRef = itemsRef?.document(itemID) {
            wishlistRef?.document(wishlistID).updateData(
                ["items": FieldValue.arrayUnion([newItemRef])]
            )
        }
    }
    
    //function to remove item from wishlist
    func removeItemFromWishlist(wishlist: Wishlist, item: Item) {
        guard let wishlistID = wishlist.id, let itemID = item.id else {
            return
        }
        
        if let itemRemoveRef = itemsRef?.document(itemID) {
            wishlistRef?.document(wishlistID).updateData(
                ["items": FieldValue.arrayRemove([itemRemoveRef])]
            )
        }
    }
    
    //set up wishlist listener
    func setupWishlistListener() {
        wishlistRef = database.collection("wishlists")
        //find current user's wishlist
        wishlistSnapshotListener = wishlistRef?.whereField("user.uid", isEqualTo: currentUser!.uid).addSnapshotListener{ (querySnapshot, error) in
            guard let querySnapshot = querySnapshot, let wishlistSnapshot =
                    querySnapshot.documents.first else {
                print("Error fetching wishlist: \(String(describing: error))")
                return
            }
            
            self.parseWishlistSnapshot(snapshot: wishlistSnapshot)
                    
        }
    }
    
    //set up wishlist snapshot
    func parseWishlistSnapshot(snapshot: QueryDocumentSnapshot) {
        wishlist = Wishlist()
        wishlist.user = snapshot.data()["user"] as? User
        wishlist.id = snapshot.documentID
        
        if let itemReferences = snapshot.data()["items"] as? [DocumentReference] {
            for ref in itemReferences {
                if let item = getItemById(ref.documentID) {
                    wishlist.items.append(item)
                }
            }
        }
        
        listeners.invoke{ (listener) in
            if listener.listenerType == .wishlist || listener.listenerType == .all {
                listener.onWishlistChange(change: .update, wishlist: wishlist.items)
            }
        }
       
    }


    /**
     function to remove image
     @params:
     path: filepath of the image in firestore
     */
    func removeImage(path: String) {
        let storageRef = storage!.reference()
        let filePath = path

        //delete image
        let imageRef = storageRef.child(filePath)
        imageRef.delete { error in
            if let error {
                print("Error deleting image: \(error)")
            } else {
                //success
            }
        }
    }
}
