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
import Alamofire
import AlamofireImage


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
    
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    
    var imageURLArray = [String]()
    var imageArray = [UIImage]()
    
    
    //OVERRIDE FUNCS
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        configureLocationServices()
        
        addDoubleTap()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        pullUpView.addSubview(collectionView!)
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
        cancelAllSessions()
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
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLabel() {
        progressLabel = UILabel()
        progressLabel?.frame = CGRect(x: (screenSize.width/2) - 120, y: 175, width: 240, height: 40)
        progressLabel?.font = UIFont(name: "Avenir Next", size: 18)
        progressLabel?.textColor = #colorLiteral(red: 0.1215686277, green: 0.1294117719, blue: 0.1411764771, alpha: 1)
        progressLabel?.textAlignment = .center
        progressLabel?.text = "Images loading..."
        collectionView?.addSubview(progressLabel!)
    }
    
    func removeProgressLabel() {
        if progressLabel != nil {
            progressLabel?.removeFromSuperview()
        }
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
        
        imageURLArray = []
        imageArray = []
        collectionView?.reloadData()
        
        cancelAllSessions()
        removePin()
        removeSpinner()
        removeProgressLabel()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLabel()
        
        let touchpoint = sender.location(in: mapView)
        let touchpointCoordinate = mapView.convert(touchpoint, toCoordinateFrom: mapView)
        
        let annotation = DropablePIn(coordinate: touchpointCoordinate, identifier: "dropablePin")
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegion.init(center: touchpointCoordinate, latitudinalMeters: regionRadius,  longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        
        retrieveURLs(forAnnotation: annotation) { (finished) in
            if finished {
                self.retrieveImages(handler: { (finished) in
                    self.removeSpinner()
                    self.removeProgressLabel()
                    self.collectionView?.reloadData()
                })
            }
        }
        
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func retrieveURLs(forAnnotation annotation: DropablePIn, handler: @escaping (_ status: Bool) -> ()) {
        
        Alamofire.request(flickrURL(forAPIKey: apiKey, withAnnotation: annotation, andNumberOfPhotos: 40)).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
            let photosDict = json["photos"] as! Dictionary<String, AnyObject>
            let photosDictArray = photosDict["photo"] as! [Dictionary<String, AnyObject>]
            for photo in photosDictArray {
                let postURL = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                self.imageURLArray.append(postURL)
            }
            handler(true)
        }
    }
    
    func retrieveImages(handler: @escaping (_ status: Bool) -> ()) {

        for url in imageURLArray {
            Alamofire.request(url).responseImage { (response) in
                guard let image = response.result.value else { return }
                self.imageArray.append(image)
                self.progressLabel?.text = "\(self.imageArray.count)/40 Images downloaded"
                
                if self.imageArray.count == self.imageURLArray.count {
                    handler(true)
                }
            }
        }
    }
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            for task in sessionDataTask {
                task.cancel()
            }
            for data in downloadData {
                data.cancel()
            }
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

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else {
            return UICollectionViewCell()
        }
        let imageView = UIImageView(image: imageArray[indexPath.row])
        cell.addSubview(imageView)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return }
        popVC.initData(forImage: imageArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
    
}

