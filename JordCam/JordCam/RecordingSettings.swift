import Foundation
import AVFoundation

enum VideoResolution: String, CaseIterable {
    case hd1080p = "1080p"
    case uhd4k = "4K"
    
    var dimensions: (width: Int, height: Int) {
        switch self {
        case .hd1080p: return (1920, 1080)
        case .uhd4k: return (3840, 2160)
        }
    }
}

enum FrameRate: Int, CaseIterable {
    case fps30 = 30
    case fps60 = 60
}

enum VideoCodec: String, CaseIterable {
    case h264 = "H.264"
    case proRes422 = "ProRes"
    
    var avCodec: AVVideoCodecType {
        switch self {
        case .h264: return .h264
        case .proRes422: return .proRes422
        }
    }
}

class RecordingSettings: ObservableObject {
    @Published var resolution: VideoResolution = .hd1080p
    @Published var frameRate: FrameRate = .fps30
    @Published var codec: VideoCodec = .h264
}
