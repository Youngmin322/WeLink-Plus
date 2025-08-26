//
//  AnimationConstants.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/26/25.
//

import SwiftUI

// MARK: - Animation Constants
struct AnimationConstants {
    static let cardTransition = Animation.easeInOut(duration: 0.3)
    static let indexChange = Animation.easeInOut(duration: 0.2)
    static let dragResponse = Animation.spring(response: 0.8, dampingFraction: 0.7)
    static let deleteButton = Animation.spring(response: 0.5, dampingFraction: 0.8)
}
