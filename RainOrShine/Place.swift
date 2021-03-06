//
//  Place.swift
//  RainOrShine
//
//  Created by Josh Henry on 10/30/16.
//  Copyright © 2016 Big Smash Software. All rights reserved.
//

import Foundation
import GooglePlaces

//The place class is used to store a Google Place along with place image information.
class Place {
    // MARK: - Properties
    public var gmsPlace: GMSPlace?
    public lazy var photoMetaDataArray: [GMSPlacePhotoMetadata?] = [GMSPlacePhotoMetadata?]()
    public lazy var photoArray: [UIImage?] = [UIImage?]()
    
    // MARK: - Initializers
    convenience init() {
        self.init(place: nil)
    }
    
    init(place: GMSPlace?) {
        self.gmsPlace = place
    }
    
    
    // MARK: - Methods
    //This method builds a string of the general locality of the place, which will be used to query a photo of the general locale
    public func getGeneralLocaleString() -> String {
        var queryString: String = ""
        var isFirstItemInQueryString: Bool = true
        var cityNameAlreadyFound: Bool = false
        var naturalFeatureName: String?
        
        guard let addresscomponents = self.gmsPlace?.addressComponents else {
            return ""
        }

        for addressComponent in addresscomponents {
            switch (addressComponent.type) {
            //Prefer city, then county, then state, etc.
            case "locality", "administrative_area_level_3", "administrative_area_level_2":
                if (!cityNameAlreadyFound) {
                    if (isFirstItemInQueryString) {
                        queryString += addressComponent.name
                        isFirstItemInQueryString = false
                    }
                    else {
                        queryString += "+" + addressComponent.name
                    }
                    
                    cityNameAlreadyFound = true
                }
            case "administrative_area_level_1", "country":
                if (isFirstItemInQueryString) {
                    queryString += addressComponent.name
                    isFirstItemInQueryString = false
                }
                else {
                    queryString += "+" + addressComponent.name
                }
            case "natural_feature":
                naturalFeatureName = addressComponent.name
            default:
                break
            }
        }
        
        //If we don't get any city, state, country name, but we DO have a natural feature, make the query string the natural feature name.  Doesn't always return an image but increases the chances.
        if (queryString == "" &&
            naturalFeatureName != nil) {
            queryString += naturalFeatureName!
        }
        
        //Replace any spaces in the URL with "+"
        queryString = queryString.replacingOccurrences(of: " ", with: "+")
        return queryString
    }
}
