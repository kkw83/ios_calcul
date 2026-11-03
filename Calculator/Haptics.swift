import UIKit

/// 계산기 버튼에서 사용하는 가벼운 햅틱 피드백.
enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)

    static var isEnabled = true

    static func tap() {
        guard isEnabled else { return }
        light.impactOccurred(intensity: 0.65)
        light.prepare()
    }

    static func result() {
        guard isEnabled else { return }
        rigid.impactOccurred(intensity: 0.8)
        rigid.prepare()
    }
}
