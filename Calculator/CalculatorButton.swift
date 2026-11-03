import SwiftUI

/// 버튼 종류에 따른 색상/폰트 스타일.
enum KeyStyle: Equatable {
    case digit
    case function
    case accent
    case selectedAccent
}

/// 계산기 키 하나를 그리는 공용 버튼.
struct CalculatorButton: View {
    let title: String
    let style: KeyStyle
    let theme: CalculatorTheme
    let width: CGFloat
    let height: CGFloat
    var fontScale: CGFloat = 1
    var accessibilityLabel: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: fontSize, weight: .medium, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(foregroundColor)
                .frame(width: width, height: height)
                .background(backgroundColor)
                .clipShape(Capsule())
                .overlay {
                    if style == .digit {
                        Capsule()
                            .strokeBorder(theme.primaryText.opacity(theme.isDark ? 0.05 : 0.04))
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(accessibilityLabel.isEmpty ? title : accessibilityLabel)
    }

    private var fontSize: CGFloat {
        let base = min(width, height)
        switch style {
        case .digit:
            return base * 0.42 * fontScale
        case .accent, .selectedAccent:
            return base * 0.45 * fontScale
        case .function:
            return base * 0.33 * fontScale
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .digit: return theme.digitFill
        case .function: return theme.functionFill
        case .accent: return theme.accent
        case .selectedAccent: return theme.selectedAccentFill
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .digit: return theme.digitText
        case .function: return theme.functionText
        case .accent: return theme.accentText
        case .selectedAccent: return theme.selectedAccentText
        }
    }
}

/// 눌렀을 때 살짝 줄어드는 iOS 계산기 느낌의 버튼 스타일.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
