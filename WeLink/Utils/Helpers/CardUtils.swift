//
//  CardUtils.swift
//  WeLink
//
//  Created by 조영민 on 8/11/25.
//

import SwiftUI

// MARK: - Card Array Extensions
extension Array where Element == CardModel {
    func safeIndex(_ index: Int) -> Int {
        guard !isEmpty else { return 0 }
        let clampedIndex = index < 0 ? 0 : (index >= count ? count - 1 : index)
        return clampedIndex
    }
}

// MARK: - Collection Extensions
extension Collection {
    func safeIndex(_ index: Int) -> Int {
        guard !isEmpty else { return 0 }
        return Swift.max(0, Swift.min(index, count - 1))
    }
}
