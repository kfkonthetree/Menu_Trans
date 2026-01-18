//
//  Item.swift
//  Menu_trans
//
//  Created by 谢甲腾 on 2025/7/19.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
