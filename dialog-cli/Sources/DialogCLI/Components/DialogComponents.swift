import SwiftUI
import AppKit

// MARK: - Dialog Header (Composable)

struct DialogHeader: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?

    init(icon: String, title: String, subtitle: String? = nil, iconColor: Color = Theme.Colors.accentBlue) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            .padding(.top, 28)
            .padding(.bottom, 16)

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Dialog Footer (Composable)

struct DialogFooter: View {
    let hints: [KeyboardHint]
    let buttons: [DialogButton]

    struct DialogButton: Identifiable {
        let id = UUID()
        let title: String
        let isPrimary: Bool
        let isDestructive: Bool
        let isDisabled: Bool
        let showReturnHint: Bool
        let action: () -> Void

        init(_ title: String, isPrimary: Bool = false, isDestructive: Bool = false, isDisabled: Bool = false, showReturnHint: Bool = false, action: @escaping () -> Void) {
            self.title = title
            self.isPrimary = isPrimary
            self.isDestructive = isDestructive
            self.isDisabled = isDisabled
            self.showReturnHint = showReturnHint
            self.action = action
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            KeyboardHintsView(hints: hints)
            HStack(spacing: 10) {
                ForEach(buttons) { button in
                    FocusableButton(
                        title: button.title,
                        isPrimary: button.isPrimary,
                        isDestructive: button.isDestructive,
                        isDisabled: button.isDisabled,
                        showReturnHint: button.showReturnHint,
                        action: button.action
                    )
                    .frame(height: 48)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Dialog Container (Composable)

struct DialogContainer<Content: View>: View {
    let onEscape: (() -> Void)?
    let keyHandler: ((UInt16, NSEvent.ModifierFlags) -> Bool)?
    let content: Content

    @State private var keyboardMonitor: KeyboardNavigationMonitor?

    init(
        onEscape: (() -> Void)? = nil,
        keyHandler: ((UInt16, NSEvent.ModifierFlags) -> Bool)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.onEscape = onEscape
        self.keyHandler = keyHandler
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.clear)
            .onAppear {
                FocusManager.shared.reset()
                setupKeyboardNavigation()
                // Focus first element after a brief delay to let views register
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    FocusManager.shared.focusFirst()
                }
            }
            .onDisappear {
                keyboardMonitor = nil
                FocusManager.shared.reset()
            }
    }

    private func setupKeyboardNavigation() {
        keyboardMonitor = KeyboardNavigationMonitor { keyCode, modifiers in
            // Handle navigation keys globally via FocusManager
            switch keyCode {
            case 48: // Tab
                if modifiers.contains(.shift) {
                    FocusManager.shared.focusPrevious()
                } else {
                    FocusManager.shared.focusNext()
                }
                return true
            case 125: // Down arrow
                FocusManager.shared.focusNext()
                return true
            case 126: // Up arrow
                FocusManager.shared.focusPrevious()
                return true
            default:
                break
            }

            // Let custom handler try (for Enter/Escape/etc)
            if let handler = keyHandler, handler(keyCode, modifiers) {
                return true
            }
            return false
        }
    }
}
