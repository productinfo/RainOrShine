//
//  LocationAPIService.swift
//  RainOrShine
//
//  Created by Josh Henry on 10/28/16.
//  Copyright © 2016 Big Smash Software. All rights reserved.
//

import Foundation
import GooglePlaces
import SwiftyJSON

class LocationAPIService {
    var keys: NSDictionary = NSDictionary()

    var placesClient: GMSPlacesClient? = GMSPlacesClient.shared()
    var currentPlace: GMSPlace?
    
    var firstGeneralLocalePhotoMetaData: GMSPlacePhotoMetadata?
    var firstGeneralLocalePhoto: UIImage?

    
    func setAPIKeys() {
        guard let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist") else {return}
        keys = NSDictionary(contentsOfFile: path)!
    }
    
    
    func getCurrentLocation(completion: @escaping (_ result: Bool)->()) {
        var placeFindComplete: Bool = false
        
        placesClient?.currentPlace(callback: { (placeLikelihoods, error) -> Void in
            guard error == nil else {
                print("Current Place error: \(error!.localizedDescription)")
                completion(true)
                return
            }
            
            if let placeLikelihoods = placeLikelihoods {
                let place = placeLikelihoods.likelihoods.first?.place
                self.currentPlace = place
                placeFindComplete = true
                completion(true)
            }
        })
        if (placeFindComplete == false) {
            completion(false)
        }
    }
    
    
    func setPhotoOfGeneralLocale(size: CGSize, scale: CGFloat, completion: @escaping (_ result: Bool) ->()) {
        print("In function getPhotoOfGeneralLocale...")

        //let setPhotoComplete: Bool = false
        let generalLocaleString: String = getGeneralLocaleString()
        
        //Get the place ID of the general area so that we can grab an image of the city
        let placeIDOfGeneralArea: String? = getPlaceIDOfGeneralLocale(generalLocaleQueryString: generalLocaleString)
        if (placeIDOfGeneralArea != nil) {
            setPhotoMetaDataForCurrentLocation() { (photoMetaDataFound) -> () in
                if (photoMetaDataFound == true) {
                    self.setImageForMetadata(size: size, scale: scale) { (imageFound) -> () in
                        
                        if (imageFound == true) {
                            completion(true)
                        }
                        else {
                            completion(false)
                        }
                    }
                }
            }
            /*if (setPhotoComplete == false) {
                completion(false)
            }*/
        }
        else {
            print("Not loading a photo since place ID of general area was nil...")
            completion(true)
        }
    }
    
    
    //This method builds a string of the general locality of the place
    func getGeneralLocaleString() -> String {
        print("In function getGeneralLocaleString...")

        var queryString: String = String()
        
        for addressComponent in (currentPlace?.addressComponents)! {
            print(addressComponent.type)
            print(addressComponent.name)
            
            switch (addressComponent.type) {
                //case "sublocality_level_1":
            //    queryString += thisType.name
            case "locality":
                queryString += addressComponent.name
            case "administrative_area_level_1":
                queryString += "+" + addressComponent.name
            case "country":
                queryString += "+" + addressComponent.name
            default:
                break
            }
        }
        
        //Replace any spaces in the URL with "+"
        queryString = queryString.replacingOccurrences(of: " ", with: "+")
        
        return queryString
    }
    
    
    //This method takes a general area string (such as "Atlanta, Georgia, United States") and gets a place ID for that area
    func getPlaceIDOfGeneralLocale(generalLocaleQueryString: String) -> String? {
        print("In function getPlaceIDOfGeneralLocale...")

        var placeID: String?
        var completionHandlerCodeComplete: Bool = false
        
        let placeTextSearchURL: String = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=" + generalLocaleQueryString + "&key=" + (keys["GooglePlacesAPIKeyWeb"] as! String)
        print("placeTextSearchURL is \(placeTextSearchURL)")
        
        let session = URLSession.shared
        /*guard let url = URL(string: placeTextSearchURL) else {
         print("OH NOOOO")
         return nil
         }*/
        //I NEED TO CHECK HERE THAT THERE IS NO ERROR.
        //PREVIOUSLY IT CRASHED IF THERE WERE SPACES IN THE URL.  I NEED TO FIND OUT HOW ELSE IT COULD CRASH
        let url = URL(string: placeTextSearchURL)!
        
        // Make call. Handle it in a completion handler.
        session.dataTask(with: url as URL, completionHandler: { ( data: Data?, response: URLResponse?, error: Error?) -> Void in
            //Ensure the  response isn't an error
            guard let thisURLResponse = response as? HTTPURLResponse,
                thisURLResponse.statusCode == 200 else {
                    print("Not a 200 (successful) response")
                    return
            }
            let json = JSON(data: data!)
            placeID = json["results"][0]["place_id"].string
            
            completionHandlerCodeComplete = true
        }).resume()
        
        while (completionHandlerCodeComplete == false) {
            print("Waiting on the photo reference to retrieve...")
        }
        return placeID
    }
    
    
    //Retrieve photo metadata for place
    func setPhotoMetaDataForCurrentLocation(completion: @escaping (_ result: Bool)->()) {
        print("In function setPhotoMetaDataForCurrentLocation...")

        var photoMetaDataFindComplete: Bool = false
        
        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: (currentPlace?.placeID)!) { (photos, error) -> Void in
            if let error = error {
                print("Error loading photo from Google API: \(error.localizedDescription)")
                completion(true)
                return
            } else {
                if let firstPhotoMetadata = photos?.results.first {
                    self.firstGeneralLocalePhotoMetaData = firstPhotoMetadata
                    photoMetaDataFindComplete = true
                    completion(true)
                }
                else {
                    print("No photos found. Resetting image view to blank...")
                    self.firstGeneralLocalePhotoMetaData = nil
                    completion(true)
                }
            }
        }
        if (photoMetaDataFindComplete == false) {
            completion(false)
        }
    }
    
    
    //Retrieve image based on place metadata
    func setImageForMetadata(size: CGSize, scale: CGFloat, completion: @escaping (_ result: Bool) ->()) {
        print("In function setImageForMetadata...")

        var imageFindComplete: Bool = false
        
        GMSPlacesClient.shared().loadPlacePhoto(firstGeneralLocalePhotoMetaData!, constrainedTo: size, scale: scale) { (photo, error) -> Void in
            if let error = error {
                print("Error loading image for metadata: \(error.localizedDescription)")
                completion(true)
                return
            } else {
                //self.locationImageView.image = photo
                //self.attributionTextView.attributedText = photoMetadata.attributions
                self.firstGeneralLocalePhoto = photo
                print("self.firstGeneralLocalePhoto is \(self.firstGeneralLocalePhoto)")
                imageFindComplete = true
                completion(true)
            }
        }
        if (imageFindComplete == false) {
            completion(false)
        }
    }
}
