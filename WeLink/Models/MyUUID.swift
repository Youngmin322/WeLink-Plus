//
//  MyUUID.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/26/25.
//

import Foundation
import SwiftData

@Model
class MyUUID {
    var id: UUID
    
    init(id: UUID) {
        self.id = id
    }
}
