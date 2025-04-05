import SwiftUI
import ARKit
import SceneKit

struct LiDARMeshView: UIViewRepresentable {
    @ObservedObject var scanManager: ARScanManager
    static var coordinatorInstance: Coordinator?  // <-- store the coordinator

    func makeCoordinator() -> Coordinator {
        let c = Coordinator(scanManager: scanManager)
        LiDARMeshView.coordinatorInstance = c
        return c
    }

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        sceneView.session = scanManager.session
        sceneView.scene = SCNScene()
        sceneView.automaticallyUpdatesLighting = true
        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

class Coordinator: NSObject, ARSCNViewDelegate {
    let scanManager: ARScanManager
    var meshNodes: [UUID: SCNNode] = [:]

    init(scanManager: ARScanManager) {
        self.scanManager = scanManager
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor else { return }
        let meshNode = SCNNode(geometry: SCNGeometry.fromARMeshGeometry(meshAnchor.geometry))
        styleMesh(meshNode)
        meshNodes[meshAnchor.identifier] = meshNode
        node.addChildNode(meshNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor else { return }
        meshNodes[meshAnchor.identifier]?.removeFromParentNode()
        let updatedNode = SCNNode(geometry: SCNGeometry.fromARMeshGeometry(meshAnchor.geometry))
        styleMesh(updatedNode)
        meshNodes[meshAnchor.identifier] = updatedNode
        node.addChildNode(updatedNode)
    }
    
    func clearMesh() {
        for node in meshNodes.values {
            node.removeFromParentNode()
        }
        meshNodes.removeAll()
        print("🧼 Cleared all mesh nodes from the scene.")
    }


    private func styleMesh(_ node: SCNNode) {
        guard let material = node.geometry?.firstMaterial else { return }
        material.fillMode = .lines
        material.diffuse.contents = UIColor.white
        material.isDoubleSided = true
        material.lightingModel = .constant
        material.writesToDepthBuffer = true
        material.readsFromDepthBuffer = true
        material.isLitPerPixel = false
    }
}

extension SCNGeometry {
    static func fromARMeshGeometry(_ meshGeometry: ARMeshGeometry) -> SCNGeometry {
        let vertexCount = meshGeometry.vertices.count
        let vertexBuffer = meshGeometry.vertices.buffer
        let vertexStride = meshGeometry.vertices.stride
        let vertexOffset = meshGeometry.vertices.offset

        let vertexData = Data(bytesNoCopy: vertexBuffer.contents(),
                              count: vertexBuffer.length,
                              deallocator: .none)

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
        let indexData = Data(bytesNoCopy: faceBuffer.contents(),
                             count: faceBuffer.length,
                             deallocator: .none)

        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .triangles,
                                         primitiveCount: meshGeometry.faces.count,
                                         bytesPerIndex: MemoryLayout<UInt32>.size)

        return SCNGeometry(sources: [vertexSource], elements: [element])
    }
}

