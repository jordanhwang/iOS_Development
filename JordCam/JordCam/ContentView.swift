import SwiftUI

struct ContentView: View {
    @StateObject var recorder = RecordingManager()
    @StateObject var settings = RecordingSettings()
    @State private var navigateToGallery = false
    @State private var selectedRecording: RecordingMetadata? = nil

    
    @State private var isBouncing = false
    @State private var showSettingsPanel = false
    @State private var showGallery = false
    @State private var orientation = UIDevice.current.orientation
    @State private var isScanning = false
    @State private var showWireframe = true
    @State private var scanMode: ScanMode = .idle
    
    var body: some View {
        ZStack {
            // AR View
            ARViewContainer(scanMode: $scanMode, recorder: recorder)
                .edgesIgnoringSafeArea(.all)
            
            // Dismiss panel tap area
            if showSettingsPanel {
                Color.black.opacity(0.001)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showSettingsPanel = false
                        }
                    }
            }
            
            // Top buttons
            VStack {
                HStack {
                    // Toggle Wireframe
                    Button(showWireframe ? "Hide Wireframe" : "Show Wireframe") {
                        showWireframe.toggle()
                        NotificationCenter.default.post(name: .toggleWireframe, object: showWireframe)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showSettingsPanel.toggle()
                        }
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .padding(10)
                    }
                }
                .padding(.top, 50)
                .padding(.horizontal)
                
                Spacer()
            }
            
            // Record Button — position and rotate based on orientation
            recordButton
                .padding()
            //                .rotationEffect(rotation(for: orientation))
            //                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(for: orientation))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(for: orientation))
            
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    Button(action: { showGallery = true }) {
                        Image(systemName: "play.square.stack")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .offset(x: 30, y: -5)
                            .padding()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 12) {
                        // Clear Button
                        if recorder.meshWasScanned {
                            Button("Clear") {
                                recorder.clearMesh()
                                scanMode = .idle
                                isScanning = false
                                showWireframe = true // reset visibility in UI
                                NotificationCenter.default.post(name: .toggleWireframe, object: true)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        }
                        
                        Button(action: {
                            switch scanMode {
                            case .idle:
                                scanMode = .scanning
                                isScanning = true
                                recorder.toggleMeshScanning(true)
                                
                            case .scanning:
                                scanMode = .extended
                                isScanning = false
                                recorder.toggleMeshScanning(false)
                                
                            case .extended:
                                scanMode = .scanning
                                isScanning = true
                                recorder.toggleMeshScanning(true)
                            }
                            print("🟩 SCAN MODE CHANGED TO: \(scanMode)")
                            print("🟦 isScanningMesh: \(recorder.isScanningMesh)")
                            
                            
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }) {
                            Label(
                                scanMode == .idle ? "3D Scan" :
                                    scanMode == .scanning ? "Stop Scan" : "Extend",
                                systemImage: "arkit"
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(scanMode == .scanning ? .red : .white.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        }
                    }
                    .padding()
                }
            }
            
            // Settings Panel
            if showSettingsPanel {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Resolution").font(.caption).foregroundColor(.white)
                    ForEach(VideoResolution.allCases, id: \.self) { option in
                        Button {
                            settings.resolution = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if settings.resolution == option {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                            .foregroundColor(.white)
                        }
                    }
                    
                    Text("Frame Rate").font(.caption).foregroundColor(.white)
                    ForEach(FrameRate.allCases, id: \.self) { option in
                        Button {
                            settings.frameRate = option
                        } label: {
                            HStack {
                                Text("\(option.rawValue) fps")
                                if settings.frameRate == option {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                            .foregroundColor(.white)
                        }
                    }
                    
                    Text("Codec").font(.caption).foregroundColor(.white)
                    ForEach(VideoCodec.allCases, id: \.self) { option in
                        Button {
                            settings.codec = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if settings.codec == option {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                .frame(width: 200)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .padding(.top, 90)
                .padding(.trailing, 12)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(1)
                .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
        }
        .environmentObject(settings)
        .sheet(isPresented: $showGallery) {
            GalleryView(recorder: recorder)
        }
        .onAppear {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                withAnimation(.easeInOut) {
                    self.orientation = UIDevice.current.orientation
                }
            }
        }
        .onDisappear {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
    }
    
    // Record Button View
    private var recordButton: some View {
        Button(action: {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 15)) {
                isBouncing = true
                recorder.settings = settings
                recorder.toggleRecording()
            }
            
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isBouncing = false
            }
        }) {
            Image(systemName: recorder.isRecording ? "stop.circle" : "video.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .scaleEffect(isBouncing ? 1.1 : 1.0)
            //                .rotationEffect(iconRotation(for: orientation)) // 👈 NEW
                .foregroundStyle(
                    recorder.isRecording ? .red : .white,
                    recorder.isRecording ? .white : .white
                )
                .shadow(radius: 5)
            
        }
    }
    
    // Orientation-based alignment
    private func alignment(for orientation: UIDeviceOrientation) -> Alignment {
        switch orientation {
        case .landscapeLeft:
            return .trailing
        case .landscapeRight:
            return .leading
        case .portraitUpsideDown:
            return .top
        case .portrait, .faceUp, .faceDown:
            return .bottom
        default:
            return .bottom
        }
    }
}
