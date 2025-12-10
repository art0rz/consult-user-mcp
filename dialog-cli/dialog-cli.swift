#!/usr/bin/env swift

import AppKit
import AVFoundation
import Foundation
import SwiftUI

// MARK: - Models

struct ConfirmRequest: Codable {
    let message: String
    let title: String
    let confirmLabel: String
    let cancelLabel: String
    let position: String
}

struct ConfirmResponse: Codable {
    let confirmed: Bool
    let cancelled: Bool
    let response: String?
    let comment: String?
}

struct ChooseRequest: Codable {
    let prompt: String
    let choices: [String]
    let descriptions: [String]?
    let allowMultiple: Bool
    let defaultSelection: String?
    let position: String
}

struct ChoiceResponse: Codable {
    let selected: SelectedValue?
    let cancelled: Bool
    let description: String?
    let descriptions: [String?]?
    let comment: String?

    enum SelectedValue: Codable {
        case single(String)
        case multiple([String])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let arr = try? container.decode([String].self) {
                self = .multiple(arr)
            } else if let str = try? container.decode(String.self) {
                self = .single(str)
            } else {
                throw DecodingError.typeMismatch(SelectedValue.self, .init(codingPath: decoder.codingPath, debugDescription: "Expected String or [String]"))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .single(let str): try container.encode(str)
            case .multiple(let arr): try container.encode(arr)
            }
        }
    }
}

struct TextInputRequest: Codable {
    let prompt: String
    let title: String
    let defaultValue: String
    let hidden: Bool
    let position: String
}

struct TextInputResponse: Codable {
    let text: String?
    let cancelled: Bool
    let comment: String?
}

struct NotifyRequest: Codable {
    let message: String
    let title: String
    let subtitle: String?
    let sound: Bool
}

struct NotifyResponse: Codable {
    let success: Bool
}

struct SpeakRequest: Codable {
    let text: String
    let voice: String?
    let rate: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        rate = try container.decode(Int.self, forKey: .rate)
        if container.contains(.voice) {
            voice = try? container.decode(String.self, forKey: .voice)
        } else {
            voice = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case text, voice, rate
    }
}

struct SpeakResponse: Codable {
    let success: Bool
}

// MARK: - Multi-Question Models

struct QuestionOption: Codable {
    let label: String
    let description: String?
}

struct QuestionItem: Codable {
    let id: String
    let question: String
    let options: [QuestionOption]
    let multiSelect: Bool
}

struct QuestionsRequest: Codable {
    let questions: [QuestionItem]
    let mode: String  // "wizard" | "accordion" | "questionnaire"
    let position: String
}

struct QuestionsResponse: Codable {
    let answers: [String: AnswerValue]
    let cancelled: Bool
    let completedCount: Int

    enum AnswerValue: Codable {
        case single(String)
        case multiple([String])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let arr = try? container.decode([String].self) {
                self = .multiple(arr)
            } else if let str = try? container.decode(String.self) {
                self = .single(str)
            } else {
                throw DecodingError.typeMismatch(AnswerValue.self, .init(codingPath: decoder.codingPath, debugDescription: "Expected String or [String]"))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .single(let str): try container.encode(str)
            case .multiple(let arr): try container.encode(arr)
            }
        }
    }
}

// MARK: - Modern Theme

struct Theme {
    static let windowBackground = NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 0.98)
    static let cardBackground = NSColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
    static let cardHover = NSColor(red: 0.18, green: 0.18, blue: 0.22, alpha: 1.0)
    static let cardSelected = NSColor(red: 0.22, green: 0.22, blue: 0.28, alpha: 1.0)

    static let textPrimary = NSColor.white
    static let textSecondary = NSColor(white: 0.65, alpha: 1.0)
    static let textMuted = NSColor(white: 0.4, alpha: 1.0)

    static let accentBlue = NSColor(red: 0.35, green: 0.55, blue: 1.0, alpha: 1.0)
    static let accentGreen = NSColor(red: 0.30, green: 0.85, blue: 0.55, alpha: 1.0)
    static let accentRed = NSColor(red: 0.95, green: 0.35, blue: 0.40, alpha: 1.0)

    static let border = NSColor(white: 0.25, alpha: 1.0)
    static let inputBackground = NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)

    static let cornerRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 12
    static let cardRadius: CGFloat = 10

    // SwiftUI Colors
    enum Colors {
        static let windowBackground = Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.98)
        static let cardBackground = Color(red: 0.14, green: 0.14, blue: 0.16)
        static let cardHover = Color(red: 0.18, green: 0.18, blue: 0.22)
        static let cardSelected = Color(red: 0.22, green: 0.22, blue: 0.28)
        static let textPrimary = Color.white
        static let textSecondary = Color(white: 0.65)
        static let textMuted = Color(white: 0.4)
        static let accentBlue = Color(red: 0.35, green: 0.55, blue: 1.0)
        static let accentGreen = Color(red: 0.30, green: 0.85, blue: 0.55)
        static let accentRed = Color(red: 0.95, green: 0.35, blue: 0.40)
        static let border = Color(white: 0.25)
        static let inputBackground = Color(red: 0.08, green: 0.08, blue: 0.10)
    }
}

// MARK: - SwiftUI Choice Card

struct SwiftUIChoiceCard: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovered = false

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

                // Always reserve space for checkmark to prevent layout shifts
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.Colors.accentBlue : Color.clear)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Theme.Colors.accentBlue.opacity(0.15) : (isHovered ? Theme.Colors.cardHover : Theme.Colors.cardBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Theme.Colors.accentBlue : Theme.Colors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - SwiftUI Modern Button

struct SwiftUIModernButton: View {
    let title: String
    let isPrimary: Bool
    let isDestructive: Bool
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    init(title: String, isPrimary: Bool = false, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isPrimary = isPrimary
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isPrimary ? .semibold : .medium))
                .foregroundColor(buttonTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(buttonBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isPrimary ? Color.clear : Theme.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(PressableButtonStyle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var buttonBackground: Color {
        if isPrimary {
            return isHovered ? Theme.Colors.accentBlue.opacity(0.85) : Theme.Colors.accentBlue
        } else if isDestructive {
            return isHovered ? Theme.Colors.accentRed.opacity(0.3) : Theme.Colors.accentRed.opacity(0.2)
        } else {
            return isHovered ? Theme.Colors.cardHover : Theme.Colors.cardBackground
        }
    }

    private var buttonTextColor: Color {
        if isPrimary {
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
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - SwiftUI Confirm Dialog

struct SwiftUIConfirmDialog: View {
    let title: String
    let message: String
    let confirmLabel: String
    let cancelLabel: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.accentBlue.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: "questionmark")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Theme.Colors.accentBlue)
            }
            .padding(.top, 28)
            .padding(.bottom, 16)

            // Title
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

            // Scrollable Message
            ScrollView {
                Text(message)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
            }
            .frame(maxHeight: 300)
            .padding(.bottom, 20)

            // Buttons
            HStack(spacing: 10) {
                SwiftUIModernButton(title: cancelLabel, isPrimary: false, action: onCancel)
                SwiftUIModernButton(title: confirmLabel, isPrimary: true, action: onConfirm)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.clear)
    }
}

// MARK: - Hybrid Text Input Dialog (SwiftUI + AppKit)

struct SwiftUITextInputDialogHeader: View {
    let title: String
    let prompt: String
    let isSecure: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.accentBlue.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: isSecure ? "lock.fill" : "text.cursor")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Theme.Colors.accentBlue)
            }
            .padding(.top, 28)
            .padding(.bottom, 16)

            // Title
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Prompt
            Text(prompt)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 16)
        }
    }
}

// MARK: - Modern Styled Text Field (AppKit)

class StyledTextField: NSView {
    let textField: NSTextField
    private let isSecure: Bool
    private var isFocused = false

    override var mouseDownCanMoveWindow: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    init(isSecure: Bool, defaultValue: String) {
        self.isSecure = isSecure
        if isSecure {
            textField = NSSecureTextField()
        } else {
            textField = NSTextField()
        }
        super.init(frame: .zero)

        textField.stringValue = defaultValue
        textField.isEditable = true
        textField.isSelectable = true
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = NSFont.systemFont(ofSize: 15)
        textField.textColor = Theme.textPrimary
        textField.delegate = self

        addSubview(textField)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        textField.frame = bounds.insetBy(dx: 14, dy: 0)
        textField.frame.origin.y = (bounds.height - 22) / 2
        textField.frame.size.height = 22
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(textField)
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)

        Theme.inputBackground.setFill()
        path.fill()

        let borderColor = isFocused ? Theme.accentBlue : Theme.border
        borderColor.setStroke()
        path.lineWidth = isFocused ? 2 : 1
        path.stroke()
    }
}

extension StyledTextField: NSTextFieldDelegate {
    func controlTextDidBeginEditing(_ obj: Notification) {
        isFocused = true
        needsDisplay = true
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        isFocused = false
        needsDisplay = true
    }
}

// MARK: - SwiftUI Choose Dialog

struct SwiftUIChooseDialog: View {
    let prompt: String
    let choices: [String]
    let descriptions: [String]?
    let allowMultiple: Bool
    let defaultSelection: String?
    let onComplete: (Set<Int>) -> Void
    let onCancel: () -> Void

    @State private var selectedIndices: Set<Int> = []

    init(prompt: String, choices: [String], descriptions: [String]?, allowMultiple: Bool, defaultSelection: String?, onComplete: @escaping (Set<Int>) -> Void, onCancel: @escaping () -> Void) {
        self.prompt = prompt
        self.choices = choices
        self.descriptions = descriptions
        self.allowMultiple = allowMultiple
        self.defaultSelection = defaultSelection
        self.onComplete = onComplete
        self.onCancel = onCancel

        // Set default selection
        if let defaultSel = defaultSelection, let idx = choices.firstIndex(of: defaultSel) {
            _selectedIndices = State(initialValue: [idx])
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(prompt)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

            // Scrollable choices
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                        SwiftUIChoiceCard(
                            title: choice,
                            subtitle: descriptions?[safe: index],
                            isSelected: selectedIndices.contains(index),
                            onTap: {
                                if allowMultiple {
                                    if selectedIndices.contains(index) {
                                        selectedIndices.remove(index)
                                    } else {
                                        selectedIndices.insert(index)
                                    }
                                } else {
                                    selectedIndices = [index]
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 500)

            // Footer buttons
            HStack(spacing: 10) {
                SwiftUIModernButton(title: "Cancel", isPrimary: false, action: onCancel)
                SwiftUIModernButton(title: "Continue", isPrimary: true, action: {
                    onComplete(selectedIndices)
                })
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.clear)
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < current ? Theme.Colors.accentBlue : Theme.Colors.border)
                    .frame(height: 4)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Question Section (shared component)

struct QuestionSection: View {
    let question: QuestionItem
    @Binding var selectedIndices: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.question)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    SwiftUIChoiceCard(
                        title: option.label,
                        subtitle: option.description,
                        isSelected: selectedIndices.contains(index),
                        onTap: {
                            if question.multiSelect {
                                if selectedIndices.contains(index) {
                                    selectedIndices.remove(index)
                                } else {
                                    selectedIndices.insert(index)
                                }
                            } else {
                                selectedIndices = [index]
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Wizard Mode Dialog

struct SwiftUIWizardDialog: View {
    let questions: [QuestionItem]
    let onComplete: ([String: Set<Int>]) -> Void
    let onCancel: () -> Void

    @State private var currentIndex = 0
    @State private var answers: [String: Set<Int>] = [:]

    private var currentQuestion: QuestionItem { questions[currentIndex] }
    private var currentAnswer: Set<Int> { answers[currentQuestion.id] ?? [] }
    private var isFirst: Bool { currentIndex == 0 }
    private var isLast: Bool { currentIndex == questions.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressBar(current: currentIndex + 1, total: questions.count)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)

            // Progress text
            Text("\(currentIndex + 1) of \(questions.count)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.textMuted)
                .padding(.bottom, 16)

            // Question content
            ScrollView {
                QuestionSection(
                    question: currentQuestion,
                    selectedIndices: Binding(
                        get: { currentAnswer },
                        set: { answers[currentQuestion.id] = $0 }
                    )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 420)

            // Navigation buttons
            HStack(spacing: 10) {
                if isFirst {
                    SwiftUIModernButton(title: "Cancel", isPrimary: false, action: onCancel)
                } else {
                    SwiftUIModernButton(title: "Back", isPrimary: false, action: {
                        currentIndex -= 1
                    })
                }

                if isLast {
                    SwiftUIModernButton(title: "Submit", isPrimary: true, action: {
                        onComplete(answers)
                    })
                } else {
                    SwiftUIModernButton(title: "Next", isPrimary: true, action: {
                        currentIndex += 1
                    })
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.clear)
    }
}

// MARK: - Accordion Mode Dialog

struct AccordionSection: View {
    let question: QuestionItem
    let isExpanded: Bool
    let isAnswered: Bool
    @Binding var selectedIndices: Set<Int>
    let onToggle: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack {
                    // Status indicator
                    ZStack {
                        Circle()
                            .fill(isAnswered ? Theme.Colors.accentGreen : Theme.Colors.border)
                            .frame(width: 20, height: 20)

                        if isAnswered {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    Text(question.question)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isHovered ? Theme.Colors.cardHover : Theme.Colors.cardBackground)
                )
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }

            // Expanded content
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        SwiftUIChoiceCard(
                            title: option.label,
                            subtitle: option.description,
                            isSelected: selectedIndices.contains(index),
                            onTap: {
                                if question.multiSelect {
                                    if selectedIndices.contains(index) {
                                        selectedIndices.remove(index)
                                    } else {
                                        selectedIndices.insert(index)
                                    }
                                } else {
                                    selectedIndices = [index]
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }
        }
    }
}

struct SwiftUIAccordionDialog: View {
    let questions: [QuestionItem]
    let onComplete: ([String: Set<Int>]) -> Void
    let onCancel: () -> Void

    @State private var expandedId: String?
    @State private var answers: [String: Set<Int>] = [:]

    private var answeredCount: Int {
        answers.values.filter { !$0.isEmpty }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            HStack {
                Text("Questions")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Text("\(answeredCount)/\(questions.count) answered")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Accordion sections
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(questions, id: \.id) { question in
                        AccordionSection(
                            question: question,
                            isExpanded: expandedId == question.id,
                            isAnswered: !(answers[question.id] ?? []).isEmpty,
                            selectedIndices: Binding(
                                get: { answers[question.id] ?? [] },
                                set: { answers[question.id] = $0 }
                            ),
                            onToggle: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    expandedId = expandedId == question.id ? nil : question.id
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 450)

            // Footer buttons
            HStack(spacing: 10) {
                SwiftUIModernButton(title: "Cancel", isPrimary: false, action: onCancel)
                SwiftUIModernButton(title: "Submit", isPrimary: true, action: {
                    onComplete(answers)
                })
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.clear)
        .onAppear {
            // Expand first question by default
            if let first = questions.first {
                expandedId = first.id
            }
        }
    }
}

// MARK: - Questionnaire Mode Dialog (all visible)

struct SwiftUIQuestionnaireDialog: View {
    let questions: [QuestionItem]
    let onComplete: ([String: Set<Int>]) -> Void
    let onCancel: () -> Void

    @State private var answers: [String: Set<Int>] = [:]

    private var answeredCount: Int {
        answers.values.filter { !$0.isEmpty }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            HStack {
                Text("Questions")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Text("\(answeredCount)/\(questions.count) answered")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // All questions visible
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                        VStack(alignment: .leading, spacing: 0) {
                            // Question number badge
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(!(answers[question.id] ?? []).isEmpty ? Theme.Colors.accentBlue : Theme.Colors.border)
                                        .frame(width: 24, height: 24)

                                    Text("\(index + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                Text(question.question)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.bottom, 12)

                            // Options
                            VStack(spacing: 8) {
                                ForEach(Array(question.options.enumerated()), id: \.offset) { optIndex, option in
                                    SwiftUIChoiceCard(
                                        title: option.label,
                                        subtitle: option.description,
                                        isSelected: (answers[question.id] ?? []).contains(optIndex),
                                        onTap: {
                                            var current = answers[question.id] ?? []
                                            if question.multiSelect {
                                                if current.contains(optIndex) {
                                                    current.remove(optIndex)
                                                } else {
                                                    current.insert(optIndex)
                                                }
                                            } else {
                                                current = [optIndex]
                                            }
                                            answers[question.id] = current
                                        }
                                    )
                                }
                            }
                        }

                        if index < questions.count - 1 {
                            Divider()
                                .background(Theme.Colors.border)
                                .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 450)

            // Footer buttons
            HStack(spacing: 10) {
                SwiftUIModernButton(title: "Cancel", isPrimary: false, action: onCancel)
                SwiftUIModernButton(title: "Submit", isPrimary: true, action: {
                    onComplete(answers)
                })
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.clear)
    }
}

// MARK: - Borderless Window that Accepts Keyboard

class BorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override var acceptsFirstResponder: Bool { true }
}

// MARK: - Draggable Window Background

class DraggableView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 8, dy: 8)
        let path = NSBezierPath(roundedRect: rect, xRadius: Theme.cornerRadius, yRadius: Theme.cornerRadius)
        Theme.windowBackground.setFill()
        path.fill()
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

// MARK: - Modern Choice Card

class ChoiceCard: NSView {
    var title: String
    var subtitle: String?
    var isSelected = false
    var onClick: (() -> Void)?

    private var isHovered = false
    private var trackingArea: NSTrackingArea?

    override var mouseDownCanMoveWindow: Bool { false }

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
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
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: Theme.cardRadius, yRadius: Theme.cardRadius)

        let bgColor: NSColor
        if isSelected {
            bgColor = Theme.accentBlue.withAlphaComponent(0.25)
        } else if isHovered {
            bgColor = Theme.cardHover
        } else {
            bgColor = Theme.cardBackground
        }

        bgColor.setFill()
        path.fill()

        let borderColor = isSelected ? Theme.accentBlue : Theme.border
        borderColor.setStroke()
        path.lineWidth = isSelected ? 2 : 1
        path.stroke()

        // Checkmark circle for selected
        if isSelected {
            let checkSize: CGFloat = 20
            let checkRect = NSRect(x: bounds.width - checkSize - 12, y: (bounds.height - checkSize) / 2, width: checkSize, height: checkSize)
            let checkPath = NSBezierPath(ovalIn: checkRect)
            Theme.accentBlue.setFill()
            checkPath.fill()

            let checkmarkPath = NSBezierPath()
            let cx = checkRect.midX
            let cy = checkRect.midY
            checkmarkPath.move(to: NSPoint(x: cx - 4, y: cy))
            checkmarkPath.line(to: NSPoint(x: cx - 1, y: cy - 3))
            checkmarkPath.line(to: NSPoint(x: cx + 4, y: cy + 3))
            NSColor.white.setStroke()
            checkmarkPath.lineWidth = 2
            checkmarkPath.lineCapStyle = .round
            checkmarkPath.lineJoinStyle = .round
            checkmarkPath.stroke()
        }

        // Text
        let textX: CGFloat = 16
        let maxTextWidth = bounds.width - 50

        let titleFont = NSFont.systemFont(ofSize: 14, weight: .medium)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: Theme.textPrimary
        ]

        if let subtitle = subtitle, !subtitle.isEmpty {
            let titleY = bounds.height / 2 + 4
            let titleRect = NSRect(x: textX, y: titleY, width: maxTextWidth, height: 18)
            (title as NSString).draw(in: titleRect, withAttributes: titleAttrs)

            let subtitleFont = NSFont.systemFont(ofSize: 11, weight: .regular)
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: Theme.textSecondary
            ]
            let subtitleY = bounds.height / 2 - 14
            let subtitleRect = NSRect(x: textX, y: subtitleY, width: maxTextWidth, height: 14)
            (subtitle as NSString).draw(in: subtitleRect, withAttributes: subtitleAttrs)
        } else {
            let titleSize = (title as NSString).size(withAttributes: titleAttrs)
            let titleY = (bounds.height - titleSize.height) / 2
            let titleRect = NSRect(x: textX, y: titleY, width: maxTextWidth, height: titleSize.height)
            (title as NSString).draw(in: titleRect, withAttributes: titleAttrs)
        }
    }
}

// MARK: - Modern Text Field

class ModernTextField: NSView {
    var placeholder: String
    var isSecure: Bool
    var text: String {
        get { textField.stringValue }
        set { textField.stringValue = newValue }
    }

    override var mouseDownCanMoveWindow: Bool { false }

    private let textField: NSTextField

    init(placeholder: String = "", isSecure: Bool = false, defaultValue: String = "") {
        self.placeholder = placeholder
        self.isSecure = isSecure

        if isSecure {
            textField = NSSecureTextField()
        } else {
            textField = NSTextField()
        }

        super.init(frame: .zero)

        textField.stringValue = defaultValue
        textField.placeholderString = placeholder
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = NSFont.systemFont(ofSize: 15)
        textField.textColor = Theme.textPrimary

        addSubview(textField)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        textField.frame = bounds.insetBy(dx: 14, dy: 0)
        textField.frame.origin.y = (bounds.height - 22) / 2
        textField.frame.size.height = 22
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)

        Theme.inputBackground.setFill()
        path.fill()

        Theme.border.setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    func makeFirstResponder(in window: NSWindow) {
        window.makeFirstResponder(textField)
    }
}

// MARK: - Settings Reader

struct UserSettings {
    var position: String = "left"
    var speechRate: Int = 200

    static func load() -> UserSettings {
        var settings = UserSettings()

        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return settings
        }

        let settingsURL = appSupport.appendingPathComponent("SpeakMCP/settings.json")
        guard let data = fm.contents(atPath: settingsURL.path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return settings
        }

        if let position = json["position"] as? String {
            settings.position = position
        }
        if let rate = json["speechRate"] as? Int {
            settings.speechRate = rate
        } else if let rate = json["speechRate"] as? Double {
            settings.speechRate = Int(rate)
        }

        return settings
    }
}

// MARK: - Dialog Manager

class DialogManager {
    static let shared = DialogManager()
    private var clientName = "MCP"
    private var userSettings = UserSettings.load()

    func setClientName(_ name: String) {
        clientName = name
    }

    func reloadSettings() {
        userSettings = UserSettings.load()
    }

    /// Returns the effective position - user setting always overrides passed-in position
    private func effectivePosition(_ requestedPosition: String) -> String {
        return userSettings.position
    }

    private func buildTitle(_ baseTitle: String) -> String {
        "\(clientName)"
    }

    private func createWindow(width: CGFloat, height: CGFloat) -> (NSWindow, DraggableView) {
        let window = BorderlessWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.acceptsMouseMovedEvents = true

        let bgView = DraggableView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        window.contentView = bgView

        return (window, bgView)
    }

    private func positionWindow(_ window: NSWindow, position: String) {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame

        let x: CGFloat
        switch position {
        case "left":
            x = screenFrame.minX + 40
        case "right":
            x = screenFrame.maxX - windowFrame.width - 40
        default:
            x = screenFrame.midX - windowFrame.width / 2
        }

        let y = screenFrame.maxY - windowFrame.height - 80
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Confirm Dialog (SwiftUI)

    func confirm(_ request: ConfirmRequest) -> ConfirmResponse {
        reloadSettings()
        NSApp.setActivationPolicy(.accessory)

        var result: ConfirmResponse?
        let windowWidth: CGFloat = 420
        let windowHeight: CGFloat = 480

        let (window, contentView) = createWindow(width: windowWidth, height: windowHeight)

        // Create SwiftUI dialog
        let swiftUIDialog = SwiftUIConfirmDialog(
            title: request.title,
            message: request.message,
            confirmLabel: request.confirmLabel,
            cancelLabel: request.cancelLabel,
            onConfirm: {
                result = ConfirmResponse(confirmed: true, cancelled: false, response: request.confirmLabel, comment: nil)
                NSApp.stopModal()
            },
            onCancel: {
                result = ConfirmResponse(confirmed: false, cancelled: false, response: request.cancelLabel, comment: nil)
                NSApp.stopModal()
            }
        )

        // Embed SwiftUI in NSHostingView
        let hostingView = NSHostingView(rootView: swiftUIDialog)
        hostingView.frame = NSRect(x: 8, y: 8, width: windowWidth - 16, height: windowHeight - 16)
        contentView.addSubview(hostingView)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSApp.runModal(for: window)
        window.close()

        return result ?? ConfirmResponse(confirmed: false, cancelled: true, response: nil, comment: nil)
    }

    // MARK: - Choose Dialog (SwiftUI)

    func choose(_ request: ChooseRequest) -> ChoiceResponse {
        reloadSettings()
        NSApp.setActivationPolicy(.accessory)

        var result: ChoiceResponse?
        let windowWidth: CGFloat = 420
        let windowHeight: CGFloat = 600

        let (window, contentView) = createWindow(width: windowWidth, height: windowHeight)

        // Create SwiftUI dialog
        let swiftUIDialog = SwiftUIChooseDialog(
            prompt: request.prompt,
            choices: request.choices,
            descriptions: request.descriptions,
            allowMultiple: request.allowMultiple,
            defaultSelection: request.defaultSelection,
            onComplete: { selectedIndices in
                if selectedIndices.isEmpty {
                    result = ChoiceResponse(selected: nil, cancelled: true, description: nil, descriptions: nil, comment: nil)
                } else if request.allowMultiple {
                    let selected = selectedIndices.sorted().map { request.choices[$0] }
                    let descs = selectedIndices.sorted().map { request.descriptions?[safe: $0] }
                    result = ChoiceResponse(selected: .multiple(selected), cancelled: false, description: nil, descriptions: descs, comment: nil)
                } else {
                    let idx = selectedIndices.first!
                    result = ChoiceResponse(selected: .single(request.choices[idx]), cancelled: false, description: request.descriptions?[safe: idx], descriptions: nil, comment: nil)
                }
                NSApp.stopModal()
            },
            onCancel: {
                result = ChoiceResponse(selected: nil, cancelled: true, description: nil, descriptions: nil, comment: nil)
                NSApp.stopModal()
            }
        )

        // Embed SwiftUI in NSHostingView
        let hostingView = NSHostingView(rootView: swiftUIDialog)
        hostingView.frame = NSRect(x: 8, y: 8, width: windowWidth - 16, height: windowHeight - 16)
        contentView.addSubview(hostingView)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSApp.runModal(for: window)
        window.close()

        return result ?? ChoiceResponse(selected: nil, cancelled: true, description: nil, descriptions: nil, comment: nil)
    }

    // MARK: - Text Input Dialog (Full AppKit with Modern Design)

    func textInput(_ request: TextInputRequest) -> TextInputResponse {
        reloadSettings()
        NSApp.setActivationPolicy(.accessory)

        var result: TextInputResponse?
        let windowWidth: CGFloat = 420

        // Calculate prompt height dynamically
        let promptFont = NSFont.systemFont(ofSize: 13)
        let promptAttrs: [NSAttributedString.Key: Any] = [.font: promptFont]
        let promptMaxWidth = windowWidth - 48
        let promptSize = (request.prompt as NSString).boundingRect(
            with: NSSize(width: promptMaxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: promptAttrs
        )
        let promptHeight = max(20, ceil(promptSize.height) + 8)

        // Calculate total window height based on content
        let topPadding: CGFloat = 28
        let iconSize: CGFloat = 56
        let iconToTitle: CGFloat = 16
        let titleHeight: CGFloat = 24
        let titleToPrompt: CGFloat = 8
        let promptToInput: CGFloat = 16
        let inputHeight: CGFloat = 44
        let inputToButtons: CGFloat = 20
        let buttonHeight: CGFloat = 48
        let bottomPadding: CGFloat = 20

        let windowHeight = topPadding + iconSize + iconToTitle + titleHeight + titleToPrompt + promptHeight + promptToInput + inputHeight + inputToButtons + buttonHeight + bottomPadding

        let (window, contentView) = createWindow(width: windowWidth, height: windowHeight)

        var yPos = windowHeight - topPadding

        // Icon
        yPos -= iconSize
        let iconBg = NSView(frame: NSRect(x: (windowWidth - iconSize) / 2, y: yPos, width: iconSize, height: iconSize))
        iconBg.wantsLayer = true
        iconBg.layer?.backgroundColor = Theme.accentBlue.withAlphaComponent(0.15).cgColor
        iconBg.layer?.cornerRadius = iconSize / 2
        contentView.addSubview(iconBg)

        let iconImage = NSImageView(frame: NSRect(x: (windowWidth - 24) / 2, y: yPos + 16, width: 24, height: 24))
        iconImage.image = NSImage(systemSymbolName: request.hidden ? "lock.fill" : "text.cursor", accessibilityDescription: nil)
        iconImage.contentTintColor = Theme.accentBlue
        contentView.addSubview(iconImage)

        // Title
        yPos -= iconToTitle + titleHeight
        let titleLabel = NSTextField(labelWithString: request.title)
        titleLabel.frame = NSRect(x: 24, y: yPos, width: windowWidth - 48, height: titleHeight)
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = Theme.textPrimary
        titleLabel.alignment = .center
        contentView.addSubview(titleLabel)

        // Prompt (wrapping text)
        yPos -= titleToPrompt + promptHeight
        let promptLabel = NSTextField(wrappingLabelWithString: request.prompt)
        promptLabel.frame = NSRect(x: 24, y: yPos, width: promptMaxWidth, height: promptHeight)
        promptLabel.font = promptFont
        promptLabel.textColor = Theme.textSecondary
        promptLabel.alignment = .center
        promptLabel.maximumNumberOfLines = 0
        promptLabel.lineBreakMode = .byWordWrapping
        contentView.addSubview(promptLabel)

        // Text Field
        yPos -= promptToInput + inputHeight
        let inputField = StyledTextField(isSecure: request.hidden, defaultValue: request.defaultValue)
        inputField.frame = NSRect(x: 28, y: yPos, width: windowWidth - 56, height: inputHeight)
        contentView.addSubview(inputField)

        // Buttons
        let buttonSpacing: CGFloat = 10
        let sideMargin: CGFloat = 20
        let buttonWidth = (windowWidth - sideMargin * 2 - buttonSpacing - 16) / 2

        let cancelButton = ModernButton(title: "Cancel", isPrimary: false)
        cancelButton.frame = NSRect(x: sideMargin + 8, y: bottomPadding, width: buttonWidth, height: buttonHeight)
        contentView.addSubview(cancelButton)

        let submitButton = ModernButton(title: "Submit", isPrimary: true)
        submitButton.frame = NSRect(x: sideMargin + buttonWidth + buttonSpacing + 8, y: bottomPadding, width: buttonWidth, height: buttonHeight)
        contentView.addSubview(submitButton)

        submitButton.onClick = {
            result = TextInputResponse(text: inputField.textField.stringValue, cancelled: false, comment: nil)
            NSApp.stopModal()
        }

        cancelButton.onClick = {
            result = TextInputResponse(text: nil, cancelled: true, comment: nil)
            NSApp.stopModal()
        }

        // Set up key view loop for tab navigation
        inputField.textField.nextKeyView = cancelButton
        cancelButton.nextKeyView = submitButton
        submitButton.nextKeyView = inputField.textField
        window.initialFirstResponder = inputField.textField

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Focus text field with proper modal run loop scheduling
        let modes: [RunLoop.Mode] = [.default, .modalPanel]
        RunLoop.current.perform(inModes: modes) {
            window.makeFirstResponder(inputField.textField)
        }

        NSApp.runModal(for: window)
        window.close()

        return result ?? TextInputResponse(text: nil, cancelled: true, comment: nil)
    }

    // MARK: - Notify (using osascript for bundle-free notifications)

    func notify(_ request: NotifyRequest) -> NotifyResponse {
        let title = buildTitle(request.title)
        var script = "display notification \"\(escapeForAppleScript(request.message))\" with title \"\(escapeForAppleScript(title))\""
        if let subtitle = request.subtitle {
            script += " subtitle \"\(escapeForAppleScript(subtitle))\""
        }
        if request.sound {
            script += " sound name \"default\""
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let success: Bool
        do {
            try process.run()
            process.waitUntilExit()
            success = process.terminationStatus == 0
        } catch {
            success = false
        }

        return NotifyResponse(success: success)
    }

    private func escapeForAppleScript(_ str: String) -> String {
        return str.replacingOccurrences(of: "\\", with: "\\\\")
                  .replacingOccurrences(of: "\"", with: "\\\"")
    }

    // MARK: - Speak

    func speak(_ request: SpeakRequest) -> SpeakResponse {
        let synth = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: request.text)

        let normalizedRate = Float(request.rate - 50) / 450.0
        utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, normalizedRate))

        if let voiceName = request.voice {
            let voices = AVSpeechSynthesisVoice.speechVoices()
            if let voice = voices.first(where: { $0.name.lowercased().contains(voiceName.lowercased()) }) {
                utterance.voice = voice
            }
        }

        var finished = false
        class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
            var onFinish: (() -> Void)?
            func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
                onFinish?()
            }
        }

        let delegate = SpeechDelegate()
        delegate.onFinish = { finished = true }
        synth.delegate = delegate
        synth.speak(utterance)

        while !finished {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        return SpeakResponse(success: true)
    }

    // MARK: - Multi-Question Dialog

    func questions(_ request: QuestionsRequest) -> QuestionsResponse {
        reloadSettings()
        NSApp.setActivationPolicy(.accessory)

        var result: QuestionsResponse?
        let windowWidth: CGFloat = 460
        let windowHeight: CGFloat = 650

        let (window, contentView) = createWindow(width: windowWidth, height: windowHeight)

        // Convert answers from Set<Int> to response format
        func buildResponse(answers: [String: Set<Int>], cancelled: Bool) -> QuestionsResponse {
            var responseAnswers: [String: QuestionsResponse.AnswerValue] = [:]
            var completedCount = 0

            for question in request.questions {
                if let indices = answers[question.id], !indices.isEmpty {
                    completedCount += 1
                    let labels = indices.sorted().map { question.options[$0].label }
                    if question.multiSelect {
                        responseAnswers[question.id] = .multiple(labels)
                    } else {
                        responseAnswers[question.id] = .single(labels.first!)
                    }
                }
            }

            return QuestionsResponse(answers: responseAnswers, cancelled: cancelled, completedCount: completedCount)
        }

        let onComplete: ([String: Set<Int>]) -> Void = { answers in
            result = buildResponse(answers: answers, cancelled: false)
            NSApp.stopModal()
        }

        let onCancel: () -> Void = {
            result = QuestionsResponse(answers: [:], cancelled: true, completedCount: 0)
            NSApp.stopModal()
        }

        // Create appropriate dialog based on mode
        let hostingView: NSHostingView<AnyView>
        switch request.mode {
        case "wizard":
            hostingView = NSHostingView(rootView: AnyView(
                SwiftUIWizardDialog(
                    questions: request.questions,
                    onComplete: onComplete,
                    onCancel: onCancel
                )
            ))
        case "accordion":
            hostingView = NSHostingView(rootView: AnyView(
                SwiftUIAccordionDialog(
                    questions: request.questions,
                    onComplete: onComplete,
                    onCancel: onCancel
                )
            ))
        default: // "questionnaire"
            hostingView = NSHostingView(rootView: AnyView(
                SwiftUIQuestionnaireDialog(
                    questions: request.questions,
                    onComplete: onComplete,
                    onCancel: onCancel
                )
            ))
        }

        hostingView.frame = NSRect(x: 8, y: 8, width: windowWidth - 16, height: windowHeight - 16)
        contentView.addSubview(hostingView)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSApp.runModal(for: window)
        window.close()

        return result ?? QuestionsResponse(answers: [:], cancelled: true, completedCount: 0)
    }
}

// MARK: - Extensions

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo: path.move(to: points[0])
            case .lineTo: path.addLine(to: points[0])
            case .curveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath: path.closeSubpath()
            case .cubicCurveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo: path.addQuadCurve(to: points[1], control: points[0])
            @unknown default: break
            }
        }
        return path
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Main

// MARK: - Pulse Response

struct PulseResponse: Codable {
    let success: Bool
}

func main() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    let args = CommandLine.arguments
    guard args.count >= 2 else {
        fputs("Usage: dialog-cli <command> [json]\n", stderr)
        fputs("Commands: confirm, choose, textInput, notify, speak, questions, pulse\n", stderr)
        exit(1)
    }

    let command = args[1]

    // Handle pulse command separately (no JSON needed)
    if command == "pulse" {
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("com.speak.pulse"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        let response = PulseResponse(success: true)
        if let data = try? JSONEncoder().encode(response),
           let output = String(data: data, encoding: .utf8) {
            print(output)
        }
        exit(0)
    }

    guard args.count >= 3 else {
        fputs("Usage: dialog-cli <command> <json>\n", stderr)
        fputs("Commands: confirm, choose, textInput, notify, speak, questions, pulse\n", stderr)
        exit(1)
    }

    let jsonInput = args[2]

    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    let manager = DialogManager.shared

    if let clientName = ProcessInfo.processInfo.environment["MCP_CLIENT_NAME"] {
        manager.setClientName(clientName)
    }

    guard let jsonData = jsonInput.data(using: .utf8) else {
        fputs("Invalid JSON input\n", stderr)
        exit(1)
    }

    var outputData: Data?

    switch command {
    case "confirm":
        guard let request = try? decoder.decode(ConfirmRequest.self, from: jsonData) else {
            fputs("Invalid confirm request\n", stderr)
            exit(1)
        }
        let response = manager.confirm(request)
        outputData = try? encoder.encode(response)

    case "choose":
        guard let request = try? decoder.decode(ChooseRequest.self, from: jsonData) else {
            fputs("Invalid choose request\n", stderr)
            exit(1)
        }
        let response = manager.choose(request)
        outputData = try? encoder.encode(response)

    case "textInput":
        guard let request = try? decoder.decode(TextInputRequest.self, from: jsonData) else {
            fputs("Invalid textInput request\n", stderr)
            exit(1)
        }
        let response = manager.textInput(request)
        outputData = try? encoder.encode(response)

    case "notify":
        guard let request = try? decoder.decode(NotifyRequest.self, from: jsonData) else {
            fputs("Invalid notify request\n", stderr)
            exit(1)
        }
        let response = manager.notify(request)
        outputData = try? encoder.encode(response)

    case "speak":
        guard let request = try? decoder.decode(SpeakRequest.self, from: jsonData) else {
            fputs("Invalid speak request\n", stderr)
            exit(1)
        }
        let response = manager.speak(request)
        outputData = try? encoder.encode(response)

    case "questions":
        guard let request = try? decoder.decode(QuestionsRequest.self, from: jsonData) else {
            fputs("Invalid questions request\n", stderr)
            exit(1)
        }
        let response = manager.questions(request)
        outputData = try? encoder.encode(response)

    default:
        fputs("Unknown command: \(command)\n", stderr)
        exit(1)
    }

    if let data = outputData, let output = String(data: data, encoding: .utf8) {
        print(output)
    } else {
        fputs("Failed to encode response\n", stderr)
        exit(1)
    }
}

main()
