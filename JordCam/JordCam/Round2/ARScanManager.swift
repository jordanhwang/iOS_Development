import Foundation
import ARKit

class ARScanManager: ObservableObject {
    let session = ARSession()

    func startScan() {
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .mesh
        config.environmentTexturing = .none
        config.frameSemantics = .sceneDepth
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func stopScan() {
        session.pause()
    }

    func clearScan() {
        session.run(session.configuration ?? ARWorldTrackingConfiguration(), options: [.removeExistingAnchors])
    }
}
