import SwiftUI

enum ScanState {
    case idle, scanning, paused
}

struct CameraView: View {
    @StateObject private var scanManager = ARScanManager()
    @State private var scanState: ScanState = .idle

    var body: some View {
        ZStack {
            LiDARMeshView(scanManager: scanManager)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        if scanState == .paused {
                            Button("Clear") {
                                scanManager.clearScan()
                                LiDARMeshView.coordinatorInstance?.clearMesh()  // <- clears visuals
                                scanState = .idle
                            }
                            .font(.caption)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
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
                                 scanState == .scanning ? "Stop Scan" : "Extend Scan")
                                .font(.caption)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

