//
//  EWNetworking+test.swift
//  AlamofireEncapsulation
//
//  Created by Ethan.Wang on 2018/9/7.
//  Copyright © 2018年 Ethan. All rights reserved.
//

import Foundation

extension EWNetworking {
    ///get请求demo
    public func getDataTest(test: String,
                            success: @escaping EWResponseSuccess,
                            failure: @escaping EWResponseFail) {
        let path = "test"
        EWNetworking.ShareInstance.getWith(url: path, params: ["id": test], success: { (response) in
            guard let json = response as? [String: Any] else { return }
            ///保证接口调通, 否则返回错误信息
            guard json["status"] as? NSNumber == 1 else {
//                MBProgressHud.showTextHudTips(message: json["msg"] as? String)
                print(json["msg"] as? String ?? "")
                failure(response)
                return
            }
            guard let dict = json["obj"] as? [String: Any] else {
                failure(NSError(domain: "转字典失败", code: 2000, userInfo: nil))
                return
            }
            guard let dataArray = dict["data"] else {
                failure(NSError(domain: "获取数组失败", code: 2000, userInfo: nil))
                return
            }
            success(dataArray as AnyObject)
        },error: { (error) in
            failure(error)
//            MBProgressHud.showTextHudTips(message: "网络请求错误")
        })
    }
    ///post请求demo
    public func postDataTest(test: String,
                             success: @escaping EWResponseSuccess,
                             failure: @escaping EWResponseFail) {
        let path = "v1/passport/register"
        EWNetworking.ShareInstance.postWith(url: path, params: ["id": test], success: { (response) in
            guard let json = response as? [String: Any] else { return }
            guard json["status"] as? NSNumber == 1 else {
                //                MBProgressHud.showTextHudTips(message: json["msg"] as? String)
                print(json["msg"] as? String ?? "")
                failure(response)
                return
            }
            success(response as AnyObject)
        },error: { (error) in
            failure(error)
            //            MBProgressHud.showTextHudTips(message: "网络请求错误")
        })
    }
}
