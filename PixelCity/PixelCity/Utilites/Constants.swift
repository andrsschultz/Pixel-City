//
//  Constants.swift
//  PixelCity
//
//  Created by Andreas Schultz on 22.12.18.
//  Copyright © 2018 Andreas Schultz. All rights reserved.
//

import Foundation


let apiKey = "b4234eb9367dbbef3dfe3488e4e9cec6"

func flickrURL(forAPIKey key: String, withAnnotation annotation: DropablePIn, andNumberOfPhotos number: Int) -> String {
    let url = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(key)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=km&per_page=\(number)&format=json&nojsoncallback=1"
    return url
}
