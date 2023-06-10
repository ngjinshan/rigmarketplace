//
//  ForumViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 15/05/2023.
//

import UIKit
import FirebaseStorage

class ForumViewController: UIViewController, DatabaseListener, UISearchBarDelegate {

    @IBOutlet weak var newPost: UIBarButtonItem!
    @IBOutlet weak var searchbar: UISearchBar!
    
    @IBOutlet weak var collectionView: UICollectionView!
    var listenerType: ListenerType = .posts
    var posts: [Post] = [] //all posts
    var filteredPosts: [Post] = [] //filtered posts
    var databaseController: DatabaseProtocol?
    var selectedPost: Post? //selected post
    var task: StorageDownloadTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        //setting collection view layout to 1 column per row
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
        layout.itemSize = CGSize(width: collectionView.frame.size.width/1, height: collectionView.frame.size.width/1)
        collectionView.collectionViewLayout = layout
        
        searchbar.delegate = self
        
//        showLoadingAnimation()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            self.hideLoadingAnimation()
//        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredPosts = posts
        
        if(searchText.count > 0) {
            //filter by text
            filteredPosts = filteredPosts.filter({(post: Post) -> Bool in
                //filter by post description or user email
                let filterQuery = post.postDescription?.lowercased().contains(searchText.lowercased()) ?? false || post.user!.email?.lowercased().contains(searchText.lowercased()) ?? false
                
                return filterQuery
            })
        }
        
        collectionView.reloadData()
    }
    
    
    // Bar Button handler
    @IBAction func addPostHandler(_ sender: Any) {
        //if signed in, segue to add post view else segue to sign in
        if databaseController?.currentUser?.isAnonymous == true {
            performSegue(withIdentifier: Constants.SIGN_IN_SEGUE, sender: nil)
        } else {
            performSegue(withIdentifier: Constants.FORUM_ADD_NEW_SEGUE, sender: nil)
        }
    }
    
    func onPostsChange(change: DatabaseChange, posts: [Post]) {
        self.posts = posts
        self.filteredPosts = self.posts
        collectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    func onItemsChange(change: DatabaseChange, items: [Item]) {
        //do nothing
    }
    
    func onWishlistChange(change: DatabaseChange, wishlist: [Item]) {
        //do nothing
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.FORUM_SHOW_DETAIL_SEGUE {
            let view = segue.destination as! ForumDetailViewController
            view.post = selectedPost //set post in detailviewcontroller to selected post
        }
    }
}

extension ForumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredPosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.FORUM_COLLECTION_ID, for: indexPath) as! ForumCollectionViewCell
        
        cell.userText.text = filteredPosts[indexPath.row].user!.email //set to user email
        cell.descriptionText.text = filteredPosts[indexPath.row].postDescription //set to post description
        let price = databaseController?.getPostPrice(filteredPosts[indexPath.row].id!) //get all parts price
        cell.priceText.text = "$\(price!)" //set to all parts price
        
        cell.imageView.image = nil //set image to nil while waiting for new downloadtask to be complete

        if(filteredPosts[indexPath.row].picture?.isEmpty == false) {
            //get post image
            task = databaseController?.getPostImage(post: filteredPosts[indexPath.row], imageView: cell.imageView)
        }
        
        //cell styling
        cell.layer.borderWidth = 1
        cell.layer.borderColor = hexStringToUIColor(hex: "#e6e6e6").cgColor
//        cell.layer.shadowColor = UIColor.gray.cgColor
//        cell.layer.shadowOpacity = 0.5
//        cell.layer.shadowOffset = CGSize.zero
//        cell.layer.shadowRadius = 5
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedPost = filteredPosts[indexPath.row]
        performSegue(withIdentifier: Constants.FORUM_SHOW_DETAIL_SEGUE, sender: nil)
    }
}
