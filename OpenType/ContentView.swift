//
//  ContentView.swift
//  OpenType
//

import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    SetupStep(
                        number: 1,
                        title: "Add the keyboard",
                        detail: "Settings → General → Keyboard → Keyboards → Add New Keyboard… → OpenType."
                    )

                    SetupStep(
                        number: 2,
                        title: "Allow Full Access",
                        detail: "Tap OpenType in that same list and toggle Allow Full Access ON. This is required so the keyboard can reach the Gemini API."
                    )

                    SetupStep(
                        number: 3,
                        title: "Use it anywhere",
                        detail: "Type your question in any app, then long-press the globe key, switch to OpenType, and tap Ask AI. The reply replaces your question."
                    )

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .navigationTitle("OpenType")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(.tint)
            Text("Ask AI from any keyboard.")
                .font(.title2.weight(.semibold))
            Text("OpenType adds a tiny AI prompt to your keyboard. Tap, type a question, and the answer lands at your cursor.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SetupStep: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.title3.weight(.semibold))
                .frame(width: 32, height: 32)
                .background(Circle().fill(.tint.opacity(0.15)))
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
