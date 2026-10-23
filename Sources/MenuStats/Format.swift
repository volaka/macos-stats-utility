import Foundation

enum Format {
    static func bytes(_ value: Double) -> String {
        scaled(value, base: 1000)
    }

    /// RAM is sized in binary units (36 GB = 36 × 1024³ bytes).
    static func memory(_ value: Double) -> String {
        scaled(value, base: 1024)
    }

    private static func scaled(_ value: Double, base: Double) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = value
        var unit = 0
        while value >= base && unit < units.count - 1 {
            value /= base
            unit += 1
        }
        return unit == 0 ? "\(Int(value)) B" : String(format: "%.1f %@", value, units[unit])
    }

    static func rate(_ bytesPerSecond: Double) -> String {
        bytes(bytesPerSecond) + "/s"
    }

    static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }
}
