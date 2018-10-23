//
//  ViewController.swift
//  AlamofireEncapsulation
//
//  Created by Ethan.Wang on 2018/9/7.
//  Copyright © 2018年 Ethan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        getDemo()
        postDemo()
    }
    func getDemo(){
        EWNetworking.ShareInstance.getDataTest(id: "1", success: { [weak self] (response) in
            guard let weakSelf = self else { return }
            guard let model = response as? [String] else { return }
            ///根据获取model来进行相应操作
        }) { (error) in
        }
    }
    func postDemo(){
        EWNetworking.ShareInstance.postDataTest(id: "1", success: { [weak self] (response) in
            guard let weakSelf = self else { return }
            guard let model = response as? [String] else { return }
            ///根据获取model来进行相应操作
        }) { (error) in
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

