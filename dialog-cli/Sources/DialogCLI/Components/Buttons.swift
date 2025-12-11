import SwiftUI
import AppKit

// MARK: - SwiftUI Modern Button

struct SwiftUIModernButton: View {
    let title: String
    let isPrimary: Bool
    let isDestructive: Bool
    let isDisabled: Bool
    let showReturnHint: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isHovered = false
    @State private var isPressed = false

    init(title: String, isPrimary: Bool = false, isDestructive: Bool = false, isDisabled: Bool = false, showReturnHint: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isPrimary = isPrimary
        self.isDestructive = isDestructive
        self.isDisabled = isDisabled
        self.showReturnHint = showReturnHint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: isPrimary ? .semibold : .medium))
                    .foregroundColor(buttonTextColor)
                if showReturnHint && isPrimary && !isDisabled {
                    Image(systemName: "return")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(buttonTextColor.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isPrimary ? Color.clear : Theme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isDisabled)
        .onHover { hovering in
            guard !isDisabled else { return }
            if reduceMotion {
                isHovered = hovering
            } else {
                withAnimation(.easeOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(isPrimary ? .isButton : [.isButton])
    }

    private var buttonFill: AnyShapeStyle {
        if isDisabled {
            return AnyShapeStyle(Theme.Colors.cardBackground.opacity(0.5))
        } else if isPrimary {
            return AnyShapeStyle(LinearGradient(
                colors: isHovered
                    ? [Theme.Colors.accentBlue, Theme.Colors.accentBlueDark]
                    : [Theme.Colors.accentBlueLight, Theme.Colors.accentBlue],
                startPoint: .top,
                endPoint: .bottom
            ))
        } else if isDestructive {
            return AnyShapeStyle(isHovered ? Theme.Colors.accentRed.opacity(0.3) : Theme.Colors.accentRed.opacity(0.2))
        } else {
            return AnyShapeStyle(isHovered ? Theme.Colors.cardHover : Theme.Colors.cardBackground)
        }
    }

    private var buttonTextColor: Color {
        if isDisabled {
            return Theme.Colors.textMuted
        } else if isPrimary {
            return .white
        } else if isDestructive {
            return Theme.Colors.accentRed
        } else {
            return Theme.Colors.textPrimary
        }
    }
}

// MARK: - Button Press Style

struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Modern Button

class ModernButton: NSView {
    var title: String
    var isPrimary: Bool
    var isDestructive: Bool
    var onClick: (() -> Void)?

    private var isHovered = false
    private var isPressed = false
    private var isFocused = false
    private var trackingArea: NSTrackingArea?

    override var mouseDownCanMoveWindow: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    init(title: String, isPrimary: Bool = false, isDestructive: Bool = false) {
        self.title = title
        self.isPrimary = isPrimary
        self.isDestructive = isDestructive
        super.init(frame: .zero)
        setupTracking()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupTracking() {
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        isPressed = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        isPressed = true
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if isPressed && isHovered {
            onClick?()
        }
        isPressed = false
        needsDisplay = true
    }

    override func becomeFirstResponder() -> Bool {
        isFocused = true
        needsDisplay = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        isFocused = false
        needsDisplay = true
        return true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 || event.keyCode == 36 { // Space or Enter
            onClick?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: Theme.buttonRadius, yRadius: Theme.buttonRadius)

        let bgColor: NSColor
        if isPrimary {
            if isPressed {
                bgColor = Theme.accentBlue.blended(withFraction: 0.3, of: .black) ?? Theme.accentBlue
            } else if isHovered {
                bgColor = Theme.accentBlue.blended(withFraction: 0.15, of: .white) ?? Theme.accentBlue
            } else {
                bgColor = Theme.accentBlue
            }
        } else if isDestructive {
            if isPressed {
                bgColor = Theme.accentRed.blended(withFraction: 0.3, of: .black) ?? Theme.accentRed
            } else if isHovered {
                bgColor = Theme.accentRed.blended(withFraction: 0.15, of: .white) ?? Theme.accentRed
            } else {
                bgColor = Theme.accentRed.withAlphaComponent(0.2)
            }
        } else {
            if isPressed {
                bgColor = Theme.cardSelected
            } else if isHovered {
                bgColor = Theme.cardHover
            } else {
                bgColor = Theme.cardBackground
            }
        }

        bgColor.setFill()
        path.fill()

        if !isPrimary {
            Theme.border.setStroke()
            path.lineWidth = 1
            path.stroke()
        }

        // Draw focus ring
        if isFocused {
            let focusPath = NSBezierPath(roundedRect: rect.insetBy(dx: -2, dy: -2), xRadius: Theme.buttonRadius + 1, yRadius: Theme.buttonRadius + 1)
            Theme.accentBlue.setStroke()
            focusPath.lineWidth = 2
            focusPath.stroke()
        }

        let textColor: NSColor = isPrimary ? .white : (isDestructive ? Theme.accentRed : Theme.textPrimary)
        let font = NSFont.systemFont(ofSize: 15, weight: isPrimary ? .semibold : .medium)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let size = (title as NSString).size(withAttributes: attrs)
        let textRect = NSRect(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2,
            width: size.width,
            height: size.height
        )

        (title as NSString).draw(in: textRect, withAttributes: attrs)
    }
}
