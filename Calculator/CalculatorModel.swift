import Foundation
import Observation

// MARK: - Operations

enum BinaryOperation: String, CaseIterable, Identifiable {
    case add = "+"
    case subtract = "−"
    case multiply = "×"
    case divide = "÷"
    case power = "xʸ"

    var id: String { rawValue }

    var accessibilityLabel: String {
        switch self {
        case .add: return "더하기"
        case .subtract: return "빼기"
        case .multiply: return "곱하기"
        case .divide: return "나누기"
        case .power: return "거듭제곱"
        }
    }
}

enum UnaryOperation: String, CaseIterable, Identifiable {
    case sine = "sin"
    case cosine = "cos"
    case tangent = "tan"
    case naturalLog = "ln"
    case commonLog = "log"
    case squareRoot = "√"
    case square = "x²"
    case reciprocal = "1/x"

    var id: String { rawValue }

    var accessibilityLabel: String {
        switch self {
        case .sine: return "사인"
        case .cosine: return "코사인"
        case .tangent: return "탄젠트"
        case .naturalLog: return "자연 로그"
        case .commonLog: return "상용 로그"
        case .squareRoot: return "제곱근"
        case .square: return "제곱"
        case .reciprocal: return "역수"
        }
    }
}

enum MathConstant: String, Identifiable {
    case pi = "π"
    case e = "e"

    var id: String { rawValue }

    var value: Decimal {
        switch self {
        case .pi: return Decimal(string: "3.14159265358979", locale: CalcNumber.posix) ?? 0
        case .e: return Decimal(string: "2.71828182845905", locale: CalcNumber.posix) ?? 0
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .pi: return "파이"
        case .e: return "자연 상수 이"
        }
    }
}

enum AngleMode: String, Codable, CaseIterable {
    case degrees = "Deg"
    case radians = "Rad"

    var toggled: AngleMode {
        self == .degrees ? .radians : .degrees
    }
}

struct HistoryEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    let expression: String
    let result: String
    let value: Decimal
    var date = Date()
}

// MARK: - Model

/// 계산기 상태와 연산 엔진. 즉시 실행(immediate execution) 방식으로 동작한다.
@Observable
final class CalculatorModel {

    // MARK: 공개 상태

    private(set) var rawInput = "0"
    private(set) var expression = ""
    private(set) var isError = false
    private(set) var history: [HistoryEntry] = []
    private(set) var angleMode: AngleMode = .degrees

    // MARK: 엔진 내부 상태

    private var accumulator: Decimal?
    private var pendingOperation: BinaryOperation?
    private var startsNewEntry = true
    private var lastOperation: BinaryOperation?
    private var lastOperand: Decimal?

    private let defaults: UserDefaults

    private enum StorageKey {
        static let history = "calculator.history"
        static let angleMode = "calculator.angleMode"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadPersistedState()
    }

    // MARK: - 화면 표시용 값

    var displayText: String {
        isError ? "Error" : CalcNumber.grouped(rawInput)
    }

    var displayValue: Decimal { currentValue }

    var clearKeyLabel: String { canResetAll ? "AC" : "C" }

    var highlightedOperation: BinaryOperation? { pendingOperation }

    var angleLabel: String { angleMode.rawValue }

    // MARK: - 입력

    func inputDigit(_ digit: Character) {
        guard !isError, digit.isNumber else { return }

        if startsNewEntry {
            rawInput = String(digit)
            startsNewEntry = false
            if pendingOperation == nil { expression = "" }
        } else {
            guard significantDigitCount < 15 else { return }
            if rawInput == "0" {
                rawInput = String(digit)
            } else if rawInput == "-0" {
                rawInput = "-" + String(digit)
            } else {
                rawInput.append(digit)
            }
        }
    }

    func inputDecimalPoint() {
        guard !isError else { return }

        if startsNewEntry {
            rawInput = "0."
            startsNewEntry = false
            if pendingOperation == nil { expression = "" }
        } else if !rawInput.contains(".") {
            rawInput.append(".")
        }
    }

    func toggleSign() {
        guard !isError, currentValue != 0 else { return }
        if rawInput.hasPrefix("-") {
            rawInput.removeFirst()
        } else {
            rawInput = "-" + rawInput
        }
        if pendingOperation != nil {
            startsNewEntry = false
        }
    }

    func percent() {
        guard !isError else { return }

        let value = currentValue
        let result: Decimal
        if let pending = pendingOperation,
           let acc = accumulator,
           pending == .add || pending == .subtract {
            result = acc * value / 100
        } else {
            result = value / 100
        }

        guard let valid = validated(result) else {
            fail()
            return
        }
        expression = "\(format(value))%"
        setCurrent(valid, startsNewEntry: pendingOperation == nil)
    }

    func clear() {
        if canResetAll {
            resetAll()
        } else {
            clearEntry()
        }
    }

    // MARK: - 이항 연산

    func setOperation(_ operation: BinaryOperation) {
        guard !isError else { return }

        // 연산자를 연달아 누르면 마지막 연산자로 교체한다.
        if startsNewEntry, pendingOperation != nil {
            pendingOperation = operation
            lastOperation = nil
            lastOperand = nil
            expression = "\(format(accumulator ?? 0)) \(operation.rawValue)"
            return
        }

        let value = currentValue

        if let pending = pendingOperation, let acc = accumulator {
            guard let result = apply(pending, acc, value) else {
                fail()
                return
            }
            accumulator = result
            setCurrent(result)
        } else {
            accumulator = value
            setCurrent(value)
        }

        pendingOperation = operation
        lastOperation = nil
        lastOperand = nil
        startsNewEntry = true
        expression = "\(format(accumulator ?? 0)) \(operation.rawValue)"
    }

    func equals() {
        guard !isError else { return }

        if let pending = pendingOperation, let acc = accumulator {
            let rhs = startsNewEntry ? acc : currentValue

            guard let result = apply(pending, acc, rhs) else {
                fail()
                return
            }

            let calculation = "\(format(acc)) \(pending.rawValue) \(format(rhs))"
            record(expression: calculation, result: result)
            expression = calculation + " ="
            setCurrent(result)
            accumulator = result
            lastOperation = pending
            lastOperand = rhs
            pendingOperation = nil
        } else if let operation = lastOperation, let operand = lastOperand {
            let lhs = currentValue

            guard let result = apply(operation, lhs, operand) else {
                fail()
                return
            }

            let calculation = "\(format(lhs)) \(operation.rawValue) \(format(operand))"
            record(expression: calculation, result: result)
            expression = calculation + " ="
            setCurrent(result)
            accumulator = result
        } else {
            expression = "\(format(currentValue)) ="
            setCurrent(currentValue)
            accumulator = currentValue
        }

        startsNewEntry = true
    }

    // MARK: - 단항 연산

    func applyUnary(_ operation: UnaryOperation) {
        guard !isError else { return }

        let value = currentValue
        let doubleValue = NSDecimalNumber(decimal: value).doubleValue
        let result: Decimal?

        switch operation {
        case .square:
            result = validated(value * value)
        case .reciprocal:
            result = value == 0 ? nil : validated(1 / value)
        case .squareRoot:
            result = doubleValue < 0 ? nil : CalcNumber.decimal(from: sqrt(doubleValue))
        case .sine:
            result = CalcNumber.decimal(from: sin(radians(from: doubleValue)), zeroingTiny: true)
        case .cosine:
            result = CalcNumber.decimal(from: cos(radians(from: doubleValue)), zeroingTiny: true)
        case .tangent:
            let angle = radians(from: doubleValue)
            result = abs(cos(angle)) < 1e-12
                ? nil
                : CalcNumber.decimal(from: tan(angle), zeroingTiny: true)
        case .naturalLog:
            result = doubleValue <= 0 ? nil : CalcNumber.decimal(from: log(doubleValue))
        case .commonLog:
            result = doubleValue <= 0 ? nil : CalcNumber.decimal(from: log10(doubleValue))
        }

        guard let result else {
            fail()
            return
        }

        expression = unaryExpression(for: operation, value: value)
        setCurrent(result, startsNewEntry: pendingOperation == nil)
    }

    func insertConstant(_ constant: MathConstant) {
        guard !isError else { return }
        expression = constant.rawValue
        setCurrent(constant.value, startsNewEntry: pendingOperation == nil)
    }

    // MARK: - 설정 / 기록

    func toggleAngleMode() {
        angleMode = angleMode.toggled
        defaults.set(angleMode.rawValue, forKey: StorageKey.angleMode)
    }

    func useHistoryEntry(_ entry: HistoryEntry) {
        resetAll()
        setCurrent(entry.value)
    }

    func clearHistory() {
        history.removeAll()
        persistHistory()
    }

    // MARK: - 계산

    private var currentValue: Decimal {
        Decimal(string: rawInput, locale: CalcNumber.posix) ?? 0
    }

    private var significantDigitCount: Int {
        rawInput.reduce(into: 0) { count, character in
            if character.isNumber { count += 1 }
        }
    }

    private var canResetAll: Bool {
        isError || (rawInput == "0" && startsNewEntry)
    }

    private func apply(_ operation: BinaryOperation, _ lhs: Decimal, _ rhs: Decimal) -> Decimal? {
        switch operation {
        case .add:
            return validated(lhs + rhs)
        case .subtract:
            return validated(lhs - rhs)
        case .multiply:
            return validated(lhs * rhs)
        case .divide:
            guard rhs != 0 else { return nil }
            return validated(lhs / rhs)
        case .power:
            let result = pow(
                NSDecimalNumber(decimal: lhs).doubleValue,
                NSDecimalNumber(decimal: rhs).doubleValue
            )
            return CalcNumber.decimal(from: result)
        }
    }

    private func validated(_ value: Decimal) -> Decimal? {
        NSDecimalNumber(decimal: value) == NSDecimalNumber.notANumber ? nil : value
    }

    private func radians(from degrees: Double) -> Double {
        angleMode == .degrees ? degrees * .pi / 180 : degrees
    }

    private func setCurrent(_ value: Decimal, startsNewEntry: Bool = true) {
        rawInput = CalcNumber.string(from: value)
        self.startsNewEntry = startsNewEntry
    }

    private func format(_ value: Decimal) -> String {
        CalcNumber.grouped(CalcNumber.string(from: value))
    }

    private func unaryExpression(for operation: UnaryOperation, value: Decimal) -> String {
        let argument = format(value)
        switch operation {
        case .square:
            return "(\(argument))²"
        case .squareRoot:
            return "√(\(argument))"
        case .reciprocal:
            return "1/(\(argument))"
        default:
            return "\(operation.rawValue)(\(argument))"
        }
    }

    private func clearEntry() {
        rawInput = "0"
        startsNewEntry = true
        if let pending = pendingOperation {
            expression = "\(format(accumulator ?? 0)) \(pending.rawValue)"
        } else {
            expression = ""
        }
    }

    private func resetAll() {
        rawInput = "0"
        expression = ""
        isError = false
        accumulator = nil
        pendingOperation = nil
        lastOperation = nil
        lastOperand = nil
        startsNewEntry = true
    }

    private func fail() {
        resetAll()
        isError = true
    }

    // MARK: - 기록 저장

    private func record(expression: String, result: Decimal) {
        let entry = HistoryEntry(
            expression: expression,
            result: format(result),
            value: result
        )
        history.insert(entry, at: 0)
        if history.count > 100 {
            history.removeLast(history.count - 100)
        }
        persistHistory()
    }

    private func persistHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        defaults.set(data, forKey: StorageKey.history)
    }

    private func loadPersistedState() {
        if let data = defaults.data(forKey: StorageKey.history),
           let saved = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            history = Array(saved.prefix(100))
        }
        if let raw = defaults.string(forKey: StorageKey.angleMode),
           let mode = AngleMode(rawValue: raw) {
            angleMode = mode
        }
    }
}
