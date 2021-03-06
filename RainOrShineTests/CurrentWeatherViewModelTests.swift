//
//  CurrentWeatherViewModelTests.swift
//  RainOrShine
//
//  Created by Josh Henry on 11/26/16.
//  Copyright © 2016 Big Smash Software. All rights reserved.
//

import XCTest
import ForecastIO

@testable import RainOrShine

class CurrentWeatherViewModelTests: XCTestCase {
        
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    //Test retrieving the current forecast with a mock location and make sure it returns a value.
    //The dummy value is the coordinates of Yobe, Nigeria
    func testCurrentWeatherViewModelUpdateForecast() {
        let jsonString: String = "{\"latitude\":12,\"longitude\":12,\"timezone\":\"Etc/GMT\",\"offset\":0}"
        
        guard let jsonDictionary: NSDictionary = jsonString.convertStringToDictionary() as? NSDictionary else {
            XCTAssert(false, "The JSON dictionary was nil.")
            return
        }
        
        let forecast = Forecast(fromJSON: jsonDictionary)
        let currentWeatherViewModel: CurrentWeatherViewModel = CurrentWeatherViewModel(forecast: forecast)
        
        currentWeatherViewModel.updateForecast(newForecast: forecast)
        
        XCTAssertEqual(currentWeatherViewModel.currentForecast.value?.latitude, forecast.latitude, "currentWeatherViewModel.updateForecast did not correctly update currentWeatherViewModel.currentForecast...")
    }
    
}
