import SwiftUI

// MARK: - Keyboard Hints View

struct KeyboardHint: Identifiable {
    let id = UUID()
    let key: String
    let label: String
}

struct KeyboardHintsView: View {
    let hints: [KeyboardHint]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(hints) { hint in
                HStack(spacing: 5) {
                    Text(hint.key)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Theme.Colors.cardBackground)
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Theme.Colors.border.opacity(0.6), lineWidth: 1)
                        )
                    Text(hint.label)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
