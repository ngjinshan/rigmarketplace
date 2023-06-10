//
//  MarketplaceBuyItemDetailViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 23/04/2023.
//

import UIKit
import FirebaseStorage

class MarketplaceBuyItemDetailViewController: UIViewController, CDatabaseListener, DatabaseListener {

    var item: Item? //item from marketplaceviewcontroller segue
    
    @IBOutlet weak var descriptionField: UILabel!
    @IBOutlet weak var priceField: UILabel!
    @IBOutlet weak var ratingField: UILabel!
    @IBOutlet weak var userField: UILabel!
    @IBOutlet weak var nameField: UILabel!
    @IBOutlet weak var imageField: UIImageView!
    var databaseController: DatabaseProtocol?
    var coredataController: CDatabaseProtocol?
    var listenerType: ListenerType = ListenerType.all //wishlist + cart
    var task: StorageDownloadTask?
    var wishlist: [Item] = []
    
    @IBOutlet weak var wishlistButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        coredataController = appDelegate?.coredataController
        
        //set fields to item from segue
        if let item {
            nameField.text = item.name
            userField.text = item.user_seller?.email
            priceField.text = "$\(String(describing: item.price!))"
            descriptionField.text = item.itemDescription
            
            //get item image
            if(item.picture?.isEmpty == false) {
                task = databaseController?.getItemImage(item: item, imageView: self.imageField)
            }
        }
    }
    
    //add to cart button handler
    @IBAction func addToCart(_ sender: Any) {
        if let item {
            //if not logged in segue to log in, otherwise add to cart
            if(databaseController?.currentUser?.isAnonymous == true) {
                performSegue(withIdentifier: Constants.SIGN_IN_SEGUE, sender: nil)
            } else {
                let _ = coredataController?.addItemToCart(item: item)
                
                let action = UIAlertAction(title: "Close", style: .default, handler: {(alert: UIAlertAction!) in
                    self.navigationController?.popViewController(animated: true)
                })
                
                displayMessage(title: "You're all set!", message: "Your item has been added to cart", action: action)
            }
        }
    }
    
    @IBAction func wishlistButtonHandler(_ sender: Any) {
        if let item = item {
            var wished = false
            let userWishlist = self.databaseController?.getWishlist()
            wishlist.forEach{ wishlistItem in
                if wishlistItem.id == item.id {
                    wished = true
                    return
                }
            }
            
            if wished == true {
                self.databaseController?.removeItemFromWishlist(wishlist: userWishlist!, item: item)
            } else {
                self.databaseController?.addItemToWishlist(wishlist: userWishlist!, item: item)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        coredataController?.addListener(listener: self)
        databaseController?.addListener(listener: self)
        
        if(databaseController?.currentUser?.isAnonymous == false) {
            wishlistButton.isHidden = false
        } else {
            wishlistButton.isHidden = true
        }
    }
//
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        coredataController?.removeListener(listener: self)
        databaseController?.removeListener(listener: self)
    }
    
    func onCartChange(change: DatabaseChange, cart: [Cart]) {
        //do nothing
    }
    
    func onItemsChange(change: DatabaseChange, items: [Item]) {
        //do nothing
    }
    
    func onPostsChange(change: DatabaseChange, posts: [Post]) {
        //do nothing
    }
    
    func onWishlistChange(change: DatabaseChange, wishlist: [Item]) {
        self.wishlist = wishlist
        var wished = false
        if let item = item {
            wishlist.forEach{ wishlistItem in
                if wishlistItem.id == item.id {
                    wished = true
                    return
                }
            }
            
            if(wished == true) {
                wishlistButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            } else {
                wishlistButton.setImage(UIImage(systemName: "heart"), for: .normal)
            }
        }
    }
}
