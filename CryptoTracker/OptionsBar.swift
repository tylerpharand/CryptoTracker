//
//  OptionsBar.swift
//  CryptoTracker
//
//  Created by Tyler Pharand on 2018-11-15.
//  Copyright © 2018 Tyler Pharand. All rights reserved.
//

import UIKit

class optionsBar : UIView {
    let headerLabel : UILabel = UILabel()
    let optionsBarPadding : CGFloat = 4.0
    var currencyValue : String = ""
    var periodValue : String = ""
    var refreshFunction : (()->())? = nil
    
    init(frame: CGRect, currency: String, period: String){
        self.currencyValue = currency
        self.periodValue = period
        super.init(frame: frame)
        let currency = scrollButton(frame: CGRect(x: 150, y: 0, width: 60, height: 26), options: ["USD", "CAD", "EUR"], parent: self, id: "currency")
        let period = scrollButton(frame: CGRect(x: 20, y: 0, width: 75, height: 26), options: ["12 Hour", "24 Hour", "7 Day", "1 Month", "6 Month", "YTD", "1 Year", "2 Year", "All"], parent: self, id: "period")
        
        headerLabel.text = "Watchlist"
        headerLabel.textColor = UIColor(red:0.93, green:0.91, blue:1.00, alpha:1.0)
        headerLabel.font = UIFont(name: "AvenirNext-Medium", size: 18)
        headerLabel.frame = self.frame
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(blurEffectView)
        
        self.addSubview(currency)
        self.addSubview(period)
        self.addSubview(headerLabel)
        
        period.translatesAutoresizingMaskIntoConstraints = false
        currency.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let A = NSLayoutConstraint(item: period, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: -stackPadding)
        let B = NSLayoutConstraint(item: period, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: period.frame.height)
        let C = NSLayoutConstraint(item: period, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: period.frame.width)
        let D = NSLayoutConstraint(item: period, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        let E = NSLayoutConstraint(item: currency, attribute: .trailing, relatedBy: .equal, toItem: period, attribute: .leading, multiplier: 1.0, constant: -optionsBarPadding)
        let F = NSLayoutConstraint(item: currency, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: currency.frame.height)
        let G = NSLayoutConstraint(item: currency, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: currency.frame.width)
        let H = NSLayoutConstraint(item: currency, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        let I = NSLayoutConstraint(item: headerLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: stackPadding)
        let J = NSLayoutConstraint(item: headerLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: currency.frame.height)
        let K = NSLayoutConstraint(item: currency, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: currency.frame.width)
        let L = NSLayoutConstraint(item: headerLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activate([A, B, C, D, E, F, G, H, I, J, K, L])
        
        period.setScrollPosition(option: periodValue)
        currency.setScrollPosition(option: currencyValue)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updatedValue(sender: scrollButton!, value: String) {
        let id : String = sender.accessibilityIdentifier!
        
        // On value change in either period or currency
        if id == "period" {
            if value != self.periodValue{
                self.periodValue = value
                self.refreshFunction!()
            }
            
        } else if id == "currency" {
            if value != self.currencyValue{
                self.currencyValue = value
                self.refreshFunction!()
            }
        }
    }
}
