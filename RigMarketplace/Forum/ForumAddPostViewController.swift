//
//  ForumAddPostViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 16/05/2023.
//

import UIKit
import FirebaseStorage

class ForumAddPostViewController: UIViewController, DatabaseListener {
    
    var listenerType: ListenerType = .posts

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var parts: [PostPart] = [] //all parts
    var databaseController: DatabaseProtocol?
    var task: StorageDownloadTask?
    var storage: Storage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        storage = databaseController!.storage
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    /**
     function to add image from gallery or camera
     */
    @IBAction func addImage(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        
        let actionSheet = UIAlertController(title: "Add Photo", message: "Choose a source", preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
                picker.sourceType = .camera
                self.present(picker, animated: true, completion: nil)
            }
            
            actionSheet.addAction(cameraAction)
        }
        
        let galleryAction = UIAlertAction(title: "Gallery", style: .default) { _ in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion: nil)
        }
        
        actionSheet.addAction(galleryAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    /**
     add post button handler
     */
    @IBAction func addPost(_ sender: Any) {
        //description cannot be empty
        guard let postDescription = descriptionField.text, postDescription.isEmpty == false else {
            displayMessage(title: "Error", message: "Description cannot be empty", action: nil)
            return
        }
        
        //parts cannot be empty
        guard let postparts = databaseController?.postParts, postparts.count > 0 else {
            displayMessage(title: "Error", message: "Parts cannot be empty", action: nil)
            return
        }
        
        showLoadingAnimation()
        
        //add post
        let newPost = databaseController?.addPost(postDescription: postDescription, picture: "", parts: databaseController!.postParts)
        
        //upload image
        let uploadTask = databaseController?.updatePostImage(post: newPost!, image: imageView.image)
        
        //close action
        let action = UIAlertAction(title: "Close", style: .default, handler: {(alert: UIAlertAction!) in
            self.hideLoadingAnimation()
            self.databaseController?.postParts = [PostPart]() //reset postparts
            self.navigationController?.popViewController(animated: true) //go back to previous page
        })
        
        //if upload image successful
        if let uploadTask {
            uploadTask.observe(.success) {
                snapshot in
                self.displayMessage(title: "You're all set!", message: "Your post has been added", action: action)
            }
        } else {
            displayMessage(title: "You're all set!", message: "Your post has been added", action: action)
        }
        
    }
    
    
    func onItemsChange(change: DatabaseChange, items: [Item]) {
        //do nothing
    }
    
    func onPostsChange(change: DatabaseChange, posts: [Post]) {
        //do nothing
    }
    
    func onWishlistChange(change: DatabaseChange, wishlist: [Item]) {
        //do nothing
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
}

extension ForumAddPostViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.FORUM_TABLE_CELL, for: indexPath)
        cell.textLabel?.text = databaseController!.postParts[indexPath.row].name //set to post part name
        cell.detailTextLabel?.text = "$\(databaseController!.postParts[indexPath.row].price!)" //set to price
        cell.imageView?.image = nil //set image to nil while waiting for new downloadtask to be complete
        
        //get image
        if databaseController!.postParts[indexPath.row].picture?.isEmpty == false {
            task = databaseController?.getPartImage(part: databaseController!.postParts[indexPath.row], imageView: cell.imageView!)
        }
        
        if let task {
            task.observe(.success) { _ in
                tableView.reloadData()
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return databaseController!.postParts.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //delete image from storage?
            databaseController!.postParts.remove(at: indexPath.row) //remove from postparts
            self.tableView.reloadData()
        } else if editingStyle == .insert {
            // do nothing
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch(section) {
        default: return "Parts"
        }
    }
    
}

extension ForumAddPostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage
        self.imageView.image = image
        self.dismiss(animated: true, completion: nil)
    }
}
