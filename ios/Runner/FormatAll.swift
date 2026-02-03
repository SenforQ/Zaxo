
//: Declare String Begin

/*: "init(coder:) has not been implemented" :*/
fileprivate let routerDependName:[UInt8] = [0x57,0x5c,0x57,0x62,0x16,0x51,0x5d,0x52,0x53,0x60,0x28,0x17,0xe,0x56,0x4f,0x61,0xe,0x5c,0x5d,0x62,0xe,0x50,0x53,0x53,0x5c,0xe,0x57,0x5b,0x5e,0x5a,0x53,0x5b,0x53,0x5c,0x62,0x53,0x52]

fileprivate func deleteCount(s num: UInt8) -> UInt8 {
    let value = Int(num) - 238
    if value < 0 {
        return UInt8(value + 256)
    } else {
        return UInt8(value)
    }
}

//: Declare String End

// __DEBUG__
// __CLOSE_PRINT__
//
//  FormatAll.swift
//  AbroadTalking
//
//  Created by Joeyoung on 2022/9/1.
//

//: import UIKit
import UIKit

//: let kProgressHUD_W            = 80.0
let constUserKey            = 80.0
//: let kProgressHUD_cornerRadius = 14.0
let kSuccessMessage = 14.0
//: let kProgressHUD_alpha        = 0.9
let appCornerId        = 0.9
//: let kBackgroundView_alpha     = 0.6
let data_destinationList     = 0.6
//: let kAnimationInterval        = 0.2
let sessionPrepareKey        = 0.2
//: let kTransformScale           = 0.9
let publicTransportPath           = 0.9

//: open class ProgressHUD: UIView {
open class FormatAll: UIView {
    //: required public init?(coder: NSCoder) {
    required public init?(coder: NSCoder) {
        //: fatalError("init(coder:) has not been implemented")
        fatalError(String(bytes: routerDependName.map{deleteCount(s: $0)}, encoding: .utf8)!)
    }
    
    //: static var shared = ProgressHUD()
    static var shared = FormatAll()
    //: private override init(frame: CGRect) {
    private override init(frame: CGRect) {
        //: super.init(frame: frame)
        super.init(frame: frame)
        //: self.frame = UIScreen.main.bounds
        self.frame = UIScreen.main.bounds
        //: self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        //: self.backgroundColor = UIColor(white: 0, alpha: 0)
        self.backgroundColor = UIColor(white: 0, alpha: 0)
        //: self.addSubview(activityIndicator)
        self.addSubview(activityIndicator)
    }
    //: open override func copy() -> Any { return self }
    open override func copy() -> Any { return self }
    //: open override func mutableCopy() -> Any { return self }
    open override func mutableCopy() -> Any { return self }
    
    //: class func show() {
    class func agentIn() {
        //: show(superView: nil)
        decide(superView: nil)
    }
    //: class func show(superView: UIView?) {
    class func decide(superView: UIView?) {
        //: if superView != nil {
        if superView != nil {
            //: DispatchQueue.main.async {
            DispatchQueue.main.async {
                //: ProgressHUD.shared.frame = superView!.bounds
                FormatAll.shared.frame = superView!.bounds
                //: ProgressHUD.shared.activityIndicator.center = ProgressHUD.shared.center
                FormatAll.shared.activityIndicator.center = FormatAll.shared.center
                //: superView!.addSubview(ProgressHUD.shared)
                superView!.addSubview(FormatAll.shared)
            }
        //: } else {
        } else {
            //: DispatchQueue.main.async {
            DispatchQueue.main.async {
                //: ProgressHUD.shared.frame = UIScreen.main.bounds
                FormatAll.shared.frame = UIScreen.main.bounds
                //: ProgressHUD.shared.activityIndicator.center = ProgressHUD.shared.center
                FormatAll.shared.activityIndicator.center = FormatAll.shared.center
                //: AppConfig.getWindow().addSubview(ProgressHUD.shared)
                IndicatorDisableBegin.confirmPurchase().addSubview(FormatAll.shared)
            }
        }
        //: ProgressHUD.shared.hud_startAnimating()
        FormatAll.shared.scriptApplication()
    }
    //: class func dismiss() {
    class func pic() {
        //: ProgressHUD.shared.hud_stopAnimating()
        FormatAll.shared.numberRevenue()
    }
    
    //: private func hud_startAnimating() {
    private func scriptApplication() {
        //: DispatchQueue.main.async {
        DispatchQueue.main.async {
            //: self.backgroundColor = UIColor(white: 0, alpha: 0)
            self.backgroundColor = UIColor(white: 0, alpha: 0)
            //: self.activityIndicator.transform = CGAffineTransform(scaleX: kTransformScale, y: kTransformScale)
            self.activityIndicator.transform = CGAffineTransform(scaleX: publicTransportPath, y: publicTransportPath)
            //: self.activityIndicator.alpha = 0
            self.activityIndicator.alpha = 0
            //: UIView.animate(withDuration: kAnimationInterval) {
            UIView.animate(withDuration: sessionPrepareKey) {
                //: self.backgroundColor = UIColor(white: 0, alpha: kBackgroundView_alpha)
                self.backgroundColor = UIColor(white: 0, alpha: data_destinationList)
                //: self.activityIndicator.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.activityIndicator.transform = CGAffineTransform(scaleX: 1, y: 1)
                //: self.activityIndicator.alpha = kProgressHUD_alpha
                self.activityIndicator.alpha = appCornerId
                //: self.activityIndicator.startAnimating()
                self.activityIndicator.startAnimating()
            }
        }
    }
    //: private func hud_stopAnimating() {
    private func numberRevenue() {
        //: DispatchQueue.main.async {
        DispatchQueue.main.async {
            //: UIView.animate(withDuration: kAnimationInterval) {
            UIView.animate(withDuration: sessionPrepareKey) {
                //: self.backgroundColor = UIColor(white: 0, alpha: 0)
                self.backgroundColor = UIColor(white: 0, alpha: 0)
                //: self.activityIndicator.transform = CGAffineTransform(scaleX: kTransformScale, y: kTransformScale)
                self.activityIndicator.transform = CGAffineTransform(scaleX: publicTransportPath, y: publicTransportPath)
                //: self.activityIndicator.alpha = 0
                self.activityIndicator.alpha = 0
            //: } completion: { finished in
            } completion: { finished in
                //: self.activityIndicator.stopAnimating()
                self.activityIndicator.stopAnimating()
                //: ProgressHUD.shared.removeFromSuperview()
                FormatAll.shared.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Lazy load
    //: private lazy var activityIndicator: UIActivityIndicatorView = {
    private lazy var activityIndicator: UIActivityIndicatorView = {
        //: let indicator = UIActivityIndicatorView(style: .whiteLarge)
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        //: indicator.bounds = CGRect(x: 0, y: 0, width: kProgressHUD_W, height: kProgressHUD_W)
        indicator.bounds = CGRect(x: 0, y: 0, width: constUserKey, height: constUserKey)
        //: indicator.center = self.center
        indicator.center = self.center
        //: indicator.backgroundColor = .black
        indicator.backgroundColor = .black
        //: indicator.layer.cornerRadius = kProgressHUD_cornerRadius
        indicator.layer.cornerRadius = kSuccessMessage
        //: indicator.layer.masksToBounds = true
        indicator.layer.masksToBounds = true
        //: return indicator
        return indicator
    //: }()
    }()
}

//: extension ProgressHUD {
extension FormatAll {
    //: class func toast(_ str: String?) {
    class func purchaseInsideExamine(_ str: String?) {
        //: toast(str, showTime: 1)
        bridge(str, showTime: 1)
    }
    //: class func toast(_ str: String?, showTime: CGFloat) {
    class func bridge(_ str: String?, showTime: CGFloat) {
        //: guard str != nil else { return }
        guard str != nil else { return }
                
        //: let titleLab = UILabel()
        let titleLab = UILabel()
        //: titleLab.backgroundColor = UIColor(white: 0, alpha: 0.8)
        titleLab.backgroundColor = UIColor(white: 0, alpha: 0.8)
        //: titleLab.layer.cornerRadius = 5
        titleLab.layer.cornerRadius = 5
        //: titleLab.layer.masksToBounds = true
        titleLab.layer.masksToBounds = true
        //: titleLab.text = str
        titleLab.text = str
        //: titleLab.font = .systemFont(ofSize: 16)
        titleLab.font = .systemFont(ofSize: 16)
        //: titleLab.textAlignment = .center
        titleLab.textAlignment = .center
        //: titleLab.numberOfLines = 0
        titleLab.numberOfLines = 0
        //: titleLab.textColor = .white
        titleLab.textColor = .white
        //: AppConfig.getWindow().addSubview(titleLab)
        IndicatorDisableBegin.confirmPurchase().addSubview(titleLab)
        //: let size = titleLab.sizeThatFits(CGSize(width: UIScreen.main.bounds.width - 40, height: CGFloat(MAXFLOAT)))
        let size = titleLab.sizeThatFits(CGSize(width: UIScreen.main.bounds.width - 40, height: CGFloat(MAXFLOAT)))
        //: titleLab.center = AppConfig.getWindow().center
        titleLab.center = IndicatorDisableBegin.confirmPurchase().center
        //: titleLab.bounds = CGRect(x: 0, y: 0, width: size.width + 30, height: size.height + 30)
        titleLab.bounds = CGRect(x: 0, y: 0, width: size.width + 30, height: size.height + 30)
        //: titleLab.alpha = 0
        titleLab.alpha = 0
        
        //: UIView.animate(withDuration: 0.2) {
        UIView.animate(withDuration: 0.2) {
            //: titleLab.alpha = 1
            titleLab.alpha = 1
        //: } completion: { finished in
        } completion: { finished in
            //: DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + showTime) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + showTime) {
                //: UIView.animate(withDuration: 0.2) {
                UIView.animate(withDuration: 0.2) {
                    //: titleLab.alpha = 1
                    titleLab.alpha = 1
                //: } completion: { finished in
                } completion: { finished in
                    //: titleLab.removeFromSuperview()
                    titleLab.removeFromSuperview()
                }
            }
        }
    }
}