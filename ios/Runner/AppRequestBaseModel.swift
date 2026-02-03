
//: Declare String Begin

/*: "http://app. :*/
fileprivate let main_closeUrl:String = "base visible net afterhttp://"
fileprivate let dataExistingNowStr:String = "app.global other will color action"

/*: .com" :*/
fileprivate let cacheAfterStateMessage:String = "item top.com"

//: Declare String End

// __DEBUG__
// __CLOSE_PRINT__
//: import Foundation
import Foundation
//: import HandyJSON
import HandyJSON
 
//: class AppRequestModel: NSObject {
class StopModel: NSObject {
    
    //: @objc var requestPath: String = ""
    @objc var requestPath: String = ""
    //: var requestServer: String = ""
    var requestServer: String = ""
    //: var params: Dictionary<String, Any> = [:]
    var params: Dictionary<String, Any> = [:]
    
    //: override init() {
    override init() {
        //: self.requestServer = "http://app.\(ReplaceUrlDomain).com"
        self.requestServer = (String(main_closeUrl.suffix(7)) + String(dataExistingNowStr.prefix(4))) + "\(const_reichKey)" + (String(cacheAfterStateMessage.suffix(4)))
    }
}

/// 通用Model
//: struct AppBaseResponse: HandyJSON {
struct FormatDisplay: HandyJSON {
    //: var errno: Int!  
    var errno: Int!  // 服务端返回码
    //: var msg: String? 
    var msg: String? // 服务端返回码
    //: var data: Any?   
    var data: Any?   // 具体的data的格式和业务相关，故用泛型定义
}

/// 通用Model
//: public struct AppErrorResponse {
public struct ProductFound {
    //: let errorCode: Int
    let errorCode: Int
    //: let errorMsg: String
    let errorMsg: String
    //: init(errorCode: Int, errorMsg: String) {
    init(errorCode: Int, errorMsg: String) {
        //: self.errorCode = errorCode
        self.errorCode = errorCode
        //: self.errorMsg = errorMsg
        self.errorMsg = errorMsg
    }
}

//: enum RequestResultCode: Int {
enum MergeParty: Int {
    //: case Normal         = 0
    case Normal         = 0
    //: case NetError       = -10000      
    case NetError       = -10000      // w
    //: case NeedReLogin    = -100        
    case NeedReLogin    = -100        // 需要重新登录
}