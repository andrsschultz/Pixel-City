//
//  PopVC.swift
//  PixelCity
//
//  Created by Andreas Schultz on 23.12.18.
//  Copyright © 2018 Andreas Schultz. All rights reserved.
//

import UIKit

class PopVC: UIViewController, UIGestureRecognizerDelegate{
    
    //PROPERTIES
    @IBOutlet var popImageView: UIImageView!
    
    var passedImage: UIImage!
    
    //OVERRIDE FUNCS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popImageView.image = passedImage
        
        addDoubleTap()
    }
    
    //CUSTOM FUNCS
    
    func initData(forImage image: UIImage) {
        self.passedImage = image
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(screenWasDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
    }
    
    @objc func screenWasDoubleTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    //ACTIONS

}
