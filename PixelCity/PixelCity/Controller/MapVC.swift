//
//  ViewController.swift
//  PixelCity
//
//  Created by Andreas Schultz on 22.12.18.
//  Copyright © 2018 Andreas Schultz. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class MapVC: UIViewController, UIGestureRecognizerDelegate {

    //PROPERTIES
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var pullUpViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var pullUpView: UIView!
    
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000

    var screenSize = UIScreen.main.bounds
    
    var spinner: UIActivityIndicatorView?
    var progressLabel: UILabel?
    
    
    //OVERRIDE FUNCS
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        configureLocationServices()
        
        addDoubleTap()

    }
    
    //CUSTOM FUNCS
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    
    func animateViewUp() {
        pullUpViewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func animateViewDown() {
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width/2) - ((spinner?.frame.width)!/2), y: 150)
        spinner?.style = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.1215686277, green: 0.1294117719, blue: 0.1411764771, alpha: 1)
        spinner?.startAnimating()
        pullUpView.addSubview(spinner!)
    }

    
    //ACTIONS
    @IBAction func centerMapButtonTouched(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
}



//EXTENSIONS
extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        } else {
            let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "dropablePin")
            pinAnnotation.pinTintColor = #colorLiteral(red: 0.9742404819, green: 0.6943389177, blue: 0.328597486, alpha: 1)
            pinAnnotation.animatesDrop = true
            return pinAnnotation
        }
    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: regionRadius,  longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func dropPin(sender: UIGestureRecognizer) {
        
        removePin()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        
        let touchpoint = sender.location(in: mapView)
        let touchpointCoordinate = mapView.convert(touchpoint, toCoordinateFrom: mapView)
        
        let annotation = DropablePIn(coordinate: touchpointCoordinate, identifier: "dropablePin")
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegion.init(center: touchpointCoordinate, latitudinalMeters: regionRadius,  longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
}

extension MapVC: CLLocationManagerDelegate {
    func configureLocationServices() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

