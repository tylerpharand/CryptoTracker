//
//  Chart.swift
//  CryptoTracker
//
//  Created by Tyler Pharand on 2018-11-15.
//  Copyright © 2018 Tyler Pharand. All rights reserved.
//

import UIKit


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
