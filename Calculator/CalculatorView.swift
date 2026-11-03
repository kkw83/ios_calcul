import SwiftUI
import UIKit

// MARK: - 키 정의

private enum KeyAction: Hashable {
    case digit(Character)
    case decimal
    case sign
    case percent
    case clear
    case operation(BinaryOperation)
    case equals
    case unary(UnaryOperation)
    case constant(MathConstant)
    case angle
}

private struct KeypadKey: Identifiable {
    let id: String
    let title: String
    let style: KeyStyle
    let action: KeyAction
    var isWide = false
    var fontScale: CGFloat = 1
    var accessibilityLabel = ""
}

// MARK: - 화면

struct CalculatorView: View {
    @State private var model = CalculatorModel()
    @State private var showsHistory = false
    @AppStorage("calculator.showsScientific") private var showsScientific = false
    @Environment(\.colorScheme) private var colorScheme

    private var theme: CalculatorTheme { CalculatorTheme(scheme: colorScheme) }
    private var rowCount: Int { showsScientific ? 8 : 5 }
    private var displayHeight: CGFloat { showsScientific ? 118 : 150 }

    var body: some View {
        GeometryReader { proxy in
            let metrics = KeypadMetrics(
                size: proxy.size,
                rows: rowCount,
                displayHeight: displayHeight
            )

            VStack(spacing: 0) {
                topBar
                    .frame(height: 44)

                DisplayView(
                    expression: model.expression,
                    text: model.displayText,
                    theme: theme
                )
                .frame(height: displayHeight)
                .contextMenu {
                    Button {
                        copyDisplay()
                    } label: {
                        Label("복사", systemImage: "doc.on.doc")
                    }
                }

                Spacer(minLength: 8)

                keypad(metrics: metrics)
                    .frame(height: metrics.keypadHeight)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.background.ignoresSafeArea())
        }
        .sheet(isPresented: $showsHistory) {
            HistoryView(entries: model.history, theme: theme) { entry in
                model.useHistoryEntry(entry)
            } onClear: {
                model.clearHistory()
            }
        }
    }

    // MARK: 상단 바

    private var topBar: some View {
        HStack(spacing: 10) {
            chromeButton(
                systemName: "clock.arrow.circlepath",
                label: "계산 기록"
            ) {
                showsHistory = true
            }

            Spacer(minLength: 0)

            if showsScientific {
                Button {
                    model.toggleAngleMode()
                    Haptics.tap()
                } label: {
                    Text(model.angleLabel)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(theme.accent.opacity(0.15), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    "각도 단위 전환, 현재 \(model.angleMode == .degrees ? "도" : "라디안")"
                )
            }

            chromeButton(
                systemName: "function",
                label: showsScientific ? "공학용 키패드 숨기기" : "공학용 키패드 표시",
                isActive: showsScientific
            ) {
                showsScientific.toggle()
            }
        }
    }

    private func chromeButton(
        systemName: String,
        label: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isActive ? theme.accent : theme.chrome)
                .frame(width: 40, height: 40)
                .background(
                    isActive ? theme.accent.opacity(0.16) : theme.chromeBackground,
                    in: Circle()
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: 키패드

    private func keypad(metrics: KeypadMetrics) -> some View {
        let rows = keypadRows
        return VStack(spacing: metrics.spacing) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: metrics.spacing) {
                    ForEach(rows[rowIndex]) { key in
                        CalculatorButton(
                            title: key.title,
                            style: key.style,
                            theme: theme,
                            width: key.isWide
                                ? metrics.buttonWidth * 2 + metrics.spacing
                                : metrics.buttonWidth,
                            height: metrics.buttonHeight,
                            fontScale: key.fontScale,
                            accessibilityLabel: key.accessibilityLabel
                        ) {
                            perform(key.action)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var keypadRows: [[KeypadKey]] {
        var rows: [[KeypadKey]] = []
        if showsScientific {
            rows.append(contentsOf: scientificRows)
        }

        rows.append([
            KeypadKey(
                id: "clear",
                title: model.clearKeyLabel,
                style: .function,
                action: .clear,
                accessibilityLabel: model.clearKeyLabel == "AC" ? "모두 지우기" : "입력 지우기"
            ),
            KeypadKey(id: "sign", title: "±", style: .function, action: .sign, accessibilityLabel: "부호 변경"),
            KeypadKey(id: "percent", title: "%", style: .function, action: .percent, accessibilityLabel: "퍼센트"),
            binaryKey(.divide)
        ])

        rows.append(digitRow("7", "8", "9", operation: .multiply))
        rows.append(digitRow("4", "5", "6", operation: .subtract))
        rows.append(digitRow("1", "2", "3", operation: .add))

        rows.append([
            KeypadKey(id: "digit-0", title: "0", style: .digit, action: .digit("0"), isWide: true),
            KeypadKey(id: "decimal", title: ".", style: .digit, action: .decimal, accessibilityLabel: "소수점"),
            KeypadKey(id: "equals", title: "=", style: .accent, action: .equals, accessibilityLabel: "같음")
        ])

        return rows
    }

    private var scientificRows: [[KeypadKey]] {
        [
            [
                unaryKey(.sine),
                unaryKey(.cosine),
                unaryKey(.tangent),
                unaryKey(.naturalLog)
            ],
            [
                unaryKey(.commonLog),
                unaryKey(.squareRoot),
                unaryKey(.square),
                unaryKey(.reciprocal)
            ],
            [
                binaryKey(.power),
                constantKey(.pi),
                constantKey(.e),
                angleKey
            ]
        ]
    }

    private func digitRow(
        _ first: String,
        _ second: String,
        _ third: String,
        operation: BinaryOperation
    ) -> [KeypadKey] {
        [
            digitKey(first),
            digitKey(second),
            digitKey(third),
            binaryKey(operation)
        ]
    }

    private func digitKey(_ digit: String) -> KeypadKey {
        KeypadKey(id: "digit-\(digit)", title: digit, style: .digit, action: .digit(Character(digit)))
    }

    private func binaryKey(_ operation: BinaryOperation) -> KeypadKey {
        KeypadKey(
            id: "operation-\(operation.id)",
            title: operation.rawValue,
            style: model.highlightedOperation == operation ? .selectedAccent : .accent,
            action: .operation(operation),
            fontScale: operation == .power ? 0.8 : 1,
            accessibilityLabel: operation.accessibilityLabel
        )
    }

    private func unaryKey(_ operation: UnaryOperation) -> KeypadKey {
        KeypadKey(
            id: "unary-\(operation.id)",
            title: operation.rawValue,
            style: .function,
            action: .unary(operation),
            fontScale: 0.95,
            accessibilityLabel: operation.accessibilityLabel
        )
    }

    private func constantKey(_ constant: MathConstant) -> KeypadKey {
        KeypadKey(
            id: "constant-\(constant.id)",
            title: constant.rawValue,
            style: .function,
            action: .constant(constant),
            accessibilityLabel: constant.accessibilityLabel
        )
    }

    private var angleKey: KeypadKey {
        KeypadKey(
            id: "angle",
            title: model.angleLabel,
            style: .function,
            action: .angle,
            fontScale: 0.85,
            accessibilityLabel: "각도 단위 전환, 현재 \(model.angleMode == .degrees ? "도" : "라디안")"
        )
    }

    // MARK: 동작

    private func perform(_ action: KeyAction) {
        switch action {
        case .digit(let digit):
            model.inputDigit(digit)
        case .decimal:
            model.inputDecimalPoint()
        case .sign:
            model.toggleSign()
        case .percent:
            model.percent()
        case .clear:
            model.clear()
        case .operation(let operation):
            model.setOperation(operation)
        case .equals:
            model.equals()
        case .unary(let operation):
            model.applyUnary(operation)
        case .constant(let constant):
            model.insertConstant(constant)
        case .angle:
            model.toggleAngleMode()
        }

        if case .equals = action {
            Haptics.result()
        } else {
            Haptics.tap()
        }
    }

    private func copyDisplay() {
        UIPasteboard.general.string = CalcNumber.string(from: model.displayValue)
        Haptics.tap()
    }
}

// MARK: - 레이아웃 계산

private struct KeypadMetrics {
    let rows: Int
    let spacing: CGFloat
    let buttonWidth: CGFloat
    let buttonHeight: CGFloat

    var keypadHeight: CGFloat {
        buttonHeight * CGFloat(rows) + spacing * CGFloat(rows - 1)
    }

    init(size: CGSize, rows: Int, displayHeight: CGFloat) {
        self.rows = rows
        let gap: CGFloat = 10
        self.spacing = gap

        let availableWidth = max(0, size.width - 32)
        let width = (availableWidth - gap * 3) / 4
        self.buttonWidth = max(0, width)

        let reserved = 8 + 44 + displayHeight + 8 + 10
        let availableHeight = size.height - reserved
        let fitted = (availableHeight - gap * CGFloat(rows - 1)) / CGFloat(rows)
        self.buttonHeight = max(40, min(width * 1.15, min(fitted, 96)))
    }
}

#Preview {
    CalculatorView()
}
