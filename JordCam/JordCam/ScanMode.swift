import Foundation

enum ScanMode {
    case idle     // Not scanning
    case scanning // Actively scanning
    case extended // Scanning paused, but resume is possible
}

extension Notification.Name {
    static let toggleWireframe = Notification.Name("toggleWireframe")
}
