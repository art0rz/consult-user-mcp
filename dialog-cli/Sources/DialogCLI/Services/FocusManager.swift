import AppKit

// MARK: - Focus Manager

/// Centralized focus management for NSViewRepresentable views in SwiftUI
final class FocusManager {
    static let shared = FocusManager()

    private var focusableViews: [NSView] = []
    private var currentIndex: Int = -1

    private init() {}

    /// Register a focusable view
    func register(_ view: NSView) {
        if !focusableViews.contains(where: { $0 === view }) {
            focusableViews.append(view)
        }
    }

    /// Unregister a focusable view
    func unregister(_ view: NSView) {
        focusableViews.removeAll { $0 === view }
        updateCurrentIndex()
    }

    /// Clear all registered views (call when dialog closes)
    func reset() {
        focusableViews.removeAll()
        currentIndex = -1
    }

    /// Move focus to next view (Tab)
    func focusNext() {
        guard !focusableViews.isEmpty else { return }

        // Filter to only views that are in a window and can become key
        let validViews = focusableViews.filter { $0.window != nil && $0.canBecomeKeyView }
        guard !validViews.isEmpty else { return }

        updateCurrentIndex()

        let nextIndex = (currentIndex + 1) % validViews.count
        if let view = validViews[safe: nextIndex] {
            view.window?.makeFirstResponder(view)
            currentIndex = nextIndex
        }
    }

    /// Move focus to previous view (Shift+Tab)
    func focusPrevious() {
        guard !focusableViews.isEmpty else { return }

        let validViews = focusableViews.filter { $0.window != nil && $0.canBecomeKeyView }
        guard !validViews.isEmpty else { return }

        updateCurrentIndex()

        let prevIndex = currentIndex <= 0 ? validViews.count - 1 : currentIndex - 1
        if let view = validViews[safe: prevIndex] {
            view.window?.makeFirstResponder(view)
            currentIndex = prevIndex
        }
    }

    /// Focus a specific view
    func focus(_ view: NSView) {
        guard let window = view.window else { return }
        window.makeFirstResponder(view)
        if let index = focusableViews.firstIndex(where: { $0 === view }) {
            currentIndex = index
        }
    }

    /// Focus the first registered view (sorted by screen position - top to bottom)
    func focusFirst() {
        let validViews = focusableViews
            .filter { $0.window != nil && $0.canBecomeKeyView }
            .sorted { view1, view2 in
                // Sort by y position (higher y = higher on screen in window coordinates)
                let y1 = view1.convert(view1.bounds.origin, to: nil).y
                let y2 = view2.convert(view2.bounds.origin, to: nil).y
                return y1 > y2  // Higher y first (top of window)
            }
        if let first = validViews.first {
            first.window?.makeFirstResponder(first)
            currentIndex = 0
        }
    }

    private func updateCurrentIndex() {
        let validViews = focusableViews.filter { $0.window != nil && $0.canBecomeKeyView }

        // Find current first responder
        if let window = validViews.first?.window,
           let firstResponder = window.firstResponder as? NSView,
           let index = validViews.firstIndex(where: { $0 === firstResponder }) {
            currentIndex = index
        } else {
            currentIndex = -1
        }
    }
}

