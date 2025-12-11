import SwiftUI

// MARK: - SwiftUI Choice Card

struct SwiftUIChoiceCard: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let isMultiSelect: Bool
    let isFocused: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isHovered = false

    init(title: String, subtitle: String?, isSelected: Bool, isMultiSelect: Bool = false, isFocused: Bool = false, onTap: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.isMultiSelect = isMultiSelect
        self.isFocused = isFocused
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)

                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Show checkbox for multi-select, radio for single-select
                if isMultiSelect {
                    // Checkbox style
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Theme.Colors.accentBlue : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(isSelected ? Theme.Colors.accentBlue : Theme.Colors.border, lineWidth: 2)
                        )
                        .overlay(
                            Group {
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                } else {
                    // Radio button style
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .strokeBorder(isSelected ? Theme.Colors.accentBlue : Theme.Colors.border, lineWidth: 2)
                        )
                        .overlay(
                            Group {
                                if isSelected {
                                    Circle()
                                        .fill(Theme.Colors.accentBlue)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Theme.Colors.accentBlue.opacity(0.25) : ((isHovered || isFocused) ? Theme.Colors.cardHover : Theme.Colors.cardBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isFocused ? Theme.Colors.accentBlue.opacity(0.8) : (isSelected ? Theme.Colors.accentBlue : Theme.Colors.border),
                        lineWidth: (isSelected || isFocused) ? 2 : 1
                    )
            )
            .overlay(
                // Focus ring glow effect
                Group {
                    if isFocused && !isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.accentBlue.opacity(0.4), lineWidth: 3)
                            .padding(-2)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .onHover { hovering in
            if reduceMotion {
                isHovered = hovering
            } else {
                withAnimation(.easeOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .accessibilityLabel(Text(title))
        .accessibilityHint(subtitle.map { Text($0) } ?? Text(""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
