import Foundation
import ARKit

class ARScanManager: NSObject, ObservableObject {
    let session = ARSession()
    @Published var isScanning: Bool = false

    override init() {
        super.init()
        startCameraOnlySession()
    }

    func startCameraOnlySession() {
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = []
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        session.run(config)
        isScanning = false
    }

    func startScan() {
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else { return }
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .meshWithClassification
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        session.run(config, options: []) // ✅ No reset
        isScanning = true
    }

    func stopScan() {
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = []  // ✅ Turn mesh off, camera stays on
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        session.run(config, options: []) // ✅ Keep anchors, no reset
        isScanning = false
    }

    func clearScan() {
        session.pause()  // Optional: stops tracking momentarily
        startCameraOnlySession()
    }
}

