//
//  Item.swift
//  BookDiscovery
//
//  Created by Jann Aleli Zaplan on 2026-07-20.
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
