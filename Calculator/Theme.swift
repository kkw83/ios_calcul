import SwiftUI

/// 라이트/다크 모드에 대응하는 계산기 색상 팔레트.
struct CalculatorTheme {
    let scheme: ColorScheme

    var isDark: Bool { scheme == .dark }

    var background: LinearGradient {
        LinearGradient(
            colors: isDark
                ? [Color(red: 0.08, green: 0.08, blue: 0.09), Color(red: 0.0, green: 0.0, blue: 0.0)]
                : [Color(red: 0.99, green: 0.99, blue: 1.0), Color(red: 0.93, green: 0.93, blue: 0.95)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var primaryText: Color {
        isDark ? .white : Color(red: 0.07, green: 0.07, blue: 0.08)
    }

    var secondaryText: Color {
        isDark ? .white.opacity(0.45) : .black.opacity(0.4)
    }

    var digitFill: Color {
        isDark ? Color(red: 0.19, green: 0.19, blue: 0.20) : .white
    }

    var digitText: Color {
        isDark ? .white : Color(red: 0.07, green: 0.07, blue: 0.08)
    }

    var functionFill: Color {
        isDark ? Color(red: 0.64, green: 0.64, blue: 0.66) : Color(red: 0.85, green: 0.85, blue: 0.87)
    }

    var functionText: Color {
        isDark ? .black : Color(red: 0.1, green: 0.1, blue: 0.1)
    }

    var accent: Color {
        Color(red: 1.0, green: 0.58, blue: 0.04)
    }

    var accentText: Color { .white }

    var selectedAccentFill: Color {
        isDark ? .white : accent
    }

    var selectedAccentText: Color {
        isDark ? accent : .white
    }

    var chrome: Color {
        isDark ? .white.opacity(0.8) : .black.opacity(0.65)
    }

    var chromeBackground: Color {
        isDark ? .white.opacity(0.09) : .black.opacity(0.05)
    }

    var keyShadow: Color {
        .black.opacity(isDark ? 0.35 : 0.08)
    }

    var rowBackground: Color {
        isDark ? .white.opacity(0.06) : .white.opacity(0.85)
    }
}
