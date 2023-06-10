//
//  MarketplaceSellNewViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 30/04/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import FirebaseStorage

class MarketplaceSellNewViewController: UIViewController, DatabaseListener {

    @IBOutlet weak var priceField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var imageView: UIImageView!
    var listenerType: ListenerType = .items
    var databaseController: DatabaseProtocol?
    var storage: Storage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        storage = databaseController!.storage
    }
    

    //save button handler
    @IBAction func saveButton(_ sender: Any) {
        
        //name cannot be empty
        guard let name = nameField.text, nameField.text?.isEmpty == false else {
            displayMessage(title: "Error", message: "Name cannot be empty", action: nil)
            return
        }
        
        //description cannot be empty
        guard let itemDescription = descriptionField.text, itemDescription.isEmpty == false else {
            displayMessage(title: "Error", message: "Description cannot be empty", action: nil)
            return
        }
        
        //price must be number and cannot be empty
        guard let price = Float(priceField.text!) else {
            displayMessage(title: "Error", message: "Price cannot be empty or must be number", action: nil)
            return
        }
        
        showLoadingAnimation()
        
        //add item
        let newItem = databaseController?.addItem(name: name, itemDescription: itemDescription, picture: "", price: price, category: 0, sold: false)
        
        //upload image
        let uploadTask = databaseController?.updateItemImage(item: newItem!, image: imageView.image)
        
        let action = UIAlertAction(title: "Close", style: .default, handler: {(alert: UIAlertAction!) in
            self.hideLoadingAnimation()
            self.navigationController?.popViewController(animated: true)
        })
        
        if let uploadTask {
            uploadTask.observe(.success) {
                snapshot in
                self.displayMessage(title: "You're all set!", message: "Your item has been added", action: action)
            }
        } else {
            displayMessage(title: "You're all set!", message: "Your item has been added", action: action)
        }
        
    }
    
    
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
    
    func onItemsChange(change: DatabaseChange, items: [Item]) {
        //nothing
    }
    
    func onWishlistChange(change: DatabaseChange, wishlist: [Item]) {
        //do nothing
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }

    func onPostsChange(change: DatabaseChange, posts: [Post]) {
        //do nothing
    }
}

extension MarketplaceSellNewViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage
        self.imageView.image = image
        self.dismiss(animated: true, completion: nil)
    }
}
