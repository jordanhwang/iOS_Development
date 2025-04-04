import Foundation
import AVFoundation
import ARKit
import simd

class RecordingManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordings: [RecordingMetadata] = []
    @Published var isScanningMesh = false
    @Published var meshWasScanned = false

    var settings: RecordingSettings?

    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var sessionStartTime: CMTime?
    
    private var recordingStartTime: TimeInterval?
    private let recordingDelay: TimeInterval = 2.0

    private var cameraTransforms: [(timestamp: TimeInterval, transform: simd_float4x4)] = []

    private var audioCaptureSession: AVCaptureSession?
    private var audioOutput: AVCaptureAudioDataOutput?

    private let metadataFile = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask).first!
        .appendingPathComponent("recordings.json")

    override init() {
        super.init()
        loadMetadataList()
    }

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    func startRecording() {
        cameraTransforms = []
        recordingStartTime = CACurrentMediaTime() + recordingDelay

        do {
            try setupWriter()
            isRecording = true

            // Always use the audio session that's already configured
            DispatchQueue.global(qos: .userInitiated).async {
                self.audioCaptureSession?.startRunning()
            }

        } catch {
            print("❌ Failed to set up writer: \(error)")
            isRecording = false
        }
    }

    func stopRecording() {
        guard isRecording else {
            print("⚠️ Not recording, skipping stop.")
            return
        }

        isRecording = false

        if let writer = assetWriter,
           let videoInput = videoInput,
           writer.status == .writing,
           videoInput.isReadyForMoreMediaData {
            
            videoInput.markAsFinished()
            writer.finishWriting {
                print("✅ Finished writing video")
            }
        } else {
            print("⚠️ Skipping finishWriting: invalid writer or input. Writer status: \(assetWriter?.status.rawValue ?? -1)")
        }

        audioCaptureSession?.stopRunning()
        exportCameraTransforms()
    }



    func handleFrame(_ frame: ARFrame) {
        guard isRecording else { return }

        if let start = recordingStartTime, frame.timestamp >= start {
            saveTransform(from: frame)
            savePixelBuffer(from: frame)
        }

    }

    
    func deleteRecording(_ recording: RecordingMetadata) {
        // Delete video file
        try? FileManager.default.removeItem(at: recording.videoURL)

        // Delete tracking JSON file
        try? FileManager.default.removeItem(at: recording.transformURL)

        // Remove from in-memory list
        recordings.removeAll { $0.id == recording.id }

        // Save updated list to disk
        saveMetadataList()

        print("🗑 Deleted recording: \(recording.displayName)")
    }

    func toggleMeshScanning(_ enabled: Bool) {
        isScanningMesh = enabled
        if enabled {
            meshWasScanned = true
        }
    }

    func clearMesh() {
        isScanningMesh = false
        meshWasScanned = false
    }
    
    func setWireframeVisibility(_ visible: Bool) {
        NotificationCenter.default.post(name: .toggleWireframe, object: visible)
    }

    private func saveTransform(from frame: ARFrame) {
        let transform = frame.camera.transform
        let timestamp = frame.timestamp
        cameraTransforms.append((timestamp: timestamp, transform: transform))
    }

    private func savePixelBuffer(from frame: ARFrame) {
        print("📸 Saving frame to video")

        let pixelBuffer = frame.capturedImage

        guard let input = videoInput,
              let adaptor = pixelBufferAdaptor,
              let writer = assetWriter else { return }

        let timestamp = CMTime(seconds: frame.timestamp, preferredTimescale: 600)

        if writer.status == .unknown {
            if let start = recordingStartTime {
                let startTime = CMTime(seconds: start, preferredTimescale: 600)
                writer.startWriting()
                writer.startSession(atSourceTime: startTime)
                sessionStartTime = startTime
            } else {
                // Fallback in case something weird happens
                writer.startWriting()
                writer.startSession(atSourceTime: timestamp)
                sessionStartTime = timestamp
            }
        }

        if input.isReadyForMoreMediaData {
            adaptor.append(pixelBuffer, withPresentationTime: timestamp)
        }
    }

    private func setupWriter() throws {
        guard let settings = settings else {
            throw NSError(domain: "Missing recording settings", code: 0)
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording_\(UUID().uuidString).mov")

        assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)

        // Video
        let resolution = settings.resolution.dimensions
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: settings.codec.avCodec,
            AVVideoWidthKey: resolution.width,
            AVVideoHeightKey: resolution.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: settings.codec == .h264 ? 12_000_000 : 40_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]

        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = true

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: resolution.width,
                kCVPixelBufferHeightKey as String: resolution.height
            ]
        )

        if assetWriter!.canAdd(videoInput) {
            assetWriter!.add(videoInput)
        }

        self.videoInput = videoInput
        self.pixelBufferAdaptor = adaptor

        // Audio
        let audioSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 64000
        ] as [String : Any]

        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput.expectsMediaDataInRealTime = true

        if assetWriter!.canAdd(audioInput) {
            assetWriter!.add(audioInput)
            setupAudioCapture(audioInput)
        }
    }

    private func setupAudioCapture(_ writerInput: AVAssetWriterInput) {
        let session = AVCaptureSession()
        session.beginConfiguration()

        guard let mic = AVCaptureDevice.default(for: .audio),
              let micInput = try? AVCaptureDeviceInput(device: mic),
              session.canAddInput(micInput) else {
            print("❌ Failed to access microphone")
            return
        }

        session.addInput(micInput)

        let output = AVCaptureAudioDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "AudioQueue"))

        if session.canAddOutput(output) {
            session.addOutput(output)
            audioOutput = output
            audioCaptureSession = session
            session.commitConfiguration()
            session.startRunning()
        }
    }

    private func exportCameraTransforms() {
        let dictArray = cameraTransforms.map { entry -> [String: Any] in
            let matrix = entry.transform
            return [
                "timestamp": entry.timestamp,
                "transform": [
                    matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z, matrix.columns.0.w,
                    matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z, matrix.columns.1.w,
                    matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z, matrix.columns.2.w,
                    matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z, matrix.columns.3.w
                ]
            ]
        }

        let jsonURL = FileManager.default.temporaryDirectory.appendingPathComponent("camera_motion_\(UUID().uuidString).json")

        do {
            let data = try JSONSerialization.data(withJSONObject: dictArray, options: .prettyPrinted)
            try data.write(to: jsonURL)
            print("\u{1F4C4} Camera transform data saved to: \(jsonURL)")

            if let settings = settings,
               let videoURL = assetWriter?.outputURL {
                let metadata = RecordingMetadata(
                    id: UUID(),
                    videoURL: videoURL,
                    transformURL: jsonURL,
                    date: Date(),
                    resolution: settings.resolution.rawValue,
                    frameRate: settings.frameRate.rawValue,
                    codec: settings.codec.rawValue
                )

                recordings.append(metadata)
                saveMetadataList()
            }

        } catch {
            print("❌ Failed to save transform data: \(error)")
        }
    }

    private func saveMetadataList() {
        do {
            let data = try JSONEncoder().encode(recordings)
            try data.write(to: metadataFile)
        } catch {
            print("❌ Failed to save recordings metadata: \(error)")
        }
    }

    private func loadMetadataList() {
        do {
            let data = try Data(contentsOf: metadataFile)
            recordings = try JSONDecoder().decode([RecordingMetadata].self, from: data)
        } catch {
            print("ℹ️ No previous recordings or failed to load: \(error)")
        }
    }
}

extension RecordingManager: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isRecording,
              let writer = assetWriter,
              writer.status == .writing,
              let audioInput = writer.inputs.first(where: { $0.mediaType == .audio }),
              audioInput.isReadyForMoreMediaData else {
            return
        }

        audioInput.append(sampleBuffer)
    }
}
