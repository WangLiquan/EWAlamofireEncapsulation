# AlamofireEncapsulation
<h3>对Alamofire进行封装</h3>
<p>实现了自动缓存,无网络时调用缓存数据,网络状态监听,默认header加入功能.</p>

<p>优化了请求方式,使用起来更轻便.</p>

<p>使用时将EWNetworking.swift,EWKeychain,String+Extension拖入项目,修改其中自己需要的属性.</p>

<p>如果不需要其中部分方法可以将其删除,例如keychain存储token,key的md5加密等.</p>

<p>具体使用方式不明确,或有任何问题与建议可以与我联系.</p>

# 使用方法示例:
```
///get请求demo
public func getDataTest(id: String,
success: @escaping EWResponseSuccess,
failure: @escaping EWResponseFail){
    let path = "test"
    EWNetworking.ShareInstance.getWith(url: path, params: ["id": id], success: { (response) in
        guard let json = response as? [String:Any] else { return }
            ///保证接口调通, 否则返回错误信息
            guard json["status"] as! NSNumber == 1 else {
            //                      MBProgressHud.showTextHudTips(message: json["msg"] as? String)
            print(json["msg"])
            failure(response)
            return
        }
        guard let dict = json["obj"] as? [String:Any] else {
            failure(NSError(domain: "转字典失败", code: 2000,    userInfo: nil))
            return
        }
        guard let dataArray = dict["data"] else {
            failure(NSError(domain: "获取数组失败", code: 2000, userInfo: nil))
            return
        }
        success(dataArray as AnyObject)
    }) { (error) in
        failure(error)
        //              MBProgressHud.showTextHudTips(message: "网络请求错误")
    }
}
```
```
func getDemo(){
    EWNetworking.ShareInstance.getDataTest(id: "1", success: { [weak self] (response) in
        guard let weakSelf = self else { return }
            guard let model = response as? [String] else { return }
                ///根据获取model来进行相应操作
    }) { (error) in
    }
}
```

