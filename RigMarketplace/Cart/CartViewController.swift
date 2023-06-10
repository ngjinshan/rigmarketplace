//
//  CartViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 24/04/2023.
//

import UIKit
import FirebaseStorage

class CartViewController: UIViewController, CDatabaseListener {
    
    var listenerType: ListenerType = .cart
    var coredataController: CDatabaseProtocol?
    var databaseController: DatabaseProtocol?
    
    var task: StorageDownloadTask?
    var storage: Storage?
    
    var cart = [Cart]() //all cart elements
    var items = [Item]() //array to convert cart elements to actual items, we are doing this so it is easier to manipulate the items directly
    
    var signInView: SignInView?

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        coredataController = appDelegate?.coredataController
        databaseController = appDelegate?.databaseController
        
        tableView.delegate = self
        tableView.dataSource = self
        
        signInView = SignInView(frame: view.frame)
    }
    
    //checkout button handler
    @IBAction func checkout(_ sender: Any) {
        items.forEach{(item) in
            //set to sold and set buyer to current user
            item.sold = true
            
            let user = User()
            user.email = databaseController?.currentUser?.email
            user.uid = databaseController?.currentUser?.uid
            
            item.user_buyer = user
            databaseController?.updateItem(item: item)
        }
        
        let action = UIAlertAction(title: "Close", style: .default, handler: {(alert: UIAlertAction!) in
            //move to tracking page
            self.performSegue(withIdentifier: Constants.CHECKOUT_SEGUE, sender: self)
        })
        
        displayMessage(title: "You're all set!", message: "Your item is on the way", action: action)
    }
    
    func onCartChange(change: DatabaseChange, cart: [Cart]) {
        items = [Item]()
        self.cart = cart
        cart.forEach{ (c) in
            //get item from database and append to item array
            let item = databaseController?.getItemById(c.itemID!)
            if let item = item {
                if(item.sold == true) {
                    //if sold just delete from cart
                    coredataController?.deleteItemFromCart(cart: c)
                } else {
                    items.append(item)
                }
            } else {
                //delete if item no longer in db
                coredataController?.deleteItemFromCart(cart: c)
            }
        }
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        coredataController?.addListener(listener: self)
        
        //if not signed in, show sign in view
        if(databaseController?.authController.currentUser?.isAnonymous == true) {
            self.view.addSubview(signInView!)
        } else {
            signInView?.removeFromSuperview()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        coredataController?.removeListener(listener: self)

    }

}

extension CartViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CART_TABLE_ID, for: indexPath)
        
        cell.textLabel?.text = items[indexPath.row].name //set to item name
        cell.detailTextLabel?.text = "$\(items[indexPath.row].price!)" //set to item price

        //get item image
        if items[indexPath.row].picture?.isEmpty == false {
            task = databaseController?.getItemImage(item: items[indexPath.row], imageView: cell.imageView!)
        }
        
        if let task {
            task.observe(.success) { _ in
                tableView.reloadData()
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = items[indexPath.row]
            cart.forEach{ (c) in
                if(c.itemID! == item.id!) {
                    //delete from cart
                    self.coredataController?.deleteItemFromCart(cart: c)
                    return
                }
            }
        } else if editingStyle == .insert {
            // do nothing
        }
    }
    
}
