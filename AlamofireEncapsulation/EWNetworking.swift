//
//  EWNetworking.swift
//  AlamofireEncapsulation
//
//  Created by Ethan.Wang on 2018/9/7.
//  Copyright © 2018年 Ethan. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
///环境url,根据自己需求更改
#if PRODUCTION
let baseDomain = "http://www.baidu.com"
let basePicPath = "http://www.baidu.com/upload/"
#else
let baseDomain = "http://192.168.1.213:8000/"
let basePicPath = "http://192.168.1.213:8000/upload/"
#endif

typealias EWResponseSuccess = (_ response: AnyObject)->()
typealias EWResponseFail = (_ error: AnyObject)->()
typealias ELNetworkStatus = (_ EWNetworkStatus: Int32)->()

@objc enum EWNetworkStatus: Int32 {
    case Unknown          = -1//未知网络
    case NotReachable     = 0//网络无连接
    case WWAN             = 1//2，3，4G网络
    case WiFi             = 2//WIFI网络
}
///baseURL,可以通过修改来实现切换开发环境与生产环境
var ew_privateNetworkBaseUrl: String?
///默认超时时间
var ew_timeout: TimeInterval = 45
///自定义manager
var manager: SessionManager? = nil
/**** 请求header
 *  根据后台需求,如果需要在header中传类似token的标识
 *  就可以通过在这里设置来实现全局使用
 *  这里是将token存在keychain中,可以根据自己项目需求存在合适的位置.
 */
var ew_httpHeaders: Dictionary<String,String>? {
    get{
        guard let tokenData = Keychain.load(key: "token") else { return nil }
        let token = NSKeyedUnarchiver.unarchiveObject(with: tokenData)
        return ["token":token] as? Dictionary<String, String>
    }
}
///缓存存储地址
let cachePath = NSHomeDirectory() + "/Documents/AlamofireCaches/"
///当前网络状态
var ew_NetworkStatus: EWNetworkStatus = EWNetworkStatus.WiFi

class EWNetworking: NSObject {
    class func getWith(url: String,
                       params:Dictionary<String,Any>?,
                       success: @escaping EWResponseSuccess,
                       error: @escaping EWResponseFail){
        requestWith(url: url,
                    httpMethod: 0,
                    params: params,
                    success: success,
                    error: error)
    }
    class func postWith(url: String,
                        params: Dictionary<String,Any>,
                        success: @escaping EWResponseSuccess,
                        error: @escaping EWResponseFail){
        requestWith(url: url,
                    httpMethod: 1,
                    params: params,
                    success: success,
                    error: error)
    }
    ///核心方法
    class func requestWith(url: String,
                           httpMethod: Int32,
                           params: Dictionary<String,Any>?,
                           success: @escaping EWResponseSuccess,
                           error: @escaping EWResponseFail){
        if (self.baseUrl() == nil) {
            if URL(string: url) == nil{
                print("URLString无效")
                return
            }
        } else {
            if URL(string: "\(self.baseUrl()!)\(url)" ) == nil{
                print("URLString无效")
                return
            }
        }
        getManager()
        let encodingUrl = encodingURL(path: url)
        let absolute = absoluteUrlWithPath(path: encodingUrl)
        let lastUrl = buildAPIString(path: absolute)
        //打印header进行调试.
        if let params = params{
            print("\(lastUrl)\nheader =\(String(describing: ew_httpHeaders))\nparams = \(params)")
        }else {
            print("\(lastUrl)\nheader =\(String(describing: ew_httpHeaders))")
        }
        //get
        if httpMethod == 0{
            //无网络状态获取缓存
            if ew_NetworkStatus.rawValue == EWNetworkStatus.NotReachable.rawValue
                || ew_NetworkStatus.rawValue == EWNetworkStatus.Unknown.rawValue {
                let response = EWNetworking.cahceResponseWithURL(url: lastUrl,
                                                                 paramters: params)
                if response != nil{
                    self.successResponse(responseData: response!, callback: success)
                }else{
                    return
                }
            }
            manager?.request(lastUrl,
                             method: .get,
                             parameters: params,
                             encoding: URLEncoding.default,
                             headers: nil).responseJSON {
                                (response) in
                                switch response.result{
                                case .success:
                                    if let value = response.result.value as? Dictionary<String,Any>{
                                        ///添加一些全部接口都有的一些状态判断
                                        if value["status"] as! Int == 1010 {
                                            error("登录超时,请重新登录" as AnyObject)
                                            _ = Keychain.clear()
                                            return
                                        }
                                        success(value as AnyObject)
                                        //缓存数据
                                        self.cacheResponseObject(responseObject: value as AnyObject,
                                                                 request: response.request!,
                                                                 parameters: nil)
                                    }
                                case .failure(let err):
                                    error(err as AnyObject)
                                    debugPrint(err)
                                }
            }
        }else{
            //post
            manager?.request(lastUrl,
                             method: .post,
                             parameters: params!,
                             encoding: JSONEncoding.default,
                             headers: nil).responseJSON { (response) in
                                switch response.result{
                                case .success:
                                    ///添加一些全部接口都有的一些状态判断
                                    if let value = response.result.value as? Dictionary<String,Any> {
                                        if value["status"] as! Int == 1010 {
                                            error("登录超时,请重新登录" as AnyObject)
                                            _ = Keychain.clear()
                                            return
                                        }
                                        success(value as AnyObject)
                                    }
                                case .failure(let err):
                                    error(err as AnyObject)
                                    debugPrint(error)
                                }
            }
        }
    }
    class func updateBaseUrl(baseUrl:String){
        ew_privateNetworkBaseUrl = baseUrl
    }
    class func baseUrl()->String?{
        return ew_privateNetworkBaseUrl
    }
    //获取alamofire.manager
    class func getManager(){
        let config:URLSessionConfiguration = URLSessionConfiguration.default
        let serverTrustPolicies: [String: ServerTrustPolicy] = [
            ///正式环境的证书配置,修改成自己项目的正式url
            "www.baidu.com": .pinCertificates(
                certificates: ServerTrustPolicy.certificates(),
                validateCertificateChain: true,
                validateHost: true
            ),
            ///测试环境的证书配置,不验证证书,无脑通过
            "192.168.1.213:8002/": .disableEvaluation,
            ]
        config.httpAdditionalHeaders = ew_httpHeaders
        config.timeoutIntervalForRequest = ew_timeout
        //根据config创建manager
        manager = SessionManager(configuration: config,
                                 delegate: SessionDelegate(),
                                 serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies))
    }
    //中文路径encoding
    class func encodingURL(path: String)->String{
        return path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }
    //拼接baseurl生成完整url
    class func absoluteUrlWithPath(path:String?)->String{
        if path == nil
            || path?.length == 0 {
            return ""
        }
        if self.baseUrl() == nil
            || self.baseUrl()?.length == 0{
            return path!
        }
        var absoluteUrl = path
        if !(path?.hasPrefix("http://"))!
            && !(path?.hasPrefix("https://"))!{
            if (self.baseUrl()?.hasPrefix("/"))!{
                if (path?.hasPrefix("/"))!{
                    var mutablePath = path
                    mutablePath?.remove(at: (path?.startIndex)!)
                    absoluteUrl = self.baseUrl()! + mutablePath!
                }else{
                    absoluteUrl = self.baseUrl()! + path!
                }
            }else{
                if (path?.hasPrefix("/"))!{
                    absoluteUrl = self.baseUrl()! + path!
                }else{
                    absoluteUrl = self.baseUrl()! + "/" + path!
                }
            }
        }
        return absoluteUrl!
    }
    /// 在url最后添加一部分,这里是添加的选择语言,可以根据需求修改.
    class func buildAPIString(path:String)->String{
        if path.containsIgnoringCase(find: "http://")
            || path.containsIgnoringCase(find: "https://"){
            return path
        }
        let lang = "zh_CN"
        var str = ""
        if path.containsIgnoringCase(find: "?"){
            str = path + "&@lang=" + lang
        }else{
            str = path + "?@lang=" + lang
        }
        return str
    }
    ///从缓存中获取数据
    class func cahceResponseWithURL(url: String,paramters: Dictionary<String,Any>?) -> Any?{
        var cacheData:Any? = nil
        let directorPath = cachePath
        let absoluteURL = self.generateGETAbsoluteURL(url: url, paramters)
        ///使用md5进行加密
        let key = absoluteURL.md5()
        let path = directorPath.appending(key)
        let data:Data? = FileManager.default.contents(atPath: path)
        if data != nil{
            cacheData = data
            print("Read data from cache for url: \(url)\n")
        }
        return cacheData
    }
    //get请求下把参数拼接到url上
    class func generateGETAbsoluteURL(url: String,_ params: Dictionary<String,Any>?)->String{
        guard let params = params else {return url}
        if params.count == 0{
            return url
        }
        var url = url
        var queries = ""
        for key in (params.keys){
            let value = params[key]
            if value is Dictionary<String,Any>{
                continue
            }else if value is Array<Any>{
                continue
            }else if value is Set<AnyHashable>{
                continue
            }else{
                queries = queries.length == 0 ? "&" : queries + key + "=" + "\(value as! String)"
            }
        }
        if queries.length > 1{
            queries = String(queries[queries.startIndex..<queries.endIndex])
        }
        if (url.hasPrefix("http://")
            || url.hasPrefix("https://")
            && queries.length > 1){
            if url.containsIgnoringCase(find: "?")
                || url.containsIgnoringCase(find: "#"){
                url = "\(url)\(queries)"
            }else{
                queries = queries.stringCutToEnd(star: 1)
                url = "\(url)?\(queries)"
            }
        }
        return url.length == 0 ? queries : url
    }
    /// 进行数据缓存
    ///
    /// - Parameters:
    ///   - responseObject: 缓存数据
    ///   - request: 请求
    ///   - parameters: 参数
    class func cacheResponseObject(responseObject: AnyObject,
                                   request: URLRequest,
                                   parameters: Dictionary<String,Any>?){
        if !(responseObject is NSNull) {
            let directoryPath:String = cachePath
            ///如果没有目录,那么新建目录
            if !FileManager.default.fileExists(atPath: directoryPath, isDirectory: nil){
                do {
                    try FileManager.default.createDirectory(atPath: directoryPath,
                                                            withIntermediateDirectories: true,
                                                            attributes: nil)
                }catch let error {
                    print("create cache dir error: " + error.localizedDescription + "\n")
                    return
                }
            }
            ///将get请求下的参数拼接到url上
            let absoluterURL = self.generateGETAbsoluteURL(url: (request.url?.absoluteString)!, parameters)
            ///对url进行md5加密
            let key = absoluterURL.md5()
            ///将加密过的url作为目录拼接到默认路径
            let path = directoryPath.appending(key)
            ///将请求数据转换成data
            let dict:AnyObject = responseObject
            var data:Data? = nil
            do{
                try data = JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            }catch{
            }
            ///将data存储到指定路径
            if data != nil{
                let isOk = FileManager.default.createFile(atPath: path,
                                                          contents: data,
                                                          attributes: nil)
                if isOk{
                    print("cache file ok for request: \(absoluterURL)\n")
                }else{
                    print("cache file error for request: \(absoluterURL)\n")
                }
            }
        }
    }
    ///解析缓存数据
    class func successResponse(responseData: Any,callback success: EWResponseSuccess){
        success(self.tryToParseData(responseData: responseData))
    }
    ///解析数据
    class func tryToParseData(responseData: Any) -> AnyObject {
        if responseData is Data{
            do{
                let json =  try JSON(data: responseData as! Data)
                return json as AnyObject
            }catch{
                return responseData as AnyObject
            }
        }else{
            return responseData as AnyObject
        }
    }
    ///监听网络状态
    class func detectNetwork(netWorkStatus: @escaping ELNetworkStatus){
        let reachability = NetworkReachabilityManager()
        reachability?.startListening()
        reachability?.listener = { status in
            if reachability?.isReachable ?? false {
                switch status {
                case .notReachable:
                    ew_NetworkStatus = EWNetworkStatus.NotReachable
                case .unknown:
                    ew_NetworkStatus = EWNetworkStatus.Unknown
                case .reachable(.wwan):
                    ew_NetworkStatus = EWNetworkStatus.WWAN
                case .reachable(.ethernetOrWiFi):
                    ew_NetworkStatus = EWNetworkStatus.WiFi
                }
            }else{
                ew_NetworkStatus = EWNetworkStatus.NotReachable
            }
            netWorkStatus(ew_NetworkStatus.rawValue)
        }
    }
    ///监听网络状态
    class func obtainDataFromLocalWhenNetworkUnconnected(){
        self.detectNetwork { (CRNetworkStatus) in
        }
    }
}
