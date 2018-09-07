//
//  EWNetworking+test.swift
//  AlamofireEncapsulation
//
//  Created by Ethan.Wang on 2018/9/7.
//  Copyright © 2018年 Ethan. All rights reserved.
//

import Foundation

extension EWNetworking{
    ///get请求demo
    class func getDataTest(id: String,
                       success: @escaping EWResponseSuccess,
                       failure: @escaping EWResponseFail){
        let path = "/test"
        EWNetworking.getWith(url: path, params: ["id": id], success: { (response) in
            guard let json = response as? [String:Any] else { return }
            ///保证接口调通, 否则返回错误信息
            guard json["status"] as! NSNumber == 1 else {
//                MBProgressHud.showTextHudTips(message: json["msg"] as? String)
                print(json["msg"])
                failure(response)
                return
            }
            guard let dict = json["obj"] as? [String:Any] else {
                failure(NSError(domain: "转字典失败", code: 2000, userInfo: nil))
                return
            }
            guard let dataArray = dict["data"] else {
                failure(NSError(domain: "获取数组失败", code: 2000, userInfo: nil))
                return
            }
            success(dataArray as AnyObject)
        }) { (error) in
            failure(error)
//            MBProgressHud.showTextHudTips(message: "网络请求错误")
        }
    }
    ///post请求demo
    class func postDataTest(id: String,
                                success: @escaping EWResponseSuccess,
                                failure: @escaping EWResponseFail){
        let path = "/activity_enroll"
        EWNetworking.postWith(url: path, params: ["id": id], success: { (response) in
            guard let json = response as? [String:Any] else { return }
            guard json["status"] as! NSNumber == 1 else {
//                MBProgressHud.showTextHudTips(message: json["msg"] as? String)
                print(json["msg"])
                failure(response)
                return
            }
            success(response as AnyObject)
        }) { (error) in
            failure(error)
//            MBProgressHud.showTextHudTips(message: "网络请求错误")
        }
    }
}
