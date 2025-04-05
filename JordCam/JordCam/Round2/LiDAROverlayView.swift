import SwiftUI
import ARKit
import SceneKit

struct LiDARMeshView: UIViewRepresentable {
    @ObservedObject var scanManager: ARScanManager

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        sceneView.session = scanManager.session
        sceneView.scene = SCNScene()
        sceneView.automaticallyUpdatesLighting = true

        // 💡 Make it transparent
        sceneView.backgroundColor = .clear
        sceneView.isOpaque = false
        sceneView.scene.background.contents = UIColor.clear

        // Optional: disable ARKit's default camera feed rendering
        sceneView.rendersCameraGrain = false
        sceneView.rendersMotionBlur = false
        sceneView.pointOfView?.camera?.wantsHDR = false
        sceneView.pointOfView?.camera?.wantsExposureAdaptation = false

        return sceneView
    }


    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, ARSCNViewDelegate {
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let meshAnchor = anchor as? ARMeshAnchor else { return }
            let meshNode = createWireframeNode(from: meshAnchor)
            node.addChildNode(meshNode)
        }

        private func createWireframeNode(from meshAnchor: ARMeshAnchor) -> SCNNode {
            let geometry = meshAnchor.geometry
            let vertexCount = geometry.vertices.count

            var vertices: [SCNVector3] = []
            for i in 0..<vertexCount {
                let vertex = geometry.vertex(at: UInt32(i), transform: meshAnchor.transform)
                vertices.append(SCNVector3(vertex.x, vertex.y, vertex.z))
            }

            var indices: [UInt32] = []
            let faceCount = geometry.faces.count
            let indexBuffer = geometry.faces.buffer.contents()
            let indexStride = geometry.faces.indexCountPerPrimitive * MemoryLayout<UInt32>.size

            for i in 0..<faceCount {
                let faceOffset = i * indexStride
                let pointer = indexBuffer.advanced(by: faceOffset).bindMemory(to: UInt32.self, capacity: 3)
                indices.append(pointer[0])
                indices.append(pointer[1])
                indices.append(pointer[2])
            }

            let vertexSource = SCNGeometrySource(vertices: vertices)
            let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<UInt32>.size)
            let element = SCNGeometryElement(data: indexData, primitiveType: .triangles, primitiveCount: indices.count / 3, bytesPerIndex: MemoryLayout<UInt32>.size)

            let meshGeometry = SCNGeometry(sources: [vertexSource], elements: [element])
            let material = SCNMaterial()
            material.fillMode = .lines
            material.diffuse.contents = UIColor.white
            material.isDoubleSided = true
            meshGeometry.materials = [material]

            return SCNNode(geometry: meshGeometry)
        }
    }
}

extension ARMeshGeometry {
    func vertex(at index: UInt32, transform: simd_float4x4) -> SIMD3<Float> {
        let stride = self.vertices.stride
        let offset = Int(index) * stride
        let pointer = self.vertices.buffer.contents().advanced(by: offset)
        let float3Pointer = pointer.assumingMemoryBound(to: Float.self)
        let vertex = SIMD3(float3Pointer[0], float3Pointer[1], float3Pointer[2])
        return (transform * SIMD4(vertex, 1)).xyz
    }
}

extension SIMD4<Float> {
    var xyz: SIMD3<Float> {
        SIMD3(x, y, z)
    }
}

