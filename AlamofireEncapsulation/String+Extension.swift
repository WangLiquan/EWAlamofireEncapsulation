//
//  String+Extension.swift
//  AlamofireEncapsulation
//
//  Created by Ethan.Wang on 2018/9/7.
//  Copyright © 2018年 Ethan. All rights reserved.
//

import Foundation

extension String {
    var length: Int {
        ///更改成其他的影响含有emoji协议的签名
        return self.utf16.count
    }
    ///是否包含字符串
    func containsIgnoringCase(find: String) -> Bool {
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    ///md5加密,添加这个方法后还要添加与oc的bridging文件
    func md5() -> String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)

        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for num in 0 ..< digestLen {
            hash.appendFormat("%02x", result[num])
        }
        result.deinitialize(count: 1)

        return String(format: hash as String)
    }
    /// 截取任意位置到结束
    ///
    /// - Parameter end:
    /// - Returns: 截取后的字符串
    func stringCutToEnd(star: Int) -> String {
        if !(star < count) { return "截取超出范围" }
        let sRang = index(startIndex, offsetBy: star)..<endIndex
        return String(self[sRang])
//        return substring(with: sRang)
    }

}
