import SwiftUI
import AVKit

struct GalleryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var videoFiles: [URL] = []

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(videoFiles, id: \.self) { url in
                        VStack {
                            VideoThumbnailView(url: url)
                                .frame(height: 180)
                                .cornerRadius(12)
                                .clipped()

                            HStack {
                                Button("Play") {
                                    playVideo(url)
                                }
                                .buttonStyle(.bordered)

                                Button("Export") {
                                    exportBundle(for: url)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Your Recordings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear(perform: loadVideos)
    }

    private func loadVideos() {
        let recordingsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("recordings", isDirectory: true)

        do {
            let files = try FileManager.default.contentsOfDirectory(at: recordingsDir, includingPropertiesForKeys: nil)
            videoFiles = files.filter { $0.pathExtension == "mov" }
        } catch {
            print("❌ Failed to load videos: \(error)")
        }
    }

    private func playVideo(_ url: URL) {
        let player = AVPlayer(url: url)
        let vc = AVPlayerViewController()
        vc.player = player

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(vc, animated: true) {
                player.play()
            }
        }
    }

    private func exportBundle(for url: URL) {
        print("📦 Export tapped for: \(url.lastPathComponent)")
        // TODO: Export video + mesh + camera animation here
    }
}


struct VideoThumbnailView: View {
    let url: URL

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
            Image(systemName: "video")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .padding(30)
        }
    }
}
