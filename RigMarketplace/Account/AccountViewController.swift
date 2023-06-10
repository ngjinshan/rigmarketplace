//
//  AccountViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 23/05/2023.
//

import UIKit
import FirebaseStorage

class AccountViewController: UIViewController, DatabaseListener {
    
    var listenerType: ListenerType = .all
    var databaseController: DatabaseProtocol?
    var task: StorageDownloadTask?
    var storage: Storage?
    var posts: [Post] = [] //all posts
    var items: [Item] = [] //all items
    var boughtItems: [Item] = [] //users bought items
    var sellingItems: [Item] = [] //users items being sold
    var soldItems: [Item] = [] //users sold items
    var myPosts: [Post] = [] //user's posts
    var wishlist: [Item] = []
    var selected: Any? //selected table row
    
    var signInView: SignInView?
    
    @IBOutlet weak var tableViewUpper: UITableView!
    @IBOutlet weak var tableViewLower: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        storage = databaseController!.storage
        tableViewUpper.dataSource = self
        tableViewUpper.delegate = self
        
        tableViewLower.dataSource = self
        tableViewLower.delegate = self
        
        signInView = SignInView(frame: view.frame)
    }
    

    @IBAction func segmentedControlChange(_ sender: Any) {
        tableViewUpper.reloadData()
        tableViewLower.reloadData()
    }
    
    //function to sign out
    @IBAction func signOutHandler(_ sender: Any) {
        Task {
            self.showLoadingAnimation()
            await databaseController?.signOut()
            self.hideLoadingAnimation()
            self.view.addSubview(signInView!)
        }
    }
    
    func onItemsChange(change: DatabaseChange, items: [Item]) {
        self.items = items
        
        //find items sold by user
        boughtItems = items.filter({(item: Item) -> Bool in
            return item.sold == true && item.user_buyer!.uid == databaseController?.currentUser?.uid
        })
        
        //find items being sold by user
        sellingItems = items.filter({(item: Item) -> Bool in
            return item.sold == false && item.user_seller!.uid == databaseController?.currentUser?.uid
        })
        
        //find items sold by user
        soldItems = items.filter({(item: Item) -> Bool in
            return item.sold == true && item.user_seller!.uid == databaseController?.currentUser?.uid
        })
        
        tableViewUpper.reloadData()
        tableViewLower.reloadData()
    }
    
    func onPostsChange(change: DatabaseChange, posts: [Post]) {
        self.posts = posts
        //find own posts
        myPosts = posts.filter({(post: Post) -> Bool in
            return post.user!.uid == databaseController?.currentUser?.uid
        })
                
        tableViewUpper.reloadData()
        tableViewLower.reloadData()
    }
    
    func onWishlistChange(change: DatabaseChange, wishlist: [Item]) {
        //update wishlist
        self.wishlist = wishlist
        
        tableViewUpper.reloadData()
        tableViewLower.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        
        //add sign in view if not signed in
        if(databaseController?.authController.currentUser?.isAnonymous == true) {
            self.view.addSubview(signInView!)
        } else {
            signInView?.removeFromSuperview()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.ACCOUNT_ORDER_SEGUE {
            //do nothing for now
        } else if segue.identifier == Constants.ACCOUNT_LISTING_SEGUE {
            let view = segue.destination as! MarketplaceSellDetailViewController
            view.item = selected as? Item
        } else if segue.identifier == Constants.ACCOUNT_WISHLIST_SEGUE {
            //do nothing for now
            let view = segue.destination as! MarketplaceBuyItemDetailViewController
            view.item = selected as? Item
        } else if segue.identifier == Constants.ACCOUNT_POST_SEGUE {
            let view = segue.destination as! ForumDetailViewController
            view.post = selected as? Post
        }
    }

}

extension AccountViewController: UITableViewDelegate, UITableViewDataSource {
    
    /**
     case 0: bought items
     case 1: listing
     case 2: wishlist
     case 3: posts
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch segmentControl.selectedSegmentIndex {
        case 0:
            if tableView == tableViewUpper {
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.ACCOUNT_TABLE_1, for: indexPath)
                cell.textLabel?.text = boughtItems[indexPath.row].name
                cell.detailTextLabel?.text = "$\(boughtItems[indexPath.row].price!)"
                
                if boughtItems[indexPath.row].picture?.isEmpty == false {
                    task = databaseController?.getItemImage(item: boughtItems[indexPath.row], imageView: cell.imageView!)
                }
        
                if let task {
                    task.observe(.success) { _ in
                        tableView.reloadData()
                    }
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.ACCOUNT_TABLE_2, for: indexPath)
                return cell
            }
        case 1:
            if tableView == tableViewUpper {
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.ACCOUNT_TABLE_1, for: indexPath)
                cell.textLabel?.text = sellingItems[indexPath.row].name
                cell.detailTextLabel?.text = "$\(sellingItems[indexPath.row].price!)"
                cell.imageView?.image = nil
                
                if sellingItems[indexPath.row].picture?.isEmpty == false {
                    task = databaseController?.getItemImage(item: sellingItems[indexPath.row], imageView: cell.imageView!)
                }
        
                if let task {
                    task.observe(.success) { _ in
                        tableView.reloadData()
                    }
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.ACCOUNT_TABLE_2, for: indexPath)
                cell.textLabel?.text = soldItems[indexPath.row].name
                cell.detailTextLabel?.text = "$\(soldItems[indexPath.row].price!)"
                cell.imageView?.image = nil
                
                if soldItems[indexPath.row].picture?.isEmpty == false {
                    task = databaseController?.getItemImage(item: soldItems[indexPath.row], imageView: cell.imageView!)
                }
        
                if let task {
                    task.observe(.success) { _ in
                        tableView.reloadData()
                    }
                }
                
                return cell
            }
        case 2:
            if tableView == tableViewUpper {
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.ACCOUNT_TABLE_1, for: indexPath)

                cell.textLabel?.text = wishlist[indexPath.row].name
                cell.detailTextLabel?.text = "$\(wishlist[indexPath.row].price!)"
                cell.imageView?.image = nil
                
                if wishlist[indexPath.row].picture?.isEmpty == false {
                    task = databaseController?.getItemImage(item: wishlist[indexPath.row], imageView: cell.imageView!)
                }
        
                if let task {
                    task.observe(.success) { _ in
                        tableView.reloadData()
                    }
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.ACCOUNT_TABLE_2, for: indexPath)
                return cell
            }
        case 3:
            if tableView == tableViewUpper {
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.ACCOUNT_TABLE_1, for: indexPath)
                cell.textLabel?.text = myPosts[indexPath.row].postDescription
                let price = databaseController?.getPostPrice(myPosts[indexPath.row].id!)
                cell.detailTextLabel?.text = "$\(price!)"
                cell.imageView?.image = nil
                
                if myPosts[indexPath.row].picture?.isEmpty == false {
                    task = databaseController?.getPostImage(post: myPosts[indexPath.row], imageView: cell.imageView!)
                }
        
                if let task {
                    task.observe(.success) { _ in
                        tableView.reloadData()
                    }
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.ACCOUNT_TABLE_2, for: indexPath)
                
                return cell
            }
        default:
            if tableView == tableViewUpper {
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.ACCOUNT_TABLE_1, for: indexPath)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.ACCOUNT_TABLE_2, for: indexPath)
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentControl.selectedSegmentIndex {
        case 0:
            if tableView == tableViewUpper {
                return boughtItems.count
            } else {
                //return 0 for now as we dont have the capability to track orders for now
                return 0
            }
        case 1:
            if tableView == tableViewUpper {
                return sellingItems.count
            } else {
                return soldItems.count
            }
        case 2:
            if tableView == tableViewUpper {
                return wishlist.count
            } else {
                //not needed
                return 0
            }
        case 3:
            if tableView == tableViewUpper {
                return myPosts.count
            } else {
                //liked posts not available yet
                return 0
            }
        default:
            if tableView == tableViewUpper {
                return 0
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch segmentControl.selectedSegmentIndex {
        case 0:
            if tableView == tableViewUpper {
                return "Active"
            } else {
                return "Received"
            }
        case 1:
            if tableView == tableViewUpper {
                return "Active"
            } else {
                return "Sold"
            }
        case 2:
            if tableView == tableViewUpper {
                return "Wishlist"
            } else {
                return nil
            }
        case 3:
            if tableView == tableViewUpper {
                return "Your posts"
            } else {
                return "Liked posts - Coming soon"
            }
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch segmentControl.selectedSegmentIndex {
        case 0:
            if tableView == tableViewUpper {
                performSegue(withIdentifier: Constants.ACCOUNT_ORDER_SEGUE, sender: nil)
            } else {
                //do nothing for now
            }
            
            break
        case 1:
            if tableView == tableViewUpper {
                selected = sellingItems[indexPath.row]
                performSegue(withIdentifier: Constants.ACCOUNT_LISTING_SEGUE, sender: nil)
            } else {
                //do nothing for now
            }
            
            break
        case 2:
            if tableView == tableViewUpper {
                selected = wishlist[indexPath.row]
                performSegue(withIdentifier: Constants.ACCOUNT_WISHLIST_SEGUE, sender: nil)
            } else {
                //do nothing for now
            }
            
            break
        case 3:
            if tableView == tableViewUpper {
                selected = myPosts[indexPath.row]
                performSegue(withIdentifier: Constants.ACCOUNT_POST_SEGUE, sender: nil)
            } else {
                //do nothing for now
            }
            
            break
        default:
            //do nothing
            break
        }
    }
}
