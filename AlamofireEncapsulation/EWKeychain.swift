//
//  CRKeychain.swift
//  Group
//
//  Created by 新用户 on 2018/7/27.
//  Copyright © 2018年 Chuangrong. All rights reserved.
//

import UIKit
import Security
class Keychain {
    class func save(key: String, data: Data) -> Bool {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ] as [String : Any]
        SecItemDelete(query as CFDictionary)
        let status: OSStatus = SecItemAdd(query as CFDictionary, nil)
        return status == noErr
    }
    class func load(key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]
        var dataTypeRef: AnyObject?
        let status = withUnsafeMutablePointer(to: &dataTypeRef) { SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0)) }
        
        if status == errSecSuccess {
            if let data = dataTypeRef as! Data? {
                return data
            }
        }
        return nil
    }
    class func delete(key: String) -> Bool {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key ] as [String : Any]
        
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        return status == noErr
    }
    class func clear() -> Bool {
        let query = [ kSecClass as String : kSecClassGenericPassword ]
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        return status == noErr
    }
}
