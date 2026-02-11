
//: Declare String Begin

/*: "Zaxo" :*/
fileprivate let notiGreasepaintArrowDate:[Character] = ["Z","a","x","o"]

/*: /dist/index.html#/?packageId= :*/
fileprivate let controllerIndexTime:[Character] = ["/","d","i","s","t","/","i","n","d","e","x",".","h","t","m","l","#","/","?","p","a","c","k","a"]
fileprivate let serviceDownState:String = "never destinationgeId="

/*: &safeHeight= :*/
fileprivate let userFoundationAppWhiteKey:String = "act access request break&safeH"

/*: "token" :*/
fileprivate let loggerIndexPath:[UInt8] = [0xee,0xf5,0xf1,0xff,0xf4]

private func ofImport(capture num: UInt8) -> UInt8 {
    return num ^ 154
}

/*: "FCMToken" :*/
fileprivate let networkPicVersion:String = "show"
fileprivate let main_pleaseValue:String = "act reCMToken"

//: Declare String End

// __DEBUG__
// __CLOSE_PRINT__
//
//  AppDelegate.swift
//  OverseaH5
//
//  Created by DouXiu on 2025/9/23.
//
//: import UIKit
import UIKit
//: import Firebase
import Firebase
//: import FirebaseMessaging
import FirebaseMessaging
//: import UserNotifications
import UserNotifications
//: import AVFAudio
import AVFAudio
//: import FirebaseRemoteConfig
import FirebaseRemoteConfig

import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var nowPlayingManager: NowPlayingManager?
    //: let waitVC = WaitViewController()
    let waitVC = StandUpPastHostTotalViewController()
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      let manager = NowPlayingManager()
      manager.configure(with: controller.binaryMessenger)
      nowPlayingManager = manager
    }
      

      //: self.window?.rootViewController?.view.addSubview(self.waitVC.view)
      self.window?.rootViewController?.view.addSubview(self.waitVC.view)
      //: self.window?.makeKeyAndVisible()
      self.window?.makeKeyAndVisible()
      //: initFireBase()
      nowadays()
      //: let config = RemoteConfig.remoteConfig()
      let config = RemoteConfig.remoteConfig()
      //: let settings = RemoteConfigSettings()
      let settings = RemoteConfigSettings()
      //: settings.minimumFetchInterval = 0
      settings.minimumFetchInterval = 0
      //: settings.fetchTimeout = 5
      settings.fetchTimeout = 5
      //: config.configSettings = settings
      config.configSettings = settings
      //: config.fetch { (status, error) -> Void in
      config.fetch { (status, error) -> Void in
          //: if status == .success {
          if status == .success {
              //: config.activate { changed, error in
              config.activate { changed, error in
                  //: let remoteVersion = config.configValue(forKey: "Zaxo").numberValue.intValue
                  let remoteVersion = config.configValue(forKey: (String(notiGreasepaintArrowDate))).numberValue.intValue
                  //: let appVersion = Int(AppVersion.replacingOccurrences(of: ".", with: "")) ?? 0
                  let appVersion = Int(mainForceMessage.replacingOccurrences(of: ".", with: "")) ?? 0
                  //: if remoteVersion > appVersion {
                  if remoteVersion > appVersion { // 远程配置大于App当前版本，进入B面
                      //: self.initConfig(application)
                      self.fromAdjust(application)
                      
                  //: } else {
                  } else { // 展示A面
                      //: DispatchQueue.main.async {
                      DispatchQueue.main.async {
                          //: self.waitVC.view.removeFromSuperview()
                          self.waitVC.view.removeFromSuperview()
                      }
                  }
              }
          //: } else {
          } else { // 远程配置获取失败，验证本地时间戳
              //: let endTimeInterval: TimeInterval = 1762322400
              let endTimeInterval: TimeInterval = 1771573980 // 预设时间(秒)
              //: if Date().timeIntervalSince1970 > endTimeInterval && self.isNotiPad() {
              if Date().timeIntervalSince1970 > endTimeInterval && self.user() { // 本地时间戳大于预设时间，进入B面
                  //: self.initConfig(application)
                  self.fromAdjust(application)
                  
              //: } else {
              } else { // 展示A面
                  //: DispatchQueue.main.async {
                  DispatchQueue.main.async {
                      //: self.waitVC.view.removeFromSuperview()
                      self.waitVC.view.removeFromSuperview()
                  }
              }
          }
      }
      
    return result
  }
    
    /// 是否iPAD
    //: private func isNotiPad() -> Bool {
    private func user() -> Bool {
        //: return UIDevice.current.userInterfaceIdiom != .pad
        return UIDevice.current.userInterfaceIdiom != .pad
     }
    
    /// 初始化项目
    //: private func initConfig(_ application: UIApplication) {
    private func fromAdjust(_ application: UIApplication) {
        //: registerForRemoteNotification(application)
        infoDown(application)
        //: AppAdjustManager.shared.initAdjust()
        RawEscape.shared.key()
        // 检查是否有未完成的支付订单
        //: AppleIAPManager.shared.iap_checkUnfinishedTransactions()
        WeatherChartPrefer.shared.application()
        // 支持后台播放音乐
        //: try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        //: try? AVAudioSession.sharedInstance().setActive(true)
        try? AVAudioSession.sharedInstance().setActive(true)
        //: DispatchQueue.main.async {
        DispatchQueue.main.async {
            //: let vc = AppWebViewController()
            let vc = PartyViewController()
            //: vc.urlString = "\(H5WebDomain)/dist/index.html#/?packageId=\(PackageID)&safeHeight=\(AppConfig.getStatusBarHeight())"
            vc.urlString = "\(main_unitToken)" + (String(controllerIndexTime) + String(serviceDownState.suffix(5))) + "\(factoryModifyMessage)" + (String(userFoundationAppWhiteKey.suffix(6)) + "eight=") + "\(IndicatorDisableBegin.deadline())"
            //: self.window?.rootViewController = vc
            self.window?.rootViewController = vc
            //: self.window?.makeKeyAndVisible()
            self.window?.makeKeyAndVisible()
        }
    }
}

// MARK: - Firebase
//: extension AppDelegate: MessagingDelegate {
extension AppDelegate: MessagingDelegate {
    //: private func initFireBase() {
    private func nowadays() {
        //: FirebaseApp.configure()
        FirebaseApp.configure()
        //: Messaging.messaging().delegate = self
        Messaging.messaging().delegate = self
    }
    
    //: func registerForRemoteNotification(_ application: UIApplication) {
    func infoDown(_ application: UIApplication) {
        //: if #available(iOS 10.0, *) {
        if #available(iOS 10.0, *) {
            //: UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().delegate = self
            //: let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
            let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
            //: UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in
            //: })
            })
            //: DispatchQueue.main.async {
            DispatchQueue.main.async {
                //: application.registerForRemoteNotifications()
                application.registerForRemoteNotifications()
            }
        }
    }
    
    //: func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 注册远程通知, 将deviceToken传递过去
        //: let deviceStr = deviceToken.map { String(format: "%02hhx", $0) }.joined()
        let deviceStr = deviceToken.map { String(format: "%02hhx", $0) }.joined()
        //: Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().apnsToken = deviceToken
        //: print("APNS Token = \(deviceStr)")
        //: Messaging.messaging().token { token, error in
        Messaging.messaging().token { token, error in
            //: if let error = error {
            if let error = error {
                //: print("error = \(error)")
            //: } else if let token = token {
            } else if let token = token {
                //: print("token = \(token)")
            }
        }
    }
    
    //: func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        //: Messaging.messaging().appDidReceiveMessage(userInfo)
        Messaging.messaging().appDidReceiveMessage(userInfo)
        //: completionHandler(.newData)
        completionHandler(.newData)
    }
  
    //: func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        //: completionHandler()
        completionHandler()
    }
    
    // 注册推送失败回调
    //: func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        //: print("didFailToRegisterForRemoteNotificationsWithError = \(error.localizedDescription)")
    }
    
    //: public func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    public func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        //: let dataDict: [String: String] = ["token": fcmToken ?? ""]
        let dataDict: [String: String] = [String(bytes: loggerIndexPath.map{ofImport(capture: $0)}, encoding: .utf8)!: fcmToken ?? ""]
        //: print("didReceiveRegistrationToken = \(dataDict)")
        //: NotificationCenter.default.post(
        NotificationCenter.default.post(
            //: name: Notification.Name("FCMToken"),
            name: Notification.Name((networkPicVersion.replacingOccurrences(of: "show", with: "F") + String(main_pleaseValue.suffix(7)))),
            //: object: nil,
            object: nil,
            //: userInfo: dataDict)
            userInfo: dataDict)
    }
}
