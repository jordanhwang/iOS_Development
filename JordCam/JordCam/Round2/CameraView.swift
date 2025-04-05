import SwiftUI

enum ScanState {
    case idle
    case scanning
    case paused
}

struct CameraView: View {
    @State private var isSettingsOpen = false
    @State private var isRecording = false
    @State private var showGallery = false
    @State private var scanState: ScanState = .idle

    @StateObject private var cameraManager = CameraSessionManager()
    @StateObject private var scanManager = ARScanManager()

    var body: some View {
        ZStack {
            // ✅ Bottom Layer: Live Camera Feed
            CameraPreview(session: cameraManager.session)
                .edgesIgnoringSafeArea(.all)

            // ✅ Middle Layer: LiDAR Mesh Overlay (transparent)
            if scanState != .idle {
                LiDARMeshView(scanManager: scanManager)
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(false)
            }

            // ⚙️ Settings Button (Top Right)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isSettingsOpen.toggle()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .foregroundColor(.white)
                            .padding()
                    }
                    .sheet(isPresented: $isSettingsOpen) {
                        SettingsPanel()
                    }
                }
                Spacer()
            }

            // 🔴 Record Button (Bottom Center)
            VStack {
                Spacer()
                Button(action: {
                    isRecording.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.gray.opacity(0.8) : Color.white)
                            .frame(width: 80, height: 80)

                        Circle()
                            .fill(Color.red)
                            .frame(width: isRecording ? 40 : 60, height: isRecording ? 40 : 60)
                            .animation(.easeInOut(duration: 0.2), value: isRecording)
                    }
                }
                .padding(.bottom, 30)
            }

            // 🖼 Gallery Button (Bottom Left)
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        showGallery = true
                    }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                    .padding(.leading)
                    .sheet(isPresented: $showGallery) {
                        GalleryView()
                    }

                    Spacer()
                }
                .padding(.bottom, 70)
            }

            // 🧪 Scan Controls (Bottom Right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Button(action: {
                            switch scanState {
                            case .idle:
                                scanManager.startScan()
                                scanState = .scanning
                            case .scanning:
                                scanManager.stopScan()
                                scanState = .paused
                            case .paused:
                                scanManager.startScan()
                                scanState = .scanning
                            }
                        }) {
                            Text(scanState == .idle ? "Start Scan" :
                                 scanState == .scanning ? "Stop Scan" :
                                 "Extend Scan")
                                .font(.caption)
                                .padding(10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        if scanState == .paused {
                            Button("Clear") {
                                scanManager.clearScan()
                                scanState = .idle
                            }
                            .font(.caption)
                            .padding(10)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            cameraManager.start()
        }
        .onDisappear {
            cameraManager.stop()
        }
    }
}

