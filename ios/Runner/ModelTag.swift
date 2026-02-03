
//: Declare String Begin

/*: "Net Error, Try again later" :*/
fileprivate let serviceAtHourState:String = "Net Erelse raw link can area"
fileprivate let notiAppearPhotoPath:String = "value click second corery again"
fileprivate let factoryTotalNameState:[Character] = [" ","l","a","t","e","r"]

/*: "data" :*/
fileprivate let noti_activeEmptyData:String = "confirmata"

/*: ":null" :*/
fileprivate let show_scaleUpID:String = "click normal command native original:null"

/*: "json error" :*/
fileprivate let kAppList:String = "method size screenjson "
fileprivate let app_canMessage:String = "emanageror"

/*: "platform=iphone&version= :*/
fileprivate let sessionScurrySecret:String = "platprogressr"
fileprivate let data_carrierTitle:String = "server typem=ip"
fileprivate let kTransportMode:[Character] = ["r","s","i","o","n","="]

/*: &packageId= :*/
fileprivate let configSessionIntervalVersion:String = "&packcenter challenge device below"
fileprivate let cacheInsideBackgroundState:String = "will backageId="

/*: &bundleId= :*/
fileprivate let managerRevenueFormatData:[Character] = ["&","b","u","n","d"]
fileprivate let const_willMessage:String = "log install phoneleId="

/*: &lang= :*/
fileprivate let loggerRemoteResponseVersion:String = "on bridge system for lab&lang="

/*: ; build: :*/
fileprivate let formatterMediaNowSuperDict:String = "plain quantity clear; bu"

/*: ; iOS  :*/
fileprivate let dataKeyDate:[Character] = [";"," ","i","O","S"," "]

//: Declare String End

// __DEBUG__
// __CLOSE_PRINT__
//: import UIKit
import UIKit
//: import Alamofire
import Alamofire
//: import CoreMedia
import CoreMedia
//: import HandyJSON
import HandyJSON
 
//: typealias FinishBlock = (_ succeed: Bool, _ result: Any?, _ errorModel: AppErrorResponse?) -> Void
typealias FinishBlock = (_ succeed: Bool, _ result: Any?, _ errorModel: ProductFound?) -> Void
 
//: @objc class AppRequestTool: NSObject {
@objc class ModelTag: NSObject {
    /// 发起Post请求
    /// - Parameters:
    ///   - model: 请求参数
    ///   - completion: 回调
    //: class func startPostRequest(model: AppRequestModel, completion: @escaping FinishBlock) {
    class func offce(model: StopModel, completion: @escaping FinishBlock) {
        //: let serverUrl = self.buildServerUrl(model: model)
        let serverUrl = self.reduce(model: model)
        //: let headers = self.getRequestHeader(model: model)
        let headers = self.enableBy(model: model)
        //: AF.request(serverUrl, method: .post, parameters: model.params, headers: headers, requestModifier: { $0.timeoutInterval = 10.0 }).responseData { [self] responseData in
        AF.request(serverUrl, method: .post, parameters: model.params, headers: headers, requestModifier: { $0.timeoutInterval = 10.0 }).responseData { [self] responseData in
            //: switch responseData.result {
            switch responseData.result {
            //: case .success:
            case .success:
                //: func__requestSucess(model: model, response: responseData.response!, responseData: responseData.data!, completion: completion)
                system(model: model, response: responseData.response!, responseData: responseData.data!, completion: completion)
                
            //: case .failure:
            case .failure:
                //: completion(false, nil, AppErrorResponse.init(errorCode: RequestResultCode.NetError.rawValue, errorMsg: "Net Error, Try again later"))
                completion(false, nil, ProductFound.init(errorCode: MergeParty.NetError.rawValue, errorMsg: (String(serviceAtHourState.prefix(6)) + "ror, T" + String(notiAppearPhotoPath.suffix(8)) + String(factoryTotalNameState))))
            }
        }
    }
    
    //: class func func__requestSucess(model: AppRequestModel, response: HTTPURLResponse, responseData: Data, completion: @escaping FinishBlock) {
    class func system(model: StopModel, response: HTTPURLResponse, responseData: Data, completion: @escaping FinishBlock) {
        //: var responseJson = String(data: responseData, encoding: .utf8)
        var responseJson = String(data: responseData, encoding: .utf8)
        //: responseJson = responseJson?.replacingOccurrences(of: "\"data\":null", with: "\"data\":{}")
        responseJson = responseJson?.replacingOccurrences(of: "\"" + (noti_activeEmptyData.replacingOccurrences(of: "confirm", with: "d")) + "\"" + (String(show_scaleUpID.suffix(5))), with: "" + "\"" + (noti_activeEmptyData.replacingOccurrences(of: "confirm", with: "d")) + "\"" + ":{}")
        //: if let responseModel = JSONDeserializer<AppBaseResponse>.deserializeFrom(json: responseJson) {
        if let responseModel = JSONDeserializer<FormatDisplay>.deserializeFrom(json: responseJson) {
            //: if responseModel.errno == RequestResultCode.Normal.rawValue {
            if responseModel.errno == MergeParty.Normal.rawValue {
                //: completion(true, responseModel.data, nil)
                completion(true, responseModel.data, nil)
            //: } else {
            } else {
                //: completion(false, responseModel.data, AppErrorResponse.init(errorCode: responseModel.errno, errorMsg: responseModel.msg ?? ""))
                completion(false, responseModel.data, ProductFound.init(errorCode: responseModel.errno, errorMsg: responseModel.msg ?? ""))
                //: switch responseModel.errno {
                switch responseModel.errno {
//                case MergeParty.NeedReLogin.rawValue:
//                    NotificationCenter.default.post(name: DID_LOGIN_OUT_SUCCESS_NOTIFICATION, object: nil, userInfo: nil)
                //: default:
                default:
                    //: break
                    break
                }
            }
        //: } else {
        } else {
            //: completion(false, nil, AppErrorResponse.init(errorCode: RequestResultCode.NetError.rawValue, errorMsg: "json error"))
            completion(false, nil, ProductFound.init(errorCode: MergeParty.NetError.rawValue, errorMsg: (String(kAppList.suffix(5)) + app_canMessage.replacingOccurrences(of: "manager", with: "rr"))))
        }
                
    }
    
    //: class func buildServerUrl(model: AppRequestModel) -> String {
    class func reduce(model: StopModel) -> String {
        //: var serverUrl: String = model.requestServer
        var serverUrl: String = model.requestServer
        //: let otherParams = "platform=iphone&version=\(AppNetVersion)&packageId=\(PackageID)&bundleId=\(AppBundle)&lang=\(UIDevice.interfaceLang)"
        let otherParams = (sessionScurrySecret.replacingOccurrences(of: "progress", with: "fo") + String(data_carrierTitle.suffix(4)) + "hone&ve" + String(kTransportMode)) + "\(appTransformUrl)" + (String(configSessionIntervalVersion.prefix(5)) + String(cacheInsideBackgroundState.suffix(6))) + "\(factoryModifyMessage)" + (String(managerRevenueFormatData) + String(const_willMessage.suffix(5))) + "\(const_identityID)" + (String(loggerRemoteResponseVersion.suffix(6))) + "\(UIDevice.interfaceLang)"
        //: if !model.requestPath.isEmpty {
        if !model.requestPath.isEmpty {
            //: serverUrl.append("/\(model.requestPath)")
            serverUrl.append("/\(model.requestPath)")
        }
        //: serverUrl.append("?\(otherParams)")
        serverUrl.append("?\(otherParams)")
        
        //: return serverUrl
        return serverUrl
    }
    
    /// 获取请求头参数
    /// - Parameter model: 请求模型
    /// - Returns: 请求头参数
    //: class func getRequestHeader(model: AppRequestModel) -> HTTPHeaders {
    class func enableBy(model: StopModel) -> HTTPHeaders {
        //: let userAgent = "\(AppName)/\(AppVersion) (\(AppBundle); build:\(AppBuildNumber); iOS \(UIDevice.current.systemVersion); \(UIDevice.modelName))"
        let userAgent = "\(noti_areaName)/\(mainForceMessage) (\(const_identityID)" + (String(formatterMediaNowSuperDict.suffix(4)) + "ild:") + "\(routerSaveDomainName)" + (String(dataKeyDate)) + "\(UIDevice.current.systemVersion); \(UIDevice.modelName))"
        //: let headers = [HTTPHeader.userAgent(userAgent)]
        let headers = [HTTPHeader.userAgent(userAgent)]
        //: return HTTPHeaders(headers)
        return HTTPHeaders(headers)
    }
}
 