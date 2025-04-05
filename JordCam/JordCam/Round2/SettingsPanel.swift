import SwiftUI

enum VideoResolution: String, CaseIterable, Identifiable {
    case hd1080p = "1080p"
    case uhd4k = "4K"
    
    var id: String { rawValue }
}

enum FrameRate: String, CaseIterable, Identifiable {
    case fps30 = "30 fps"
    case fps60 = "60 fps"
    
    var id: String { rawValue }
}

enum VideoCodec: String, CaseIterable, Identifiable {
    case h264 = "H.264"
    case proResLT = "ProRes LT"
    
    var id: String { rawValue }
}

struct SettingsPanel: View {
    @State private var selectedResolution: VideoResolution = .uhd4k
    @State private var selectedFrameRate: FrameRate = .fps60
    @State private var selectedCodec: VideoCodec = .h264

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Resolution")) {
                    Picker("Resolution", selection: $selectedResolution) {
                        ForEach(VideoResolution.allCases) { res in
                            Text(res.rawValue).tag(res)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section(header: Text("Frame Rate")) {
                    Picker("Frame Rate", selection: $selectedFrameRate) {
                        ForEach(FrameRate.allCases) { rate in
                            Text(rate.rawValue).tag(rate)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section(header: Text("Codec")) {
                    Picker("Codec", selection: $selectedCodec) {
                        ForEach(VideoCodec.allCases) { codec in
                            Text(codec.rawValue).tag(codec)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

