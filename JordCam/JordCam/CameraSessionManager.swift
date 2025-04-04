import AVFoundation

struct RecordingSettings {
    let resolution: VideoResolution
    let frameRate: FrameRate
    let codec: VideoCodec
}


class CameraSessionManager: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    let session = AVCaptureSession()

    private let movieOutput = AVCaptureMovieFileOutput()
    private var outputURL: URL?

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Set up the camera input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            print("❌ Failed to create camera input.")
            session.commitConfiguration()
            return
        }

        session.addInput(videoInput)
        
        // Set up microphone input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }


        // Add movie output
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        session.commitConfiguration()
    }
    
    func apply(settings: RecordingSettings) {
        session.beginConfiguration()

        // Resolution
        switch settings.resolution {
        case .hd1080p:
            session.sessionPreset = .hd1920x1080
        case .uhd4k:
            session.sessionPreset = .hd4K3840x2160
        }

        // Frame Rate
        if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                      for: .video,
                                                      position: .back) {
            do {
                try videoDevice.lockForConfiguration()
                switch settings.frameRate {
                case .fps30:
                    videoDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
                    videoDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
                case .fps60:
                    videoDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 60)
                    videoDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 60)
                }
                videoDevice.unlockForConfiguration()
            } catch {
                print("⚠️ Couldn't set frame rate: \(error)")
            }
        }

        // Codec – info only, real control happens at export
        print("📼 Selected Codec: \(settings.codec.rawValue)")

        session.commitConfiguration()
    }


    func startRecording() {
        guard !movieOutput.isRecording else { return }

        let outputDir = FileManager.default.temporaryDirectory
        let fileName = "video_\(UUID().uuidString).mov"
        let fileURL = outputDir.appendingPathComponent(fileName)
        outputURL = fileURL

        movieOutput.startRecording(to: fileURL, recordingDelegate: self)
        print("🎬 Started recording to: \(fileURL)")
    }

    func stopRecording() {
        guard movieOutput.isRecording else { return }
        movieOutput.stopRecording()
        print("🛑 Stopping recording...")
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            print("❌ Recording error: \(error)")
        } else {
            print("✅ Video saved to: \(outputFileURL)")
            // Here’s where you’ll eventually save to your gallery / export logic
        }
    }
}

