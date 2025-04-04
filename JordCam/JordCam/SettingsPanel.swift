import SwiftUI

struct SettingsPanel: View {
    @Binding var selectedResolution: VideoResolution
    @Binding var selectedFrameRate: FrameRate
    @Binding var selectedCodec: VideoCodec

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Resolution")) {
                    Picker("Resolution", selection: $selectedResolution) {
                        ForEach(VideoResolution.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section(header: Text("Frame Rate")) {
                    Picker("Frame Rate", selection: $selectedFrameRate) {
                        ForEach(FrameRate.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section(header: Text("Codec")) {
                    Picker("Codec", selection: $selectedCodec) {
                        ForEach(VideoCodec.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Recording Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
