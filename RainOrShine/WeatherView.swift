//
//  WeatherView.swift
//  RainOrShine
//
//  Created by Josh Henry on 10/31/16.
//  Copyright © 2016 Big Smash Software. All rights reserved.
//

import UIKit

class WeatherView: UIVisualEffectView {
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var weatherConditionView: SKYIconView!

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "WeatherView", bundle: nil).instantiate(withOwner: self, options: nil)
        setViewStyle()
        addSubview(view)
    }
    

    private func setViewStyle() {
        self.setViewEdges()
        
        self.temperatureLabel.textColor = UIColor.white
        self.summaryLabel.textColor = UIColor.white
        
        weatherConditionView.backgroundColor = UIColor.clear
        weatherConditionView.setColor = UIColor.white
    }
}
