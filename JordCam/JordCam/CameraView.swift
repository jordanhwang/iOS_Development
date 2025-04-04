import SwiftUI

enum VideoResolution: String, CaseIterable {
    case hd1080p = "1080p"
    case uhd4k = "4K"
}

enum FrameRate: String, CaseIterable {
    case fps30 = "30fps"
    case fps60 = "60fps"
}

enum VideoCodec: String, CaseIterable {
    case h264 = "H.264"
    case proResLT = "ProRes LT"
}

struct CameraView: View {
    @StateObject private var cameraManager = CameraSessionManager()
    
    @State private var selectedResolution: VideoResolution = .hd1080p
    @State private var selectedFrameRate: FrameRate = .fps30
    @State private var selectedCodec: VideoCodec = .h264
    @State private var isSettingsOpen = false
    @State private var isRecording = false


    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isSettingsOpen.toggle()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .padding(12)
                            .background(Color.black.opacity(0.2))
                            .clipShape(Circle())
                            .foregroundStyle(.white)
                            .padding()
                    }
                    .sheet(isPresented: $isSettingsOpen) {
                        SettingsPanel(
                            selectedResolution: $selectedResolution,
                            selectedFrameRate: $selectedFrameRate,
                            selectedCodec: $selectedCodec
                        )
                    }
                }
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        isRecording.toggle()

                        let currentSettings = RecordingSettings(
                            resolution: selectedResolution,
                            frameRate: selectedFrameRate,
                            codec: selectedCodec
                        )
                        cameraManager.apply(settings: currentSettings)

                        if isRecording {
                            cameraManager.startRecording()
                        } else {
                            cameraManager.stopRecording()
                        }
                    }) {

                        ZStack {
                            Circle()
                                .fill(isRecording ? Color.gray.opacity(0.8) : Color.white)
                                .frame(width: 80, height: 80)

                            Circle()
                                .fill(isRecording ? Color.red : Color.red)
                                .frame(width: isRecording ? 40 : 60, height: isRecording ? 40 : 60)
                                .animation(.easeInOut(duration: 0.2), value: isRecording)
                        }
                    }
                    .padding(.bottom, 30)
                    Spacer()
                }
            }
        }
        .onAppear {
            cameraManager.session.startRunning()
        }
        .onDisappear {
            cameraManager.session.stopRunning()
        }
    }
}


