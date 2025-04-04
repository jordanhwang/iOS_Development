import SwiftUI
import AVKit

struct RecordingPreviewView: View {
    let recording: RecordingMetadata
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let player = player {
                    VideoPlayer(player: player)
                        .frame(height: 240)
                        .cornerRadius(12)
                        .padding()
                        .onAppear {
                            player.seek(to: .zero)
                            player.play()
                        }
                } else {
                    ProgressView("Loading...")
                        .frame(height: 240)
                }

                Text(recording.formattedDetails)
                    .font(.subheadline)

                Button(action: {
                    shareFiles()
                }) {
                    Label("Export Video & JSON", systemImage: "square.and.arrow.up")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Preview")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        player?.pause()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            player = AVPlayer(url: recording.videoURL)
        }
        .onDisappear {
            player = nil
        }
    }

    private func shareFiles() {
        let activityVC = UIActivityViewController(
            activityItems: [recording.videoURL, recording.transformURL],
            applicationActivities: nil
        )

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}
