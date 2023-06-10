//
//  LoadingView.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 17/05/2023.
//

import UIKit

class LoadingView: UIView {
    
    private let activityIndicatorView: UIActivityIndicatorView
    
    override init(frame: CGRect) {
        
        activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true
        
        super.init(frame: frame)

        addSubview(activityIndicatorView)
        
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimating() {
        backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        activityIndicatorView.startAnimating()
    }
    
    func stopAnimating() {
        backgroundColor = UIColor(white: 0.0, alpha: 0.0)
        activityIndicatorView.stopAnimating()
    }
}
