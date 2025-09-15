import SwiftUI
import UIKit

/// Call this once at app launch (e.g., in your App struct's init) to apply a system-style
/// "Liquid Glass" appearance to all UITabBar instances while keeping the system TabView.
public func configureLiquidGlassTabBar(
    iconHorizontalOffset: CGFloat = 2,
    titleHorizontalOffset: CGFloat = 1,
    useChromeMaterial: Bool = true
) {
    let appearance = UITabBarAppearance()

    // Start clean and opt into a translucent, glass-like background.
    appearance.configureWithTransparentBackground()

    // Apply a material-like blur effect so the bar feels like "liquid glass".
    // .systemChromeMaterial is subtle and cohesive with iOS 26 system bars.
    if useChromeMaterial {
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
    } else {
        // Alternative: slightly stronger look
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
    }

    // Optional: add a faint background color to improve contrast if needed.
    // Keep alpha low to preserve the glass effect.
    appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.05)

    // Slightly adjust icon/title positions to create a bit more visual breathing room.
    let iconOffset = UIOffset(horizontal: iconHorizontalOffset, vertical: 0)
    let titleOffset = UIOffset(horizontal: titleHorizontalOffset, vertical: 0)

    // Stacked (regular) layout
    appearance.stackedLayoutAppearance.normal.iconPositionAdjustment = iconOffset
    appearance.stackedLayoutAppearance.selected.iconPositionAdjustment = iconOffset
    appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = titleOffset
    appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = titleOffset

    // Inline layout
    appearance.inlineLayoutAppearance.normal.titlePositionAdjustment = titleOffset
    appearance.inlineLayoutAppearance.selected.titlePositionAdjustment = titleOffset

    // Compact inline layout
    appearance.compactInlineLayoutAppearance.normal.titlePositionAdjustment = titleOffset
    appearance.compactInlineLayoutAppearance.selected.titlePositionAdjustment = titleOffset

    // Apply to all tab bars in the app.
    let tabBar = UITabBar.appearance()
    tabBar.standardAppearance = appearance
    tabBar.scrollEdgeAppearance = appearance

    // Ensure translucency so content can softly show through.
    tabBar.isTranslucent = true
}

#if DEBUG
// Simple preview helper to visualize the effect in a SwiftUI preview if needed.
struct _LiquidGlassTabBarPreview: View {
    init() {
        configureLiquidGlassTabBar()
    }
    var body: some View {
        TabView {
            Color.blue.opacity(0.2).ignoresSafeArea().tabItem { Label("홈", systemImage: "house.fill") }
            Color.green.opacity(0.2).ignoresSafeArea().tabItem { Label("탐색", systemImage: "magnifyingglass") }
            Color.pink.opacity(0.2).ignoresSafeArea().tabItem { Label("프로필", systemImage: "person.fill") }
        }
    }
}

#Preview("Liquid Glass Tab Bar") {
    _LiquidGlassTabBarPreview()
}
#endif
