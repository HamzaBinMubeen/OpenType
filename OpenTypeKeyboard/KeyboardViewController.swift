//
//  KeyboardViewController.swift
//  OpenTypeKeyboard
//

import UIKit
import SwiftUI
import Combine

final class KeyboardModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case success
        case error(String)

        var isBusy: Bool {
            switch self {
            case .loading, .success: return true
            case .idle, .error: return false
            }
        }
    }

    @Published var phase: Phase = .idle

    private let client: GeminiClient
    private let insertReply: (String, Int) -> Void
    private let captureContext: () -> String
    let switchKeyboard: () -> Void
    let showsGlobeKey: () -> Bool
    private let hasFullAccess: () -> Bool

    init(client: GeminiClient,
         insertReply: @escaping (String, Int) -> Void,
         captureContext: @escaping () -> String,
         switchKeyboard: @escaping () -> Void,
         showsGlobeKey: @escaping () -> Bool,
         hasFullAccess: @escaping () -> Bool) {
        self.client = client
        self.insertReply = insertReply
        self.captureContext = captureContext
        self.switchKeyboard = switchKeyboard
        self.showsGlobeKey = showsGlobeKey
        self.hasFullAccess = hasFullAccess
    }

    func askAI() {
        guard hasFullAccess() else {
            phase = .error("Enable Allow Full Access in Settings → General → Keyboard → Keyboards → OpenType.")
            return
        }
        let captured = captureContext()
        let trimmed = captured.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            phase = .error("Type your question into the text field first.")
            return
        }
        let prompt = trimmed.count > 4000 ? String(trimmed.suffix(4000)) : trimmed
        let deleteCount = captured.count

        phase = .loading

        Task { [weak self] in
            guard let self else { return }
            do {
                let reply = try await self.client.generate(prompt: Self.composePrompt(prompt))
                await MainActor.run {
                    self.insertReply(reply, deleteCount)
                    self.phase = .success
                }
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                await MainActor.run {
                    if self.phase == .success { self.phase = .idle }
                }
            } catch {
                await MainActor.run {
                    self.phase = .error(error.localizedDescription)
                }
            }
        }
    }

    private static func composePrompt(_ userText: String) -> String {
        """
        You are an AI assistant integrated into an iOS keyboard. The user has typed the following into a text field, intending it as a prompt for you:

        ---
        \(userText)
        ---

        Reply with ONLY the plain text that should replace the user's prompt in the text field. No preamble (no "Here's…", no "Sure!"), no surrounding quotes, no markdown formatting, no code fences. Output the bare text the user wants to send, and nothing else.
        """
    }
}

final class KeyboardViewController: UIInputViewController {

    private var model: KeyboardModel!
    private var hostingController: UIHostingController<KeyboardView>!
    private var heightConstraint: NSLayoutConstraint!
    private let keyboardHeight: CGFloat = 220

    override func viewDidLoad() {
        super.viewDidLoad()

        let apiKey = (Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String) ?? ""
        let client = GeminiClient(apiKey: apiKey)

        model = KeyboardModel(
            client: client,
            insertReply: { [weak self] text, deleteCount in
                guard let proxy = self?.textDocumentProxy else { return }
                for _ in 0..<deleteCount { proxy.deleteBackward() }
                proxy.insertText(text)
            },
            captureContext: { [weak self] in
                self?.textDocumentProxy.documentContextBeforeInput ?? ""
            },
            switchKeyboard: { [weak self] in
                self?.advanceToNextInputMode()
            },
            showsGlobeKey: { [weak self] in
                self?.needsInputModeSwitchKey ?? false
            },
            hasFullAccess: { [weak self] in
                self?.hasFullAccess ?? false
            }
        )

        let root = KeyboardView(model: model)
        let host = UIHostingController(rootView: root)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear

        addChild(host)
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
        hostingController = host

        heightConstraint = view.heightAnchor.constraint(equalToConstant: keyboardHeight)
        heightConstraint.priority = UILayoutPriority(999)
        heightConstraint.isActive = true
    }
}
