//
//  SignInViewController.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 01/06/2023.
//

import UIKit
import Firebase
import FirebaseAuth

class SignInViewController: UIViewController {


    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    var handle: AuthStateDidChangeListenerHandle?
    var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    

    @IBAction func signInHandler(_ sender: Any) {
        guard let email = emailField.text, email.isEmpty == false else {
            displayMessage(title: "Error", message: "Email cannot be empty", action: nil)
            return
        }
        
        guard let password = passwordField.text, password.isEmpty == false else {
            displayMessage(title: "Error", message: "Password cannot be empty", action: nil)
            return
        }
        
        showLoadingAnimation()
        
        self.databaseController?.authController.signIn(withEmail: email, password: password) { res, err in
            if let err = err {
                self.hideLoadingAnimation()
                self.displayMessage(title: "Error", message: "Error signing in: \(err)", action: nil)
                return
            }
            
            //if success add to local storage
            let userDefaults = UserDefaults.standard
            userDefaults.set(email, forKey: "email")
            userDefaults.set(password, forKey: "password")
            self.hideLoadingAnimation()
        }
    }
    
    
    @IBAction func signUpHandler(_ sender: Any) {
        guard let email = emailField.text, email.isEmpty == false else {
            displayMessage(title: "Error", message: "Email cannot be empty", action: nil)
            return
        }
        
        guard let password = passwordField.text, password.isEmpty == false else {
            displayMessage(title: "Error", message: "Password cannot be empty", action: nil)
            return
        }
        
        showLoadingAnimation()
        
        //sign up then sign in
        self.databaseController?.authController.createUser(withEmail: email, password: password) { res, err in
            if let err = err {
                self.hideLoadingAnimation()
                self.displayMessage(title: "Error", message: "Error signing up: \(err)", action: nil)
                return
            }
            
            //create wishlist
            let _ = self.databaseController?.addWishlist()
                        
            self.databaseController?.authController.signIn(withEmail: email, password: password) { res, err in
                if let err = err {
                    self.hideLoadingAnimation()
                    self.displayMessage(title: "Error", message: "Error signing in: \(err)", action: nil)
                    return
                }
                
                //if success add to local storage
                let userDefaults = UserDefaults.standard
                userDefaults.set(email, forKey: "email")
                userDefaults.set(password, forKey: "password")
                self.hideLoadingAnimation()
            }
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //listener to auth state changes
        handle = databaseController?.authController.addStateDidChangeListener{ auth, user in
            if user?.email != nil && user?.isAnonymous == false {
                self.databaseController?.currentUser = user
                self.databaseController?.setupWishlistListener()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.authController.removeStateDidChangeListener(handle!)
    }
}
