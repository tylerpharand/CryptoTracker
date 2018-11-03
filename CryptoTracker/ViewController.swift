//
//  ViewController.swift
//  CrytoTracker
//
//  Created by Tyler Pharand on 2018-11-02.
//  Copyright © 2018 Tyler Pharand. All rights reserved.
//

import UIKit

let item_height : CGFloat = 65
let icon_padding : CGFloat = 10
let stackPadding : CGFloat = 10


extension UIImage {
    func getPixelColor(pos: CGPoint) -> UIColor {
        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

func fetchData(url : URL, completion:@escaping (_ resultImage: [[Any]]) -> Void){
    var outputData : [[Any]] = []
    
    let request = URLRequest(url: url)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            // check for fundamental networking error
            print("error=\(error)")
            return
        }
        
        if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
            // check for http errors
            print("statusCode should be 200, but is \(httpStatus.statusCode)")
            print("response = \(response)")
        }
        
        let jsonString = try? JSONSerialization.jsonObject(with: data, options: [])
        //        var epoch : Int
        //        var timestamp : NSDate
        
        if let jsonResponse = jsonString as? [String: Any] {
            if let priceInfo = jsonResponse["Data"] as? [NSDictionary] {
                for i in priceInfo {
                    //                    print(i["close"]!)
                    //                    epoch = i["time"] as! Int
                    //                    timestamp = NSDate(timeIntervalSince1970: TimeInterval(epoch)) // 4 hrs ahead of Toronto
                    outputData.append([i["time"] as! Int, i["close"] as! Double])
                }
            }
            completion(outputData)
        }
    }
    task.resume()
}

func getOHLC(data: [[Any]]) -> OHLC {
    let open : Double = data[0][1] as! Double
    let close : Double = data.last![1] as! Double
    
    var high : Double = data[0][1] as! Double
    var low : Double = data[0][1] as! Double
    var mean : Double = 0.0
    var elementValue : Double
    
    for element in data{
        elementValue = element[1] as! Double
        mean += elementValue
        if elementValue > high {
            high = elementValue
        }
        if low > elementValue {
            low =  elementValue
        }
    }
    
    mean = mean/Double(data.count)
    
    return OHLC(open: open, high: high, low: low, close: close, mean: mean)
}

struct OHLC {
    let open : Double
    let high : Double
    let low : Double
    let close : Double
    let mean : Double
}

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

func MidPoint(start: CGPoint, end: CGPoint ) -> CGPoint {
    return CGPoint( x: ( start.x + end.x ) / 2, y: ( start.y + end.y ) / 2 )
}

class chartView : UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func generateChart(data: [[Any]], OHLCData: OHLC, smooth: Bool, preview: Bool){
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        let percentChange = Float(OHLCData.close/OHLCData.open - 1.0)
        let highLowChange = Float(OHLCData.high/OHLCData.low - 1.0)
        
        let chartHeight: Float = Float(self.frame.height)
        let chartYScale : Float = chartScaleRatio(change: highLowChange)
        let chartYOffset : Float = chartHeight/2.0 - chartHeight*chartYScale/2.0
        
        let interval : Float = Float(self.frame.width)/Float(data.count-1) // time interval
        let normalizer : Float = Float(OHLCData.high - OHLCData.low)
        var timeAxis : Float = 0
        var priceAxis: Float
        var chartDataScaled : [CGPoint] = []
        
        for element in data{
            priceAxis = (1.0 - (Float(element[1] as! Double - OHLCData.low))/normalizer)*chartYScale*chartHeight + chartYOffset
            chartDataScaled.append(CGPoint(x: Int(timeAxis), y: Int(priceAxis)))
            timeAxis += interval
        }
        
        let path = UIBezierPath()
        var start : CGPoint = chartDataScaled[0]
        var prev : CGPoint = chartDataScaled[0]
        
        if smooth {
            for (index, point) in chartDataScaled.enumerated(){
                // Catmull-Rom:
                // https://stackoverflow.com/questions/34579957/drawing-class-drawing-straight-lines-instead-of-curved-lines
                switch index {
                case  0:
                    path.move(to: point)
                    start = point
                case  1:
                    path.addLine(to: MidPoint(start: start, end: point))
                    prev = point
                default:
                    path.addQuadCurve( to: MidPoint(start: prev, end: point ), controlPoint: prev )
                    prev = point
                }
            }
            path.addLine(to: chartDataScaled.last!)
        } else {
            for (index, point) in chartDataScaled.enumerated(){
                if index == 0{
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
        
        let y = Int ((1.0 - (Float(OHLCData.close - OHLCData.low))/normalizer)*chartYScale*chartHeight + chartYOffset)
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: Int(self.frame.width), y: y), radius: CGFloat(3), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        
        //Draw Line
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = nil
        shapeLayer.lineJoin = kCALineJoinRound
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.lineWidth = 2.5
        
        let priceMarker = CAShapeLayer()
        priceMarker.path = circlePath.cgPath
        
        
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        if percentChange < 0 {
            // Red line
            gradient.colors = [UIColor(red:1.00, green:0.48, blue:0.37, alpha:1.0).cgColor,
                               UIColor(red:1.00, green:0.24, blue:0.62, alpha:1.0).cgColor]
            priceMarker.fillColor = UIColor(red:1.00, green:0.44, blue:0.72, alpha:1.0).cgColor
            
        } else {
            // Purple line
            gradient.colors = [UIColor(red:0.00, green:0.71, blue:1.00, alpha:1.0).cgColor,
                               UIColor(red:0.75, green:0.35, blue:1.00, alpha:1.0).cgColor]
            priceMarker.fillColor = UIColor(red:0.85, green:0.68, blue:1.00, alpha:1.0).cgColor
            
        }
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        gradient.mask = shapeLayer
        self.layer.addSublayer(gradient)
        self.layer.addSublayer(priceMarker)
        
        if preview {
            let percentChangeLabel = UILabel()
            let arrowIcon : UIImage
            
            percentChangeLabel.textAlignment = NSTextAlignment.left
            percentChangeLabel.font = UIFont(name: "AvenirNext-Medium", size: 12)
            percentChangeLabel.frame = CGRect(x: 0, y: 0, width: 150, height: 12)
            percentChangeLabel.frame.origin = CGPoint(x: Int(self.frame.width + icon_padding*1.7), y: y - Int(percentChangeLabel.frame.height/2))
            percentChangeLabel.clipsToBounds = false
            percentChangeLabel.adjustsFontSizeToFitWidth = false
            
            if abs(percentChange) < 0.01 {
                percentChangeLabel.text = String(abs(round(percentChange*1000)/10)) + "%"
            } else {
                percentChangeLabel.text = String(Int(abs(round(percentChange*100)))) + "%"
            }
            
            if percentChange < 0 {
                percentChangeLabel.textColor = UIColor(red:1.00, green:0.58, blue:0.79, alpha:1.0)
                arrowIcon = UIImage(named: "./images/misc/" + "arrow_down.png")!
            } else {
                percentChangeLabel.textColor = UIColor(red:0.75, green:0.68, blue:1.00, alpha:1.0)
                arrowIcon = UIImage(named: "./images/misc/" + "arrow_up.png")!
            }
            
            let arrowIconImageView = UIImageView(image: arrowIcon)
            arrowIconImageView.frame = CGRect(x: 0, y: 0, width: 8, height: percentChangeLabel.frame.height)
            arrowIconImageView.frame.origin = CGPoint(x: Int(self.frame.width + icon_padding*0.75), y: y - Int(percentChangeLabel.frame.height/2))
            
            self.addSubview(percentChangeLabel)
            self.addSubview(arrowIconImageView)
        }
        
    }
    
    func getRange(data: [[Any]]) -> [Float]{
        // [open, close, high, low]
        var high = data[0][1] as! Double
        var low = data[0][1] as! Double
        var value : Double
        
        for element in data{
            value = element[1] as! Double
            if value > high {
                high = value
            }
            if low > value {
                low = value
            }
        }
        
        return [Float(high), Float(low)]
    }
    
    func chartScaleRatio (change: Float) -> Float{
        return 0.45*tanh(change/0.12 - 1) + 0.55
    }
    
    func initializeConstraints(parent: UIView){
        self.translatesAutoresizingMaskIntoConstraints = false
        let chartRightConstraint = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: parent, attribute: .trailing, multiplier: 1, constant: -icon_padding*5)
        //        let chartWidthConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 70)
        let chartWidthConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 85)
        let chartVerticalAlign = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: parent, attribute: .centerY, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: (item_height-icon_padding*2))
        NSLayoutConstraint.activate([chartRightConstraint, chartWidthConstraint, chartVerticalAlign, heightConstraint])
    }
    
}

class scrollButton : UIScrollView, UIScrollViewDelegate {
    
    let options : [String]
    let parent : optionsBar
    var yPosition:CGFloat = 0
    var scrollViewContentSize:CGFloat = 0
    var value : String = ""
    
    init(frame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0), options: [String], parent: optionsBar, id: String){
        self.options = options
        self.parent = parent
        super.init(frame: frame)
        self.delegate = self
        self.layer.cornerRadius = frame.height/2.0
        self.accessibilityIdentifier = id
        self.initialize()
    }
    
    func initialize(){
        
        for  i in stride(from: 0, to: options.count, by: 1) {
            var frame = CGRect.zero
            frame.origin.x = self.frame.size.width * CGFloat(i)
            frame.origin.y = 0
            frame.size = self.frame.size
            self.isPagingEnabled = true
            self.showsHorizontalScrollIndicator = false
            self.backgroundColor = UIColor(red:0.25, green:0.22, blue:0.49, alpha:0.4)
            self.layer.cornerRadius = self.frame.height/2.0
            
            let myLabel:UILabel = UILabel()
            myLabel.text = options[i]
            myLabel.textColor = UIColor(red:0.58, green:0.53, blue:0.78, alpha:1.0)
            myLabel.font = UIFont(name: "AvenirNext-Medium", size: frame.height/1.75)
            myLabel.frame = frame
            myLabel.textAlignment = NSTextAlignment.center
            self.addSubview(myLabel)
        }
        
        self.contentSize = CGSize(width: self.frame.size.width * CGFloat(options.count), height: self.frame.size.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            self.value = self.options[Int(round(scrollView.contentOffset.x/scrollView.frame.width))]
            self.parent.updatedValue(sender: self, value: self.value)
        })
    }
    
    func setScrollPosition(option: String){
        let i = Int(self.options.index(of: option)!)
        self.contentOffset.x = self.frame.size.width*CGFloat(i)
    }
}

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


class ViewController: UIViewController, UIScrollViewDelegate {
    // Assume this is the loaded plist data
//    let item_array : [String] = ["BTC", "ETH", "USDT", "DASH", "EOS", "LTC", "BCH", "XRP", "DOGE", "ZEC", "BTC", "ETH", "USDT", "DASH", "EOS", "LTC"] //store in plist
//            let item_array : [String] = ["LTC", "USDT", "EOS"] //store in plist
    let item_array : [String] = ["DASH", "USDT","BTC", "EOS", "LTC", "XRP"] //store in plist
    var scrollView = UIScrollView()
    let optionsHeader = optionsBar(frame: CGRect(x: 0, y: 0 ,width: 0, height: 0), currency: "CAD", period: "7 Day")
    
    var item_object_array : [item] = []
    var stackHeightConstraint = NSLayoutConstraint()
    let stackView = UIStackView()
    let editButton = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 26))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red:0.09, green:0.09, blue:0.14, alpha:1.0)
        
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = true
        scrollView.clipsToBounds = false
        
        view.addSubview(scrollView)
        
        let refresh = UIRefreshControl(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        refresh.addTarget(self, action: #selector(refreshAll(_:)), for: UIControlEvents.valueChanged)
        refresh.tintColor = UIColor(red:0.58, green:0.53, blue:0.78, alpha:1.0)
        
        scrollView.addSubview(refresh)
        
        editButton.backgroundColor = UIColor(red:0.25, green:0.22, blue:0.49, alpha:0.4)
        editButton.layer.cornerRadius = editButton.frame.height/2.0
        editButton.addTarget(self, action: #selector(buttonRemove), for: .touchUpInside)
        editButton.setTitle("+", for: .normal)
        editButton.setTitleColor(UIColor(red:0.58, green:0.53, blue:0.78, alpha:1.0), for: .normal)
        
        stackView.axis = UILayoutConstraintAxis.vertical
        stackView.backgroundColor = UIColor.gray
        stackView.frame = CGRect(x: 0, y:0 , width: 0, height: 0)
        stackView.distribution = UIStackViewDistribution.equalSpacing
        
        self.view.addSubview(optionsHeader)
        scrollView.addSubview(stackView)
        scrollView.addSubview(editButton)

        optionsHeader.refreshFunction = {self.refreshAll()}
        
        for i in item_array {
            let temp_item : item = item(symbol: i)
            item_object_array.append(temp_item)
            stackView.addArrangedSubview(temp_item)
            temp_item.initialize()
        }
        
        self.refreshAll()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let scrollViewTop = NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: optionsHeader, attribute: .bottom, multiplier: 1, constant: stackPadding/2)
        let scrollViewLeft = scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let scrollViewRight = scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let scrollViewBottom = scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        
        NSLayoutConstraint.activate([scrollViewTop, scrollViewLeft, scrollViewRight, scrollViewBottom])
        
        optionsHeader.translatesAutoresizingMaskIntoConstraints = false
        let optionsBarTop = NSLayoutConstraint(item: optionsHeader, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 20)
        let optionsBarLeft = optionsHeader.leadingAnchor.constraint(equalTo: (scrollView.leadingAnchor))
        let optionsBarRight = optionsHeader.trailingAnchor.constraint(equalTo: (self.view.trailingAnchor))
        let optionsBarHeight = NSLayoutConstraint(item: optionsHeader, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40)
        NSLayoutConstraint.activate([optionsBarTop, optionsBarLeft, optionsBarRight, optionsBarHeight])
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let stackLeftConstraint = NSLayoutConstraint(item: stackView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: stackPadding)
        let stackRightConstraint = NSLayoutConstraint(item: stackView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -stackPadding)
        let stackTopConstraint = NSLayoutConstraint(item: stackView, attribute: .top, relatedBy: .equal, toItem: scrollView, attribute: .top, multiplier: 1, constant: 0)
        stackHeightConstraint = NSLayoutConstraint(item: stackView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        NSLayoutConstraint.activate([stackLeftConstraint, stackRightConstraint, stackTopConstraint, stackHeightConstraint])

        editButton.translatesAutoresizingMaskIntoConstraints = false

        let editButtonRightConstraint = NSLayoutConstraint(item: editButton, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -stackPadding)
        let editButtonTopConstraint = NSLayoutConstraint(item: editButton, attribute: .top, relatedBy: .equal, toItem: stackView, attribute: .bottom, multiplier: 1, constant: stackPadding)
         let editButtonHeightConstraint = NSLayoutConstraint(item: editButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: editButton.frame.height)
         let editButtonWidthConstraint = NSLayoutConstraint(item: editButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: editButton.frame.width)
        
        NSLayoutConstraint.activate([editButtonRightConstraint, editButtonTopConstraint, editButtonHeightConstraint, editButtonWidthConstraint])
        
        // statusbar
        let sb = UIView(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: 20.0))
        sb.backgroundColor = UIColor(red:0.09, green:0.09, blue:0.14, alpha:1.0)
        self.view.addSubview(sb)
        
        scrollView.contentSize = CGSize(width: self.view.bounds.width, height: calculateStackHeight())
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stackHeightConstraint.constant = calculateStackHeight()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func calculateStackHeight() -> CGFloat{
        var height : CGFloat = 0
        for _ in item_object_array{
            height += item_height
        }
        height += CGFloat(item_object_array.count - 1) * stackPadding
        return height
    }
    
    func buttonRemove(sender: UIButton!) {
        print("Destroying \(item_object_array[0].symbol)")
        item_object_array[0].destroy()
        item_object_array.remove(at: 0)
        stackHeightConstraint.constant = calculateStackHeight()
        stackView.updateConstraints()
    }
    
    func refreshAll(_ refreshControl: UIRefreshControl = UIRefreshControl()) {
        for item in item_object_array{
            item.refreshData(currency: optionsHeader.currencyValue, period: optionsHeader.periodValue)
        }
        refreshControl.endRefreshing()
    }
}
