import SwiftUI

/// 수식(작게)과 결과(크게)를 오른쪽 정렬로 보여주는 디스플레이.
struct DisplayView: View {
    let expression: String
    let text: String
    let theme: CalculatorTheme

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Spacer(minLength: 0)

            Text(expression.isEmpty ? " " : expression)
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .animation(.easeOut(duration: 0.15), value: expression)

            Text(text)
                .font(.system(size: fontSize, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.18), value: text)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(expression.isEmpty ? text : "\(expression), \(text)")
    }

    private var fontSize: CGFloat {
        switch text.count {
        case 0...8: return 74
        case 9: return 68
        case 10: return 62
        case 11: return 56
        case 12: return 50
        case 13: return 46
        default: return 40
        }
    }
}

#Preview {
    ZStack {
        CalculatorTheme(scheme: .dark).background.ignoresSafeArea()
        DisplayView(
            expression: "1,234 × 56",
            text: "69,104",
            theme: CalculatorTheme(scheme: .dark)
        )
    }
}
