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
            print("error=\(error)")
            return
        }
        
        if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
            print("statusCode should be 200, but is \(httpStatus.statusCode)")
            print("response = \(response)")
        }
        
        let jsonString = try? JSONSerialization.jsonObject(with: data, options: [])
        //        var epoch : Int
        //        var timestamp : NSDate
        
        if let jsonResponse = jsonString as? [String: Any] {
            if let priceInfo = jsonResponse["Data"] as? [NSDictionary] {
                for i in priceInfo {
                    outputData.append([i["time"] as! Int, i["close"] as! Double])
                }
            }
            completion(outputData)
        }
    }
    task.resume()
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
