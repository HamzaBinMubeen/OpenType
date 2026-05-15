//
//  KeyboardView.swift
//  OpenTypeKeyboard
//

import SwiftUI

struct KeyboardView: View {
    @ObservedObject var model: KeyboardModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                if model.showsGlobeKey() {
                    Button {
                        model.switchKeyboard()
                    } label: {
                        Image(systemName: "globe")
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color(uiColor: .tertiarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    model.askAI()
                } label: {
                    askLabel
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(askBackground, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(model.phase.isBusy)
            }
            .padding(.horizontal, 8)

            statusView
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    @ViewBuilder
    private var askLabel: some View {
        switch model.phase {
        case .loading:
            HStack(spacing: 10) {
                ProgressView().tint(.white)
                Text("Thinking…").font(.body.weight(.semibold))
            }
        case .success:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                Text("Done").font(.body.weight(.semibold))
            }
        case .idle, .error:
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                Text("Ask AI").font(.body.weight(.semibold))
            }
        }
    }

    private var askBackground: Color {
        switch model.phase {
        case .loading: return Color.accentColor.opacity(0.65)
        case .success: return .green
        case .error:   return .red
        case .idle:    return .accentColor
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch model.phase {
        case .error(let msg):
            Text(msg)
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        case .idle:
            Text("Type your question in the text field, then tap Ask AI.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        case .loading, .success:
            EmptyView()
        }
    }
}
