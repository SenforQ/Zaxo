
//: Declare String Begin

/*: "socoay" :*/
fileprivate let networkBarResult:String = "responsecoay"

/*: "949" :*/
fileprivate let managerSourceTime:[Character] = ["9","4","9"]

/*: "4s5r67kx55ds" :*/
fileprivate let sessionFinishResult:[Character] = ["4","s","5","r","6","7","k","x","5","5","d","s"]

/*: "myetlu" :*/
fileprivate let sessionPublicTransportModelID:String = "MYETLU"

/*: "1.9.1" :*/
fileprivate let pointSubValue:String = "cancel.9.cancel"

/*: "https://m. :*/
fileprivate let helperPromiseFailureKey:String = "httpting"

/*: .com" :*/
fileprivate let sessionMediaPath:String = "launch text production.com"

/*: "CFBundleShortVersionString" :*/
fileprivate let networkColorName:String = "CFBunreport else"
fileprivate let user_adjustmentStatus:String = "minute us localhortV"
fileprivate let userAllowResult:String = "track package sourceonStrin"
fileprivate let dataErrorFormat:String = "succeed"

/*: "CFBundleDisplayName" :*/
fileprivate let userScaleAgainError:[Character] = ["C","F","B","u","n","d","l","e","D","i","s","p","l"]
fileprivate let routerDayDownURL:String = "ayNamedisappear multi empty zone"

/*: "CFBundleVersion" :*/
fileprivate let controllerPrepareMethodString:String = "CFBundlereport corner frame"
fileprivate let mainActionKey:String = "agent"
fileprivate let helperEmptyDiskFormat:[Character] = ["e","r","s","i","o","n"]

/*: "weixin" :*/
fileprivate let constBridgeState:String = "forceeixin"

/*: "wxwork" :*/
fileprivate let controllerFlexibleMode:String = "WXWORK"

/*: "dingtalk" :*/
fileprivate let appearArrowTime:[Character] = ["d","i","n","g","t","a","l","k"]

/*: "lark" :*/
fileprivate let show_contentError:[Character] = ["l","a","r","k"]

//: Declare String End

// __DEBUG__
// __CLOSE_PRINT__
//
//  IndicatorDisableBegin.swift
//  OverseaH5
//
//  Created by young on 2025/9/24.
//

//: import KeychainSwift
import KeychainSwift
//: import UIKit
import UIKit

/// 域名
//: let ReplaceUrlDomain = "socoay"
let const_reichKey = (networkBarResult.replacingOccurrences(of: "response", with: "so"))
/// 包ID
//: let PackageID = "949"
let factoryModifyMessage = (String(managerSourceTime))
/// Adjust
//: let AdjustKey = "4s5r67kx55ds"
let installMultiId = (String(sessionFinishResult))
//: let AdInstallToken = "myetlu"
let networkZoneStatus = (sessionPublicTransportModelID.lowercased())

/// 网络版本号
//: let AppNetVersion = "1.9.1"
let appTransformUrl = (pointSubValue.replacingOccurrences(of: "cancel", with: "1"))
//: let H5WebDomain = "https://m.\(ReplaceUrlDomain).com"
let main_unitToken = (helperPromiseFailureKey.replacingOccurrences(of: "ting", with: "s") + "://m.") + "\(const_reichKey)" + (String(sessionMediaPath.suffix(4)))
//: let AppVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
let mainForceMessage = Bundle.main.infoDictionary![(String(networkColorName.prefix(5)) + "dleS" + String(user_adjustmentStatus.suffix(5)) + "ersi" + String(userAllowResult.suffix(7)) + dataErrorFormat.replacingOccurrences(of: "succeed", with: "g"))] as! String
//: let AppBundle = Bundle.main.bundleIdentifier!
let const_identityID = Bundle.main.bundleIdentifier!
//: let AppName = Bundle.main.infoDictionary!["CFBundleDisplayName"] ?? ""
let noti_areaName = Bundle.main.infoDictionary![(String(userScaleAgainError) + String(routerDayDownURL.prefix(6)))] ?? ""
//: let AppBuildNumber = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
let routerSaveDomainName = Bundle.main.infoDictionary![(String(controllerPrepareMethodString.prefix(8)) + mainActionKey.replacingOccurrences(of: "agent", with: "V") + String(helperEmptyDiskFormat))] as! String

//: class AppConfig: NSObject {
class IndicatorDisableBegin: NSObject {
    /// 获取状态栏高度
    //: class func getStatusBarHeight() -> CGFloat {
    class func deadline() -> CGFloat {
        //: if #available(iOS 13.0, *) {
        if #available(iOS 13.0, *) {
            //: if let statusBarManager = UIApplication.shared.windows.first?
            if let statusBarManager = UIApplication.shared.windows.first?
                //: .windowScene?.statusBarManager
                .windowScene?.statusBarManager
            {
                //: return statusBarManager.statusBarFrame.size.height
                return statusBarManager.statusBarFrame.size.height
            }
        //: } else {
        } else {
            //: return UIApplication.shared.statusBarFrame.size.height
            return UIApplication.shared.statusBarFrame.size.height
        }
        //: return 20.0
        return 20.0
    }

    /// 获取window
    //: class func getWindow() -> UIWindow {
    class func confirmPurchase() -> UIWindow {
        //: var window = UIApplication.shared.windows.first(where: {
        var window = UIApplication.shared.windows.first(where: {
            //: $0.isKeyWindow
            $0.isKeyWindow
        //: })
        })
        // 是否为当前显示的window
        //: if window?.windowLevel != UIWindow.Level.normal {
        if window?.windowLevel != UIWindow.Level.normal {
            //: let windows = UIApplication.shared.windows
            let windows = UIApplication.shared.windows
            //: for windowTemp in windows {
            for windowTemp in windows {
                //: if windowTemp.windowLevel == UIWindow.Level.normal {
                if windowTemp.windowLevel == UIWindow.Level.normal {
                    //: window = windowTemp
                    window = windowTemp
                    //: break
                    break
                }
            }
        }
        //: return window!
        return window!
    }

    /// 获取当前控制器
    //: class func currentViewController() -> (UIViewController?) {
    class func laissezPasser() -> (UIViewController?) {
        //: var window = AppConfig.getWindow()
        var window = IndicatorDisableBegin.confirmPurchase()
        //: if window.windowLevel != UIWindow.Level.normal {
        if window.windowLevel != UIWindow.Level.normal {
            //: let windows = UIApplication.shared.windows
            let windows = UIApplication.shared.windows
            //: for windowTemp in windows {
            for windowTemp in windows {
                //: if windowTemp.windowLevel == UIWindow.Level.normal {
                if windowTemp.windowLevel == UIWindow.Level.normal {
                    //: window = windowTemp
                    window = windowTemp
                    //: break
                    break
                }
            }
        }
        //: let vc = window.rootViewController
        let vc = window.rootViewController
        //: return currentViewController(vc)
        return forefront(vc)
    }

    //: class func currentViewController(_ vc: UIViewController?)
    class func forefront(_ vc: UIViewController?)
        //: -> UIViewController?
        -> UIViewController?
    {
        //: if vc == nil {
        if vc == nil {
            //: return nil
            return nil
        }
        //: if let presentVC = vc?.presentedViewController {
        if let presentVC = vc?.presentedViewController {
            //: return currentViewController(presentVC)
            return forefront(presentVC)
        //: } else if let tabVC = vc as? UITabBarController {
        } else if let tabVC = vc as? UITabBarController {
            //: if let selectVC = tabVC.selectedViewController {
            if let selectVC = tabVC.selectedViewController {
                //: return currentViewController(selectVC)
                return forefront(selectVC)
            }
            //: return nil
            return nil
        //: } else if let naiVC = vc as? UINavigationController {
        } else if let naiVC = vc as? UINavigationController {
            //: return currentViewController(naiVC.visibleViewController)
            return forefront(naiVC.visibleViewController)
        //: } else {
        } else {
            //: return vc
            return vc
        }
    }
}

// MARK: - Device
//: extension UIDevice {
extension UIDevice {
    //: static var modelName: String {
    static var modelName: String {
        //: var systemInfo = utsname()
        var systemInfo = utsname()
        //: uname(&systemInfo)
        uname(&systemInfo)
        //: let machineMirror = Mirror(reflecting: systemInfo.machine)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        //: let identifier = machineMirror.children.reduce("") {
        let identifier = machineMirror.children.reduce("") {
            //: identifier, element in
            identifier, element in
            //: guard let value = element.value as? Int8, value != 0 else {
            guard let value = element.value as? Int8, value != 0 else {
                //: return identifier
                return identifier
            }
            //: return identifier + String(UnicodeScalar(UInt8(value)))
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        //: return identifier
        return identifier
    }

    /// 获取当前系统时区
    //: static var timeZone: String {
    static var timeZone: String {
        //: let currentTimeZone = NSTimeZone.system
        let currentTimeZone = NSTimeZone.system
        //: return currentTimeZone.identifier
        return currentTimeZone.identifier
    }

    /// 获取当前系统语言
    //: static var langCode: String {
    static var langCode: String {
        //: let language = Locale.preferredLanguages.first
        let language = Locale.preferredLanguages.first
        //: return language ?? ""
        return language ?? ""
    }

    /// 获取接口语言
    //: static var interfaceLang: String {
    static var interfaceLang: String {
        //: let lang = UIDevice.getSystemLangCode()
        let lang = UIDevice.access()
        //: if ["en", "ar", "es", "pt"].contains(lang) {
        if ["en", "ar", "es", "pt"].contains(lang) {
            //: return lang
            return lang
        }
        //: return "en"
        return "en"
    }

    /// 获取当前系统地区
    //: static var countryCode: String {
    static var countryCode: String {
        //: let locale = Locale.current
        let locale = Locale.current
        //: let countryCode = locale.regionCode
        let countryCode = locale.regionCode
        //: return countryCode ?? ""
        return countryCode ?? ""
    }

    /// 获取系统UUID（每次调用都会产生新值，所以需要keychain）
    //: static var systemUUID: String {
    static var systemUUID: String {
        //: let key = KeychainSwift()
        let key = KeychainSwift()
        //: if let value = key.get(AdjustKey) {
        if let value = key.get(installMultiId) {
            //: return value
            return value
        //: } else {
        } else {
            //: let value = NSUUID().uuidString
            let value = NSUUID().uuidString
            //: key.set(value, forKey: AdjustKey)
            key.set(value, forKey: installMultiId)
            //: return value
            return value
        }
    }

    /// 获取已安装应用信息
    //: static var getInstalledApps: String {
    static var getInstalledApps: String {
        //: var appsArr: [String] = []
        var appsArr: [String] = []
        //: if UIDevice.canOpenApp("weixin") {
        if UIDevice.count((constBridgeState.replacingOccurrences(of: "force", with: "w"))) {
            //: appsArr.append("weixin")
            appsArr.append((constBridgeState.replacingOccurrences(of: "force", with: "w")))
        }
        //: if UIDevice.canOpenApp("wxwork") {
        if UIDevice.count((controllerFlexibleMode.lowercased())) {
            //: appsArr.append("wxwork")
            appsArr.append((controllerFlexibleMode.lowercased()))
        }
        //: if UIDevice.canOpenApp("dingtalk") {
        if UIDevice.count((String(appearArrowTime))) {
            //: appsArr.append("dingtalk")
            appsArr.append((String(appearArrowTime)))
        }
        //: if UIDevice.canOpenApp("lark") {
        if UIDevice.count((String(show_contentError))) {
            //: appsArr.append("lark")
            appsArr.append((String(show_contentError)))
        }
        //: if appsArr.count > 0 {
        if appsArr.count > 0 {
            //: return appsArr.joined(separator: ",")
            return appsArr.joined(separator: ",")
        }
        //: return ""
        return ""
    }

    /// 判断是否安装app
    //: static func canOpenApp(_ scheme: String) -> Bool {
    static func count(_ scheme: String) -> Bool {
        //: let url = URL(string: "\(scheme)://")!
        let url = URL(string: "\(scheme)://")!
        //: if UIApplication.shared.canOpenURL(url) {
        if UIApplication.shared.canOpenURL(url) {
            //: return true
            return true
        }
        //: return false
        return false
    }

    /// 获取系统语言
    /// - Returns: 国际通用语言Code
    //: @objc public class func getSystemLangCode() -> String {
    @objc public class func access() -> String {
        //: let language = NSLocale.preferredLanguages.first
        let language = NSLocale.preferredLanguages.first
        //: let array = language?.components(separatedBy: "-")
        let array = language?.components(separatedBy: "-")
        //: return array?.first ?? "en"
        return array?.first ?? "en"
    }
}
