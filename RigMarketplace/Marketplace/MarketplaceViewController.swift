//
//  MarketplaceViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 23/04/2023.
//

import UIKit
import FirebaseStorage

class MarketplaceViewController: UIViewController, DatabaseListener, UISearchBarDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchbar: UISearchBar!
    @IBOutlet weak var marketplaceSegmentControl: UISegmentedControl!
    
    @IBOutlet var addBarButton: UIBarButtonItem!
    var listenerType: ListenerType = .items
    var items: [Item] = [] //all items
    var filteredItems: [Item] = [] //filtered items
    var databaseController: DatabaseProtocol?
    var marketplaceType: Int = 0 //0 for buy, 1 for sell
    var selectedItem: Item? //selected item for segue
    var task: StorageDownloadTask?
    var signInView: SignInView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        //set layout to 2 columns per row
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
        layout.itemSize = CGSize(width: collectionView.frame.size.width/2.05, height: collectionView.frame.size.width/1.5)
        collectionView.collectionViewLayout = layout
        
        searchbar.delegate = self
        
        signInView = SignInView(frame: collectionView.frame)
    }
    
    //segment change function
    @IBAction func marketplaceSegmentValueChanged(_ sender: Any) {
        //get segmented items
        getSegmentedItems()
        
    }
    
    //searchbar change function
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //get segmented items
        getSegmentedItems()

        //filter by item name
        if(searchText.count > 0) {
            filteredItems = filteredItems.filter({(item: Item) -> Bool in
                return (item.name?.lowercased().contains(searchText.lowercased()) ?? false)
            })
        }
        
        collectionView.reloadData()
    }
    
    func onItemsChange(change: DatabaseChange, items: [Item]) {
        //set item array to items from database
        //filter to available items only
        self.items = items.filter({(item: Item) -> Bool in
            return (item.sold == false)
        })
        
        getSegmentedItems()
    }

    //function to get buying/selling items
    func getSegmentedItems() {
        if(marketplaceSegmentControl.selectedSegmentIndex == 0) {
            //filter items by not sold by user
            filteredItems = items.filter({(item: Item) -> Bool in
                return (item.user_seller?.uid != databaseController?.currentUser?.uid)
            })
            //if buying, then hide add button
            self.navigationItem.rightBarButtonItem = nil
            //remove sign in view
            self.signInView!.removeFromSuperview()
        } else if (marketplaceSegmentControl.selectedSegmentIndex == 1) {
            if(databaseController?.currentUser?.isAnonymous == true) {
                //ask to log in if not logged in
                self.view.addSubview(signInView!)
            } else {
                //filter items by sold by user
                filteredItems = items.filter({(item: Item) -> Bool in
                    return (item.user_seller?.uid == databaseController?.currentUser?.uid)
                })
                //if selling, then show add button
                self.navigationItem.rightBarButtonItem = addBarButton
                //remove sign in view
                self.signInView!.removeFromSuperview()
            }
        }
        
        collectionView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        
        //refresh
        getSegmentedItems()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if(identifier == Constants.MARKETPLACE_BUY_ITEM_DETAIL_SEGUE) {
            //segue to buy item detail if segment is 0 i.e buy
            return marketplaceSegmentControl.selectedSegmentIndex == 0 ? true : false
        }else if(identifier == Constants.MARKETPLACE_SELL_ITEM_DETAIL_SEGUE) {
            //segue to sell item detail if segment is 1 i.e sell
            return marketplaceSegmentControl.selectedSegmentIndex == 1 ? true : false
        }else if(identifier == Constants.MARKETPLACE_SELL_NEW_ITEM_SEGUE) {
            //segue to sell new item if segment is 1 i.e sell
            return marketplaceSegmentControl.selectedSegmentIndex == 1 ? true : false
        }

        return false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == Constants.MARKETPLACE_BUY_ITEM_DETAIL_SEGUE) {
            let view = segue.destination as! MarketplaceBuyItemDetailViewController
            view.item = selectedItem
        } else if(segue.identifier == Constants.MARKETPLACE_SELL_ITEM_DETAIL_SEGUE) {
            let view = segue.destination as! MarketplaceSellDetailViewController
            view.item = selectedItem
        }
    }
    
    func onPostsChange(change: DatabaseChange, posts: [Post]) {
        // do nothing
    }
    
    func onWishlistChange(change: DatabaseChange, wishlist: [Item]) {
        //do nothing
    }

}

extension MarketplaceViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.MARKETPLACE_COLLECTION_ID, for: indexPath) as! MarketplaceCollectionViewCell
        cell.nameField.text = filteredItems[indexPath.row].name //set to item name
        cell.priceField.text = "$\(String(describing: filteredItems[indexPath.row].price!.description))" //set to item price
        cell.imageField.image = nil //set image to nil while waiting for new downloadtask to be complete
        
        //get item picture
        if(filteredItems[indexPath.row].picture?.isEmpty == false) {
            task = databaseController?.getItemImage(item: filteredItems[indexPath.row], imageView: cell.imageField)
        }
        
        //cell style
        cell.layer.borderWidth = 1
        cell.layer.borderColor = hexStringToUIColor(hex: "#e6e6e6").cgColor
//        cell.layer.shadowColor = UIColor.gray.cgColor
//        cell.layer.shadowOpacity = 0.5
//        cell.layer.shadowOffset = CGSize.zero
//        cell.layer.shadowRadius = 5
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedItem = filteredItems[indexPath.row]
        if(marketplaceSegmentControl.selectedSegmentIndex == 0) {
            performSegue(withIdentifier: Constants.MARKETPLACE_BUY_ITEM_DETAIL_SEGUE, sender: nil)
        } else if(marketplaceSegmentControl.selectedSegmentIndex == 1) {
            performSegue(withIdentifier: Constants.MARKETPLACE_SELL_ITEM_DETAIL_SEGUE, sender: nil)
        }
    }
}
