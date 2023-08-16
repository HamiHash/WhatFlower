//
//  FlowerModel.swift
//  WhatFlower
//
//  Created by Hamed Hashemi on 8/16/23.
//

import Foundation
import SwiftyJSON

struct FlowerModel {
    var description: String?
    
    init(json: JSON) {
        self.description = json["pages"].stringValue
    }
}
