//
//  ViewController.swift
//  RainOrShine
//
//  Created by Josh Henry on 10/26/16.
//  Copyright © 2016 Big Smash Software. All rights reserved.
//

import UIKit
import CoreLocation

class WeatherViewController: UIViewController , CLLocationManagerDelegate, UISearchBarDelegate {
    // MARK: - Properties
    
    // MARK: Type Aliases
    typealias ScreenSize = CGSize
    
    // MARK: Views
    @IBOutlet weak var locationImageView: LocationImageView!
    @IBOutlet weak var currentWeatherView: CurrentWeatherView!    
    @IBOutlet weak var locationView: LocationView!
    public var locationSearchView: LocationSearchView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var photoDetailView: PhotoDetailView!
    @IBOutlet weak var futureWeatherView: FutureWeatherView!
    
    // MARK: Constants
    
    private var screenWidthAndHeight: ScreenSize {
        if (UIScreen.main.bounds.width < UIScreen.main.bounds.height) {
            return ScreenSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
        else {
            return ScreenSize(width: UIScreen.main.bounds.height, height: UIScreen.main.bounds.width)
        }
    }
    
    let locationManager = CLLocationManager()
    
    // MARK: Variables
    var isStatusBarVisible: Bool = true
    override var prefersStatusBarHidden: Bool {
        return !isStatusBarVisible
    }
    var gpsConsecutiveSignalsReceived: Int = 0
    
    
    // MARK: - Methods
    //Initialize values for the first time
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setAllAPIKeys()
        configureLocationManager()
        WeatherAPIService.setWeatherClient()
        createObservers()
        createLocationSearchElements()
        
        setNightStandMode()
    }
    
    
    // Hide the navigation bar on the this view controller
    override func viewWillAppear(_ animated: Bool) {
        print("In func viewWillAppear...")
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        //Redraw the location search bar when coming back to this view controller from other view controllers.  User could have changed orientations since leaving this controller.
        resizeLocationSearchView(orientationAfterRotation: UIDevice.current.orientation)
    }
    
    
    // Show the navigation bar on other view controllers
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    
    //If the view's orientation changed, make sure that the location search bar is correctly aligned
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if (Rotation.allowed) {
            if (UIDevice.current.orientation.isLandscape ||
                UIDevice.current.orientation.isPortrait) {
                resizeLocationSearchView(orientationAfterRotation: UIDevice.current.orientation)
            }
        }
    }
    
    
    //Set all API keys for all APIs being used
    private func setAllAPIKeys() {
        LocationAPIService.setAPIKeys()
        WeatherAPIService.setAPIKeys()
    }
    
    
    //Set and configure the location manager
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy  = kCLLocationAccuracyKilometer
    }
    
    
    //Called every time a new gps signal is received
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        
        //Sometimes the first coordinates received from the GPS might be inaccurate or cached locations from previous location locks.
        //Wait for 5 GPS signals to be received before we have a semi reliable tracking.
        //ALSO, I NEED TO CACHE THE LAST FIVE LOCATIONS ACTUALLY USED.  MAKE SURE THE SIGNAL IS NOT REPORTING A PREVIOUS TRACKING AND IS GIVING FRESH, ACCURATE RESULTS
        gpsConsecutiveSignalsReceived += 1
        print("gpsConsecutiveSignalsReceived is \(gpsConsecutiveSignalsReceived)")
        if gpsConsecutiveSignalsReceived == 5 {
            self.updateLocation()
        }
    }
    
    
    //Handle location manager errors
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error - \(error)")
    }
    
    
    // MARK: Observers and Recognizers
    //Create and start all observers
    private func createObservers() {
        createTimeObserver()
        createGestureRecognizers()
        createBatteryStateObserver()
    }
    
    
    //Create a time observer to run every 10 minutes to refresh the weather forecast
    private func createTimeObserver() {
        Timer.scheduledTimer(timeInterval: 600.0, target: self, selector: #selector(self.timeIntervalReached), userInfo: nil, repeats: true)
    }
    
    
    //Create gesture recognizers for swiping left and right through location photos
    private func createGestureRecognizers() {
        //print("In func createGestureRecognizers...")        
        self.view.addGestureRecognizer(setTapRecognizer())
        locationImageView.addGestureRecognizer(setTapRecognizer())
        currentWeatherView.addGestureRecognizer(setTapRecognizer())
        locationView.addGestureRecognizer(setTapRecognizer())
        currentWeatherView.addGestureRecognizer(setTapRecognizer())
        futureWeatherView.addGestureRecognizer(setTapRecognizer())
        photoDetailView.addGestureRecognizer(setTapRecognizer())
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture(_:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture(_:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)
    }
    
    
    //Create the tap recognizer to detect if the screen was tapped once, which will show/hide futureWeatherView
    private func setTapRecognizer() -> UITapGestureRecognizer {
        return UITapGestureRecognizer(target: self, action: #selector (self.viewTapped (_:)))
    }
    
    
    //Begin monitoring charging state.
    private func createBatteryStateObserver() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.batteryStateDidChange), name: Notification.Name.UIDeviceBatteryStateDidChange, object: nil)
    }
    
    
    //If the battery state changes, turn on or off the screen lock accordingly
    dynamic func batteryStateDidChange(notification: NSNotification){
        setNightStandMode()
    }
    
    
    //This is called when the time observer's time has been reached.  It refreshes the weather.
    dynamic func timeIntervalReached() {
        //print("In func timeIntervalReached...")
        
        self.activityIndicator.startAnimating()
        
        loadNewPlaceWeather() { (isComplete) -> () in
            if (isComplete == true) {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    
    private func setNightStandMode() {
        //print("In setNightStand Mode...")

        if (UIDevice.current.batteryState == UIDeviceBatteryState.charging) {
            //Turn off the screen lock
            UIApplication.shared.isIdleTimerDisabled = true
        }
        else if (UIDevice.current.batteryState == UIDeviceBatteryState.unplugged) {
            //Turn on the screen lock
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    
    //If the user is searching, disable rotation until finished
    internal func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        //print("searchBarTextDidBeginEditing...")
        Rotation.allowed = false
    }
    
    
    //If the user is done searching, re-enable screen rotation
    internal func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        //print("searchBarTextDidEndEditing...")
        Rotation.allowed = true
    }
    
    
    //If the view was tapped, fade in or out the 5 day forecast
    internal func viewTapped(_ sender:UITapGestureRecognizer) {
        if (futureWeatherView.alpha == 0) {
            futureWeatherView.fadeIn(withDuration: 0.75, finalAlpha: 0.8)
        }
        else {
            futureWeatherView.fadeOut()
        }
    }
    
    
    //If the user swipes right or left, adjust viewmodel.updatePlaceImageIndex accordingly
    dynamic func respondToSwipeGesture(_ gesture: UIGestureRecognizer) {
        //print("In func respondToSwipeGesture")
        
        guard let swipeGesture = gesture as? UISwipeGestureRecognizer else {return}
        
        //If there are photos to swipe through, then allow swiping
        if ((LocationAPIService.currentPlace?.generalLocalePhotoArray.count)! > 0) {
            let currentPage = self.photoDetailView.advancePage(direction: swipeGesture.direction)
            locationImageView.viewModel?.updatePlaceImageIndex(newPlaceImageIndex: currentPage)
        }
    }
    
    
    //Initialize and configure the Google Places search controllers
    private func createLocationSearchElements() {
        locationSearchView = LocationSearchView(withOrientation: UIDevice.current.orientation, screenWidthAndHeight: screenWidthAndHeight)
        locationSearchView.resultsViewController?.delegate = self
        locationSearchView.searchController?.searchBar.delegate = self
        self.view.addSubview(locationSearchView)
        
        locationSearchView.searchController?.hidesNavigationBarDuringPresentation = false
        
        //When UISearchController presents the results view, present it in this view controller, not one further up the chain.
        self.definesPresentationContext = true
    }
    
    
    //Resize the location search view with the current screen dimensions
    internal func resizeLocationSearchView(orientationAfterRotation: UIDeviceOrientation) {
        //print("In resizeLocationSearchView...")
        
        if orientationAfterRotation.isPortrait {
            //print("Switching to portrait...")
            
            showStatusBar(enabled: true)
            
            locationSearchView.frame = CGRect(x: 0, y: 20, width: screenWidthAndHeight.width, height: 45)
            locationSearchView.searchController?.view.frame = CGRect(x: 0, y: 0, width: screenWidthAndHeight.width, height: screenWidthAndHeight.height)
        }
        else if orientationAfterRotation.isLandscape {
            //print("Switching to landscape...")
            
            showStatusBar(enabled: false)
            
            locationSearchView.frame = CGRect(x: 0, y: 0, width: screenWidthAndHeight.height, height: 45)
        }
        locationSearchView.searchController?.searchBar.sizeToFit()
    }
    
    
    //Show or hide the status bar
    private func showStatusBar(enabled: Bool) {
        isStatusBarVisible = enabled
        setNeedsStatusBarAppearanceUpdate()
    }
    
    
    //Make all subviews' alpha 0
    internal func makeSubViewsInvisible() {
        currentWeatherView.alpha = 0
        locationView.alpha = 0
        photoDetailView.alpha = 0
        futureWeatherView.alpha = 0
    }
   
    
    //If the GPS button is tapped, show weather for user's current location
    @IBAction func currentLocationButtonTapped(_ sender: Any) {
        activityIndicator.startAnimating()
        
        //If GPS is turned off, show an error message
        if (!CLLocationManager.locationServicesEnabled()) {
            let gpsAlert = UIAlertController(title: "GPS Not Enabled", message: "Location services are not enabled on this device.  Go to Settings -> Privacy -> Location Services and enable location services.", preferredStyle: .alert)
            gpsAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(gpsAlert, animated: true, completion: nil)
            
            return
        }
        else if (CLLocationManager.authorizationStatus() != CLAuthorizationStatus.authorizedWhenInUse) {
            let gpsAlert = UIAlertController(title: "GPS Not Enabled", message: "GPS is not enabled for this app.  Go to Settings -> Privacy -> Location Services and allow the app to utilize GPS.", preferredStyle: .alert)
            gpsAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(gpsAlert, animated: true, completion: nil)
            
            return
        }
        
        //Reset the gps signals received counter
        gpsConsecutiveSignalsReceived = 0
        
        //Start updating the location and location manager's didUpdateLocation will take over from there
        locationManager.startUpdatingLocation()
    }
    
    
    //This method updates the location by running setCurrentExactPlace and setGeneralLocalePlace.  It is only called when the user taps the GPS current location button.
    func updateLocation() {
        makeSubViewsInvisible()
        
        LocationAPIService.setCurrentExactPlace() { (isLocationFound, locationPlace) -> () in
            if (isLocationFound) {
                self.photoDetailView.viewModel?.updatePlace(newPlace: locationPlace)
                
                LocationAPIService.currentPlace = locationPlace
                
                //print("FOUND EXACT PLACE \(LocationAPIService.currentPlace?.gmsPlace?.formattedAddress)")
                //Set the general locale of the place (better for pictures and displaying user's location than exact addresses)
                LocationAPIService.setGeneralLocalePlace() { (isGeneralLocaleFound, generalLocalePlace) -> () in
                    if (isGeneralLocaleFound) {
                        
                        self.locationView.viewModel?.updateGeneralLocalePlace(newPlace: generalLocalePlace)
                        
                        LocationAPIService.generalLocalePlace = generalLocalePlace
                        
                        //print("FOUND GENERAL PLACE \(LocationAPIService.generalLocalePlace?.gmsPlace?.formattedAddress)")
                        
                        self.changePlaceShown()
                    }
                }
            }
        }
    }
    
    
    //Change the place that will be displayed in this view controller (including new place photos and weather forecast)
    internal func changePlaceShown() {
        //print("In func changePlaceShown...")
        
        print("PLACE IDS")
        print(LocationAPIService.currentPlace?.gmsPlace?.placeID)
        print(LocationAPIService.generalLocalePlace?.gmsPlace?.placeID)
        
        print(LocationAPIService.currentPlace?.gmsPlace?.formattedAddress)
        print(LocationAPIService.generalLocalePlace?.gmsPlace?.formattedAddress)

        var changePlaceCompletionFlags = (photosComplete: false, weatherComplete: false)
        
        resetValuesForNewPlace()
        
        //Run both functions.  If both are complete, stop the activity indicator
        loadNewPlacePhotos() { (isComplete) -> () in
            if (isComplete == true) {
                changePlaceCompletionFlags.photosComplete = true
                if (changePlaceCompletionFlags.weatherComplete == true) {
                    DispatchQueue.main.async {
                        self.locationManager.stopUpdatingLocation()
                        self.activityIndicator.stopAnimating()
                    }
                }
            }
        }
        loadNewPlaceWeather() { (isComplete) -> () in
            if (isComplete == true) {
                changePlaceCompletionFlags.weatherComplete = true
                if (changePlaceCompletionFlags.photosComplete == true) {
                    DispatchQueue.main.async {
                        self.locationManager.stopUpdatingLocation()
                        self.activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
    
    
    //This function is called by changePlaceShown and is run right before acquiring new values for a new place.
    //It resets some values to create a clean slate.
    private func resetValuesForNewPlace() {
        photoDetailView.viewModel?.updatePlaceImageIndex(newPlaceImageIndex: nil)
        locationImageView.viewModel?.updatePlaceImageIndex(newPlaceImageIndex: nil)
        
        LocationAPIService.currentPlace?.generalLocalePhotoArray.removeAll(keepingCapacity: false)
        LocationAPIService.currentPlace?.generalLocalePhotoMetaDataArray.removeAll(keepingCapacity: false)
        
        WeatherAPIService.forecastDayDataPointArray.removeAll(keepingCapacity: false)
    }
    
    
    //Display new place photos when a new place has been chosen
    private func loadNewPlacePhotos(completion: @escaping (_ result: Bool) ->()) {
        LocationAPIService.setPhotosOfGeneralLocale(size: self.locationImageView.bounds.size, scale: self.locationImageView.window!.screen.scale) { (isImageSet) -> () in
            if (isImageSet == true) {
                //Reset image page control to the beginning
                self.photoDetailView.viewModel?.updatePlaceImageIndex(newPlaceImageIndex: 0)
                self.locationImageView.viewModel?.updatePlaceImageIndex(newPlaceImageIndex: 0)

                //Adjust the page control according to the newly loaded place (if the place is not nil)
                guard let currentPlace = LocationAPIService.currentPlace else {return}
                
                if (currentPlace.generalLocalePhotoArray.count == 0) {
                    self.photoDetailView.photoPageControl.isHidden = true
                    self.photoDetailView.photoPageControl.numberOfPages = 0
                }
                else {
                    self.photoDetailView.photoPageControl.numberOfPages = currentPlace.generalLocalePhotoArray.count
                    self.photoDetailView.photoPageControl.isHidden = false
                }
                completion(true)
            }
        }
    }
    
    
    //Display weather info when a new place has been chosen. Get the weather forecast.
    private func loadNewPlaceWeather(completion: @escaping (_ result: Bool) ->()) {
        guard let currentPlace = LocationAPIService.currentPlace else {return}
        guard let currentGMSPlace = currentPlace.gmsPlace else {return}
        
        WeatherAPIService.setCurrentWeatherForecast(latitude: currentGMSPlace.coordinate.latitude, longitude: currentGMSPlace.coordinate.longitude) { (forecastRetrieved) -> () in
            if (forecastRetrieved) {
                self.currentWeatherView.viewModel?.updateForecast(newForecast: WeatherAPIService.currentWeatherForecast)
                self.futureWeatherView.viewModel?.updateForecast(newForecast: WeatherAPIService.currentWeatherForecast)
                
                completion(true)
            }
        }
    }
}
