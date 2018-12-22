//
//  ViewController.swift
//  PixelCity
//
//  Created by Andreas Schultz on 22.12.18.
//  Copyright © 2018 Andreas Schultz. All rights reserved.
//

import UIKit
import MapKit


class MapVC: UIViewController {

    //PROPERTIES
    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
    }

    
    //ACTIONS
    @IBAction func centerMapButtonTouched(_ sender: Any) {
    }
    
}


extension MapVC: MKMapViewDelegate {
    
}

