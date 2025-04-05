import SwiftUI
import ARKit
import SceneKit

struct ARViewContainer: UIViewRepresentable {
    @Binding var scanMode: ScanMode
    var recorder: RecordingManager

    func makeCoordinator() -> ARViewCoordinator {
        return ARViewCoordinator(scanMode: $scanMode, recorder: recorder)
    }

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.delegate = context.coordinator
        sceneView.scene = SCNScene()
        sceneView.automaticallyUpdatesLighting = true
        sceneView.debugOptions = [
            ARSCNDebugOptions.showWorldOrigin,
            ARSCNDebugOptions.showFeaturePoints
        ]
        runSession(on: sceneView, scanningMesh: recorder.isScanningMesh)
        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        if scanMode == .idle {
            context.coordinator.clearAllMeshes()
            runSession(on: uiView, scanningMesh: false)
        }

        if context.coordinator.lastScanningState != (scanMode == .scanning) {
            context.coordinator.lastScanningState = (scanMode == .scanning)
            print("🔁 Scan state changed – scanningMesh = \(scanMode == .scanning)")
            runSession(on: uiView, scanningMesh: scanMode == .scanning)
        }
    }

    private func runSession(on sceneView: ARSCNView, scanningMesh: Bool) {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = scanningMesh ? .mesh : []
        }

        config.environmentTexturing = .automatic

        let shouldReset = scanMode == .idle
        let options: ARSession.RunOptions = shouldReset ? [.resetTracking, .removeExistingAnchors] : []

        sceneView.session.run(config, options: options)
    }
}

class ARViewCoordinator: NSObject, ARSCNViewDelegate {
    @Binding var scanMode: ScanMode
    var recorder: RecordingManager
    var lastScanningState = false
    var isTrackingStable = false
    var hasStartedScanAfterStableTracking = false
    var meshNodes: [UUID: SCNNode] = [:]

    init(scanMode: Binding<ScanMode>, recorder: RecordingManager) {
        self._scanMode = scanMode
        self.recorder = recorder
        super.init()
        setupWireframeToggleObserver()
    }

    private func setupWireframeToggleObserver() {
        NotificationCenter.default.addObserver(
            forName: .toggleWireframe,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let visible = notification.object as? Bool else { return }

            for node in self.meshNodes.values {
                node.geometry?.firstMaterial?.transparency = visible ? 1.0 : 0.0
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = (renderer as? ARSCNView)?.session.currentFrame else { return }

        // Track AR state
        isTrackingStable = frame.camera.trackingState == .normal

        if isTrackingStable, !hasStartedScanAfterStableTracking, scanMode == .scanning {
            hasStartedScanAfterStableTracking = true
            DispatchQueue.main.async {
                print("🚀 Starting scan after stable tracking")
                self.recorder.isScanningMesh = true
            }
        }

        // 🔁 Tell recorder to save this frame
        recorder.handleFrame(frame)
    }


    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor else { return }
        print("🆕 Mesh anchor added")
        let meshNode = createGeometryNode(from: meshAnchor)
        meshNodes[meshAnchor.identifier] = meshNode
        node.addChildNode(meshNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor else { return }

        if let existingNode = meshNodes[meshAnchor.identifier] {
            existingNode.removeFromParentNode()
        }

        let updatedNode = createGeometryNode(from: meshAnchor)
        meshNodes[meshAnchor.identifier] = updatedNode
        node.addChildNode(updatedNode)
    }

    func clearAllMeshes() {
        for node in meshNodes.values {
            node.removeFromParentNode()
        }
        meshNodes.removeAll()
        print("🧼 Cleared all mesh nodes from the scene.")
    }

    private func createGeometryNode(from anchor: ARMeshAnchor) -> SCNNode {
        let geometry = SCNGeometry.fromARMeshGeometry(anchor.geometry)

        let material = SCNMaterial()
        material.fillMode = .lines
        material.diffuse.contents = UIColor.white
        material.isDoubleSided = true
        material.lightingModel = .constant
        material.writesToDepthBuffer = true
        material.readsFromDepthBuffer = true
        material.isLitPerPixel = false

        geometry.firstMaterial = material

        let node = SCNNode(geometry: geometry)
        print("✅ Mesh created: \(anchor.geometry.vertices.count) vertices, \(anchor.geometry.faces.count) triangles")
        return node
    }
}

extension SCNGeometry {
    static func fromARMeshGeometry(_ meshGeometry: ARMeshGeometry) -> SCNGeometry {
        let vertexCount = meshGeometry.vertices.count
        let vertexBuffer = meshGeometry.vertices.buffer
        let vertexStride = meshGeometry.vertices.stride
        let vertexOffset = meshGeometry.vertices.offset

        let vertexData = Data(bytesNoCopy: vertexBuffer.contents(), count: vertexBuffer.length, deallocator: .none)

        let vertexSource = SCNGeometrySource(data: vertexData,
                                             semantic: .vertex,
                                             vectorCount: vertexCount,
                                             usesFloatComponents: true,
                                             componentsPerVector: 3,
                                             bytesPerComponent: MemoryLayout<Float>.size,
                                             dataOffset: vertexOffset,
                                             dataStride: vertexStride)

        let indexCount = meshGeometry.faces.count * 3
        let faceBuffer = meshGeometry.faces.buffer
        let indexData = Data(bytesNoCopy: faceBuffer.contents(), count: faceBuffer.length, deallocator: .none)

        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .triangles,
                                         primitiveCount: meshGeometry.faces.count,
                                         bytesPerIndex: MemoryLayout<UInt32>.size)

        return SCNGeometry(sources: [vertexSource], elements: [element])
    }
}
