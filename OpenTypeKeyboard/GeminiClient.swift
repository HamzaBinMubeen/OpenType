//
//  GeminiClient.swift
//  OpenTypeKeyboard
//

import Foundation

enum GeminiError: Error, LocalizedError {
    case missingAPIKey
    case http(status: Int, body: String)
    case emptyReply
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not configured."
        case .http(let status, _):
            return "Gemini error (HTTP \(status))."
        case .emptyReply:
            return "Empty reply from Gemini."
        case .transport(let err):
            return "Network: \(err.localizedDescription)"
        }
    }
}

struct GeminiClient {
    private static let model = "gemini-3-flash-preview"

    let apiKey: String

    nonisolated func generate(prompt: String) async throws -> String {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, key != "PASTE_YOUR_GEMINI_KEY_HERE" else {
            throw GeminiError.missingAPIKey
        }

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(Self.model):generateContent")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(key, forHTTPHeaderField: "x-goog-api-key")

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "thinkingConfig": ["thinkingLevel": "minimal"]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let resp: URLResponse
        do {
            (data, resp) = try await URLSession.shared.data(for: req)
        } catch {
            throw GeminiError.transport(error)
        }

        guard let http = resp as? HTTPURLResponse else {
            throw GeminiError.http(status: -1, body: "")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GeminiError.http(status: http.statusCode, body: body)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let text = decoded.candidates?.first?.content?.parts?
            .compactMap(\.text)
            .joined()
            ?? ""
        guard !text.isEmpty else { throw GeminiError.emptyReply }
        return text
    }

    private struct Response: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable { let text: String? }
                let parts: [Part]?
            }
            let content: Content?
        }
        let candidates: [Candidate]?
    }
}
