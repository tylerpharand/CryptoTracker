//
//  Item.swift
//  CryptoTracker
//
//  Created by Tyler Pharand on 2018-11-15.
//  Copyright © 2018 Tyler Pharand. All rights reserved.
//

import UIKit


class item : UIView {
    var symbol : String
    var price: Float = 0.0
    var chart = chartView()
    var priceLabel : UILabel = UILabel()
    let iconGlow: CAGradientLayer = CAGradientLayer()
    let chartGlow: CAGradientLayer = CAGradientLayer()
    var chartGlowColor = UIColor()
    
    init(frame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0), symbol: String) {
        self.symbol = symbol
        super.init(frame: frame)
        self.alpha = 0
        self.accessibilityIdentifier = symbol
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setPrice(price: Float) {
        self.price = price
        priceLabel.alpha = 0
        if price > 100{
            priceLabel.text = String(Int(round(price)))
        } else if price > 10 {
            priceLabel.text = String(round(price*100)/100)
        } else if price > 1 {
            priceLabel.text = String(round(price*1000)/1000)
        } else {
            priceLabel.text = String(price)
        }
        UIView.animate(withDuration: 1) {
            self.priceLabel.alpha = 1
        }
        
    }
    
    func destroy(){
        self.removeFromSuperview()
    }
    
    
    func initialize(){
        self.backgroundColor = UIColor(red:0.15, green:0.14, blue:0.20, alpha:1.0)
        self.layer.cornerRadius = 15
        self.layer.masksToBounds = true
        
        // Symbol Icon
        let icon = UIImage(named: "./images/icons/" + symbol + "-icon.png")!
        let iconImageView = UIImageView(image: icon)
        
        // Price Label
        priceLabel.font = UIFont(name: "AvenirNext-Medium", size: 25)
        priceLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        
        // Icon Glow Effect
        let ico_color = icon.getPixelColor(pos: CGPoint(x: 10, y: 74))
        iconGlow.colors = [ico_color.withAlphaComponent(0.3).cgColor, ico_color.withAlphaComponent(0.09).cgColor, ico_color.withAlphaComponent(0).cgColor]
        iconGlow.locations = [0.0, 0.25, 0.5]
        iconGlow.startPoint = CGPoint(x: 0.0, y: 0.0)
        iconGlow.endPoint = CGPoint(x: 1.0, y: 0.0)
        // Chart Glow Effect
        chartGlow.locations = [0.6, 1.0]
        chartGlow.startPoint = CGPoint(x: 0.0, y: 0.0)
        chartGlow.endPoint = CGPoint(x: 1.0, y: 0.0)
        
        // Layers
        self.layer.addSublayer(iconGlow)
        self.layer.addSublayer(chartGlow)
        self.addSubview(priceLabel)
        self.addSubview(iconImageView)
        chart.tag = 100
        self.addSubview(chart)
        
        // Cell Constraints
        let parentView : UIView = self.superview!
        self.translatesAutoresizingMaskIntoConstraints = false
        let leftConstraint = self.leadingAnchor.constraint(equalTo: parentView.leadingAnchor)
        let rightConstraint = self.trailingAnchor.constraint(equalTo: parentView.trailingAnchor)
        let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: item_height)
        
        // Icon Constraints
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        let iconLeftConstraint = NSLayoutConstraint(item: iconImageView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: icon_padding)
        let iconAspectRatio = NSLayoutConstraint(item: iconImageView, attribute: .height, relatedBy: .equal, toItem: iconImageView, attribute: .width, multiplier: 1, constant: 0)
        let iconTopConstraint = NSLayoutConstraint(item: iconImageView, attribute: .top, relatedBy: .equal, toItem: self, attribute:.top, multiplier: 1, constant: icon_padding)
        let iconBottomConstraint = NSLayoutConstraint(item: iconImageView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute:.bottom, multiplier: 1, constant: -icon_padding)
        
        // Price Label Constraints
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        let priceLeftConstraint = NSLayoutConstraint(item: priceLabel, attribute: .leading, relatedBy: .equal, toItem: iconImageView, attribute: .trailing, multiplier: 1, constant: icon_padding*1.5)
        let priceVerticalCenter = NSLayoutConstraint(item: priceLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        // Chart Constraints
        chart.initializeConstraints(parent: self)
        
        NSLayoutConstraint.activate([leftConstraint, rightConstraint, heightConstraint, iconLeftConstraint, iconTopConstraint, iconBottomConstraint, iconAspectRatio, priceLeftConstraint, priceVerticalCenter])
    }
    
    func refreshData(currency : String, period: String){
        var fetch_result : [[Any]] = [[]]
        var limit : Int = 1
        var dailyInterval : Bool = false //dayInterval or hourlyInterval
        var apiPath : String
        var aggregation : Int = 1
        
        //        modify "limit" here using cases. Add additional parameter to switch between hourly and daily
        switch period {
        case "12 Hour":
            limit = 12
            dailyInterval = false
        case "24 Hour":
            limit = 24
            dailyInterval = false
        case "7 Day":
            limit = 28
            aggregation = 6
            dailyInterval = false
        case "1 Month":
            limit = 30
            dailyInterval = true
        case "6 Month":
            limit = 30
            aggregation = 2
            dailyInterval = true
        case "YTD":
            // function of current data ... simply calculate required scale + aggregation interval
            print("Implement YTD...")
            limit = 1
            aggregation = 1
            dailyInterval = true
        case "1 Year":
            limit = 30
            aggregation = 12
            dailyInterval = true
        case "2 Year":
            limit = 15
            aggregation = 24
            dailyInterval = true
        case "All":
            // probably use a different API command
            print("Implement All...")
            limit = 1
            aggregation = 1
            dailyInterval = true
        default:
            print("Default Case")
            limit = 30
            dailyInterval = true
        }
        
        if dailyInterval {
            apiPath = "https://min-api.cryptocompare.com/data/histoday?fsym="
        } else {
            apiPath = "https://min-api.cryptocompare.com/data/histohour?fsym="
        }
        
        let url = URL(string: apiPath + symbol + "&tsym="+currency+"&limit=" + String(limit)+"&aggregate=" + String(aggregation))!
        
        fetchData(url: url, completion: { (result) -> Void in
            fetch_result = result //Assign the result to the variable
            DispatchQueue.main.async {
                if let viewWithTag = self.viewWithTag(100) {
                    viewWithTag.removeFromSuperview()
                }
                
                let OHLCData = getOHLC(data: fetch_result)
                let percentChange = Float(OHLCData.close/OHLCData.open - 1.0)
                
                if percentChange < 0 {
                    self.chartGlowColor = UIColor(red:0.29, green:0.11, blue:0.20, alpha:1.0)
                    self.chartGlow.colors = [self.chartGlowColor.withAlphaComponent(0).cgColor, self.chartGlowColor.withAlphaComponent(0.7).cgColor]
                } else {
                    self.chartGlowColor = UIColor(red:0.18, green:0.15, blue:0.35, alpha:1.0)
                    self.chartGlow.colors = [self.chartGlowColor.withAlphaComponent(0).cgColor, self.chartGlowColor.withAlphaComponent(0.9).cgColor]
                }
                
                self.setPrice(price: Float(OHLCData.close))
                self.chart = chartView()
                //                self.chart.alpha = 0
                self.chart.tag = 100
                self.addSubview(self.chart)
                self.chart.initializeConstraints(parent: self)
                self.chart.generateChart(data: fetch_result, OHLCData: OHLCData, smooth: true, preview: true)
                UIView.animate(withDuration: 1) {
                    self.alpha = 1
                }
            }
        })
    }
    
    
    override func layoutSubviews() {
        iconGlow.frame = self.bounds
        chartGlow.frame = self.bounds
    }
}
