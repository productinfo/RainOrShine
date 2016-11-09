//
//  FutureWeatherView.swift
//  RainOrShine
//
//  Created by Josh Henry on 11/8/16.
//  Copyright © 2016 Big Smash Software. All rights reserved.
//

import UIKit

class FutureWeatherView: UIView {

    @IBOutlet var view: UIView!
    @IBOutlet weak var testLabel: UILabel!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "FutureWeatherView", bundle: nil).instantiate(withOwner: self, options: nil)
        
        setViewStyle()
        
        addSubview(view)
    }
    
    private func setViewStyle() {
        self.testLabel.text = "This works"
    }

}