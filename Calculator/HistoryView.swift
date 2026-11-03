import SwiftUI

/// 계산 기록 시트. 항목을 탭하면 그 결과를 현재 값으로 불러온다.
struct HistoryView: View {
    let entries: [HistoryEntry]
    let theme: CalculatorTheme
    let onSelect: (HistoryEntry) -> Void
    let onClear: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                if entries.isEmpty {
                    ContentUnavailableView(
                        "계산 기록이 없습니다",
                        systemImage: "clock",
                        description: Text("계산을 완료하면 여기에 기록이 남습니다.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(entries) { entry in
                                Button {
                                    onSelect(entry)
                                    dismiss()
                                } label: {
                                    row(for: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("계산 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("지우기", role: .destructive) {
                        onClear()
                    }
                    .disabled(entries.isEmpty)
                }
            }
        }
        .tint(theme.accent)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func row(for entry: HistoryEntry) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            Text(entry.date, style: .time)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(theme.secondaryText)

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.expression + " =")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(entry.result)
                    .font(.system(size: 26, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(theme.rowBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
