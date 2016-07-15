//
//  DataModel.swift
//  Cell自适应
//
//  Created by 刘浩浩 on 16/7/13.
//  Copyright © 2016年 CodingFire. All rights reserved.
//

import UIKit

class DataModel: NSObject {

    
    var text:String?
    var url:String?
    
    
    override func setValue(value: AnyObject?, forUndefinedKey key: String) {

    }
    override func valueForUndefinedKey(key: String) -> AnyObject? {
        return nil
    }
 
    
}
