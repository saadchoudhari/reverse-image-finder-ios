import Foundation
import UIKit
import Combine  // ✅ fixes @Published / ObservableObject compile errors

@MainActor
class ImageSearchService: ObservableObject {
    @Published var results: [MatchResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func findMatchingWebsites(for image: UIImage) async {
        isLoading = true
        errorMessage = nil
        results = []

        do {
            let apiKey = try loadAPIKey()
            let hostedURL = try await uploadImage(image, apiKey: apiKey)
            let fetchedResults = try await searchByImageURL(hostedURL, apiKey: apiKey)
            results = fetchedResults
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearResults() {
        results = []
        errorMessage = nil
    }

    // MARK: - Config

    private func loadAPIKey() throws -> String {
        // Step 1: check the file exists in the bundle at all
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            throw AppError(
                "Config.plist not found in app bundle. " +
                "In Xcode: select Config.plist in the Project Navigator → " +
                "open the File Inspector (⌥⌘1) → under Target Membership, " +
                "tick your app target. Then clean (⇧⌘K) and rebuild."
            )
        }

        // Step 2: check the file is a valid plist dictionary
        guard let dict = NSDictionary(contentsOfFile: path) else {
            throw AppError(
                "Config.plist exists but could not be read as a property list. " +
                "Make sure it is a valid XML plist (File → New → Property List in Xcode)."
            )
        }

        // Step 3: check SerpAPIKey is present and non-empty
        guard let key = dict["SerpAPIKey"] as? String, !key.isEmpty else {
            throw AppError(
                "SerpAPIKey is missing or empty in Config.plist. " +
                "Open Config.plist, add a String row with key \"SerpAPIKey\" " +
                "and paste your key from serpapi.com/manage-api-key."
            )
        }

        return key
    }

    // MARK: - Step 1: Upload image to SerpAPI proxy

    private func uploadImage(_ image: UIImage, apiKey: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AppError("Could not convert image to JPEG.")
        }
        guard let url = URL(string: "https://serpapi.com/images/proxy") else {
            throw AppError("Invalid proxy URL.")
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = buildMultipartBody(
            imageData: imageData,
            boundary: boundary,
            apiKey: apiKey
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppError("Image upload failed. Verify your SerpAPI key and plan limits.")
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hostedURL = json["url"] as? String else {
            throw AppError("Unexpected response from SerpAPI image proxy.")
        }

        return hostedURL
    }

    private func buildMultipartBody(imageData: Data, boundary: String, apiKey: String) -> Data {
        var body = Data()
        let crlf = "\r\n"

        body.append("--\(boundary)\(crlf)")
        body.append("Content-Disposition: form-data; name=\"api_key\"\(crlf)\(crlf)")
        body.append("\(apiKey)\(crlf)")

        body.append("--\(boundary)\(crlf)")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\(crlf)")
        body.append("Content-Type: image/jpeg\(crlf)\(crlf)")
        body.append(imageData)
        body.append(crlf)

        body.append("--\(boundary)--\(crlf)")
        return body
    }

    // MARK: - Step 2: Reverse image search

    private func searchByImageURL(_ imageURL: String, apiKey: String) async throws -> [MatchResult] {
        var components = URLComponents(string: "https://serpapi.com/search.json")!
        components.queryItems = [
            URLQueryItem(name: "engine",    value: "google_reverse_image"),
            URLQueryItem(name: "image_url", value: imageURL),
            URLQueryItem(name: "api_key",   value: apiKey)
        ]

        guard let url = components.url else {
            throw AppError("Could not build SerpAPI search URL.")
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppError("SerpAPI search failed. Check your key or plan limits.")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let imageResults = json["image_results"] as? [[String: Any]] else {
            return []   // valid: no matches found
        }

        return imageResults.compactMap { item in
            guard let title = item["title"] as? String,
                  let link  = item["link"]  as? String else { return nil }
            return MatchResult(title: title, url: link)   // ✅ matches Models.swift exactly
        }
    }
}

// MARK: - Private helpers

private struct AppError: LocalizedError {
    let errorDescription: String?
    init(_ message: String) { self.errorDescription = message }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }
}
