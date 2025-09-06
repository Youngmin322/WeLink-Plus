//
//  OnboardingView.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/26/25.
//

import SwiftUI

// MARK: - Notification Extension
extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showProfileCustomView = false
    
    var body: some View {
        ZStack {
            Color(hex: "#2C2C2C")
                .ignoresSafeArea()
            
            if viewModel.isFinalStep {
                FinalView(showProfileCustomView: $showProfileCustomView)
            } else if viewModel.currentStep == 1 && !viewModel.isTapped {
                InitialView()
                    .onTapGesture {
                        viewModel.handleTap()
                    }
            } else {
                OnboardingStepView(viewModel: viewModel)
            }
        }
        .fullScreenCover(isPresented: $showProfileCustomView) {
            ProfileCustomView(progress: 0.25, isEdit: false)
        }
    }
}

// MARK: - Initial View
struct InitialView: View {
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                Rectangle()
                    .fill(Color(hex: "#2C2C2C"))
                    .frame(width: 180, height: 180)
                    .cornerRadius(30)
                    .shadow(color: Color.white.opacity(0.45), radius: 10, x: 0, y: 4)
                
                Image("AppiconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
            }
            
            Text("WeLink")
                .font(.system(size: 55, weight: .bold))
                .foregroundStyle(.white)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding Step View
struct OnboardingStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ZStack {
            Color(hex: "#2C2C2C")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer().frame(height: 140)
                
                Image(viewModel.currentStepImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 240, height: 240)
                
                Spacer().frame(height: 150)
                
                Text(viewModel.currentStepTitle)
                    .font(.system(size: viewModel.isThirdStep ? 25 : 30, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, viewModel.isThirdStep ? 20 : 50)
                
                Spacer().frame(height: 20)
                
                Text(viewModel.currentStepDescription)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#848484"))
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                OnboardingBottomNavigation(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Bottom Navigation
struct OnboardingBottomNavigation: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                viewModel.skipOnboarding()
            }) {
                Text("Skip")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "#C0FF00"))
                    .padding(.leading, 30)
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                ForEach(1...3, id: \.self) { index in
                    if index == viewModel.currentStep {
                        Capsule()
                            .fill(Color(hex: "#C0FF00"))
                            .frame(width: 20, height: 10)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 10, height: 10)
                    }
                }
            }
            
            Spacer()
            
            if viewModel.showDoneButton {
                Button(action: {
                    viewModel.skipOnboarding()
                }) {
                    Text("Done")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#C0FF00"))
                        .padding(.trailing, 30)
                }
            } else if viewModel.showArrow {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.nextStep()
                    }
                }) {
                    Image(systemName: "arrow.forward")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#C0FF00"))
                        .padding(.trailing, 30)
                }
            } else {
                Color.clear
                    .frame(width: 60, height: 40)
            }
        }
        .frame(height: 70)
        .padding(.bottom, 10)
    }
}

// MARK: - Final View
struct FinalView: View {
    @Binding var showProfileCustomView: Bool
    
    var body: some View {
        ZStack {
            Color(hex: "#C0FF00")
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                ZStack {
                    Rectangle()
                        .fill(Color(hex: "#2C2C2C"))
                        .frame(width: 180, height: 180)
                        .cornerRadius(30)
                        .shadow(color: Color.white.opacity(0.45), radius: 10, x: 0, y: 4)
                    
                    Image("AppiconImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                }
                
                Text("WeLink")
                    .font(.system(size: 55, weight: .bold))
                    .foregroundStyle(.black)
                
                Spacer()
                
                Button(action: {
                    completeOnboarding()
                }) {
                    Text("시작하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 135)
                        .padding(.vertical, 18)
                        .background(Color(hex: "#2C2C2C"))
                        .cornerRadius(30)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    private func completeOnboarding() {
        print("온보딩 완료 처리 시작")
        
        // 온보딩 완료 상태 저장
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        print("UserDefaults에 온보딩 완료 상태 저장됨")
        
        // 상위 뷰에 완료 알림
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
        print("온보딩 완료 알림 전송됨")
        
        // ProfileCustomView로 화면 전환
        showProfileCustomView = true
    }
}

#Preview {
    OnboardingView()
}
