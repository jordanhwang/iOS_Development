import Foundation
import AVFoundation
import UIKit

struct RecordingMetadata: Codable, Identifiable {
    let id: UUID
    let videoURL: URL
    let transformURL: URL
    let date: Date
    let resolution: String
    let frameRate: Int
    let codec: String

    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    var formattedDetails: String {
        "\(resolution) • \(frameRate)fps • \(codec)"
    }

    var thumbnail: UIImage? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let midpoint = CMTimeMultiplyByFloat64(asset.duration, multiplier: 0.5)

        do {
            let cgImage = try imageGenerator.copyCGImage(at: midpoint, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("⚠️ Failed to generate thumbnail: \(error)")
            return nil
        }
    }

    var durationFormatted: String {
        let asset = AVAsset(url: videoURL)
        let duration = asset.duration
        let seconds = CMTimeGetSeconds(duration)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "00:00"
    }
}
