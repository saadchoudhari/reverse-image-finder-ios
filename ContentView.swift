import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var searchService = ImageSearchService()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var safariURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Image Picker
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 260)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(height: 200)
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    Text("Tap to select an image")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                                searchService.clearResults()
                            }
                        }
                    }

                    // MARK: - Search Buttons
                    if selectedImage != nil {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                SearchButton(
                                    title: "Search Google",
                                    icon: "magnifyingglass.circle.fill",
                                    color: .blue
                                ) {
                                    safariURL = URL(string: "https://lens.google.com/")
                                }

                                SearchButton(
                                    title: "Search Yandex",
                                    icon: "photo.circle.fill",
                                    color: .orange
                                ) {
                                    safariURL = URL(string: "https://yandex.com/images/")
                                }
                            }

                            // ✅ CHANGED: passes selectedImage into findMatchingWebsites
                            Button {
                                if let image = selectedImage {                               // ✅ guards against nil
                                    Task { await searchService.findMatchingWebsites(for: image) }  // ✅ UIImage passed in
                                }
                            } label: {
                                Label("Find Matching Websites", systemImage: "globe.americas.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(searchService.isLoading)
                        }
                    }

                    // MARK: - Progress / Error
                    if searchService.isLoading {
                        ProgressView("Searching...")
                            .padding()
                    }

                    if let error = searchService.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // MARK: - Results
                    if !searchService.results.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Results")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(searchService.results) { result in
                                Button {
                                    safariURL = URL(string: result.url)
                                } label: {
                                    ResultRow(result: result)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Reverse Image Finder")
            .sheet(item: $safariURL) { url in
                SafariView(url: url)
            }
        }
    }
}

// MARK: - Subviews

struct SearchButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

struct ResultRow: View {
    let result: MatchResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(result.url)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
