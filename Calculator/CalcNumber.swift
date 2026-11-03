import Foundation

/// 숫자를 화면에 표시하기 좋은 문자열로 변환하는 유틸리티.
enum CalcNumber {

    static let posix = Locale(identifier: "en_US_POSIX")

    /// 엔진 내부에서 사용하는 그룹 구분자 없는 문자열 포매터.
    private static let plainFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = CalcNumber.posix
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 10
        formatter.roundingMode = .halfUp
        return formatter
    }()

    /// Decimal 값을 그룹 구분자 없는 순수 문자열로 변환한다.
    static func string(from value: Decimal) -> String {
        let doubleValue = NSDecimalNumber(decimal: value).doubleValue
        guard doubleValue.isFinite else { return "Error" }
        if doubleValue == 0 { return "0" }

        let magnitude = abs(doubleValue)
        if magnitude >= 1e15 || magnitude < 1e-9 {
            return String(format: "%.6g", doubleValue)
        }

        guard var text = plainFormatter.string(from: NSDecimalNumber(decimal: value)) else {
            return "0"
        }
        if text == "-0" { text = "0" }
        return text
    }

    /// Double 연산 결과를 계산기 정밀도(소수 10자리)로 반올림해 Decimal 로 변환한다.
    static func decimal(from value: Double, zeroingTiny: Bool = false) -> Decimal? {
        guard value.isFinite else { return nil }

        var adjusted = value
        if zeroingTiny, abs(adjusted) < 1e-12 { adjusted = 0 }

        let magnitude = abs(adjusted)
        if magnitude >= 1e15 || (magnitude > 0 && magnitude < 1e-10) {
            return Decimal(string: String(format: "%.12g", adjusted), locale: posix)
        }

        let rounded = (adjusted * 1e10).rounded() / 1e10
        return Decimal(string: String(format: "%.10f", rounded), locale: posix)
    }

    /// 순수 숫자 문자열에 천 단위 구분자를 넣는다. (예: "1234567.89" -> "1,234,567.89")
    static func grouped(_ raw: String) -> String {
        guard raw != "Error" else { return raw }
        guard !raw.lowercased().contains("e") else { return raw }

        var body = raw
        var sign = ""
        if body.hasPrefix("-") {
            sign = "−"
            body.removeFirst()
        }
        if body.hasPrefix("+") {
            body.removeFirst()
        }

        let parts = body.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integerPart = String(parts[0])

        var groupedReversed = ""
        for (index, character) in integerPart.reversed().enumerated() {
            if index > 0, index % 3 == 0 {
                groupedReversed.append(",")
            }
            groupedReversed.append(character)
        }
        let groupedInteger = String(groupedReversed.reversed())

        if parts.count > 1 {
            return sign + groupedInteger + "." + String(parts[1])
        }
        return sign + groupedInteger
    }

    /// 구분자가 포함된 표시 문자열을 Decimal 로 파싱한다.
    static func decimal(fromDisplayText text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "−", with: "-")
        return Decimal(string: cleaned, locale: posix)
    }
}
