//
//  SignInView.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 01/06/2023.
//

import UIKit

class SignInView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        
        //add button
        let button = UIButton(type: .system)
        button.configuration = .filled()
        button.setTitle("Sign In", for: .normal)
        
        button.addTarget(self, action: #selector(signInHandler), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        
        //center of screen
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    /**
     function to get parent view controller
     got the function from ChatGPT
     */
    func getParent() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
    
    //sign in button handler
    @objc private func signInHandler() {
        if let parent = getParent() {
            parent.performSegue(withIdentifier: Constants.SIGN_IN_SEGUE, sender: nil)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
