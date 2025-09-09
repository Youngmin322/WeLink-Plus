//
//  OnboardingViewModel.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/26/25.
//

import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var isTapped = false
    @Published var currentStep = 1
    
    private let totalSteps = 3
    
    // MARK: - Navigation
    func handleTap() {
        isTapped = true
    }
    
    func nextStep() {
        if currentStep < totalSteps {
            currentStep += 1
        }
    }
    
    func skipOnboarding() {
        currentStep = totalSteps + 1
    }
    
    // MARK: - Step Management
    var isFirstStep: Bool {
        currentStep == 1
    }
    
    var isSecondStep: Bool {
        currentStep == 2
    }
    
    var isThirdStep: Bool {
        currentStep == 3
    }
    
    var isFinalStep: Bool {
        currentStep > totalSteps
    }
    
    // MARK: - Content Data
    var currentStepTitle: String {
        switch currentStep {
        case 1:
            return "위링크가 처음이신가요?"
        case 2:
            return "당신의 취향을 기록하고,\n나를 표현해보세요"
        case 3:
            return "친구와 카드를 주고받으며\n서로의 취향을 확인해요"
        default:
            return ""
        }
    }
    
    var currentStepDescription: String {
        switch currentStep {
        case 1:
            return "말로 설명하기 어려운 내 취향, 분위기, 스타일을 이제 한 장의 '취향 카드'로 표현해보세요."
        case 2:
            return "좋아하는 색, 향, 스타일, 관심사까지 카드 한 장에 나를 담아 공유할 수 있어요"
        case 3:
            return "각자의 카드를 보며 서로를 더 잘 이해할 수 있어요"
        default:
            return ""
        }
    }
    
    var currentStepImage: String {
        switch currentStep {
        case 1:
            return "Onboarding2-1"
        case 2:
            return "Onboarding2-2"
        case 3:
            return "onboarding3"
        default:
            return ""
        }
    }
    
    // MARK: - Button Text
    var nextButtonText: String {
        if currentStep == totalSteps {
            return "Done"
        } else {
            return ""
        }
    }
    
    var showArrow: Bool {
        currentStep < totalSteps
    }
    
    var showDoneButton: Bool {
        currentStep == totalSteps
    }
    
    // MARK: - Indicator State
    func getIndicatorState(for index: Int) -> IndicatorState {
        if index == currentStep {
            return .active
        } else {
            return .inactive
        }
    }
    
    enum IndicatorState {
        case active
        case inactive
    }
}
