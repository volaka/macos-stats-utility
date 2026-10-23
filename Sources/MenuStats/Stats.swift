import Darwin
import Foundation
import IOKit

struct CPUTicks {
    var busy: UInt64
    var total: UInt64
}

struct MemoryPages {
    var `internal`: UInt64
    var purgeable: UInt64
    var wired: UInt64
    var compressed: UInt64
}

struct NetBytes {
    var received: UInt64
    var sent: UInt64
}

struct Battery {
    var charge: Double
    var isCharging: Bool
    var isPluggedIn: Bool
    var health: Double
    var cycles: Int
    var temperature: Double
}

struct History {
    let limit: Int
    private(set) var values: [Double] = []

    mutating func append(_ value: Double) {
        values.append(value)
        if values.count > limit { values.removeFirst(values.count - limit) }
    }
}

enum Stats {
    // MARK: Calculations

    static func cpuUsage(from old: CPUTicks, to new: CPUTicks) -> Double {
        // Tick counters are 32-bit and wrap; skip the sample instead of trapping on underflow.
        guard new.total > old.total, new.busy >= old.busy else { return 0 }
        return Double(new.busy - old.busy) / Double(new.total - old.total)
    }

    /// Same definition as Activity Monitor's "Memory Used": app memory + wired + compressed.
    static func memoryUsed(_ pages: MemoryPages, pageSize: UInt64) -> UInt64 {
        let appMemory = pages.internal > pages.purgeable ? pages.internal - pages.purgeable : 0
        return (appMemory + pages.wired + pages.compressed) * pageSize
    }

    /// Counters can reset (interface restart) or wrap; report 0 instead of a negative rate.
    static func rate(from old: UInt64, to new: UInt64, seconds: Double) -> Double {
        guard new >= old, seconds > 0 else { return 0 }
        return Double(new - old) / seconds
    }

    /// Health uses the raw capacities because `MaxCapacity` is always 100 on Apple Silicon.
    static func battery(from properties: [String: Any]) -> Battery? {
        guard let current = properties["CurrentCapacity"] as? Int,
              let max = properties["MaxCapacity"] as? Int, max > 0,
              let rawMax = properties["AppleRawMaxCapacity"] as? Int,
              let design = properties["DesignCapacity"] as? Int, design > 0
        else { return nil }

        return Battery(
            charge: Double(current) / Double(max),
            isCharging: properties["IsCharging"] as? Bool ?? false,
            isPluggedIn: properties["ExternalConnected"] as? Bool ?? false,
            health: Double(rawMax) / Double(design),
            cycles: properties["CycleCount"] as? Int ?? 0,
            temperature: Double(properties["Temperature"] as? Int ?? 0) / 100
        )
    }

    // MARK: System readers

    static func readCPUTicks() -> CPUTicks? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let user = UInt64(info.cpu_ticks.0)
        let system = UInt64(info.cpu_ticks.1)
        let idle = UInt64(info.cpu_ticks.2)
        let nice = UInt64(info.cpu_ticks.3)
        return CPUTicks(busy: user + system + nice, total: user + system + idle + nice)
    }

    static func readMemoryPages() -> MemoryPages? {
        var info = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        return MemoryPages(
            internal: UInt64(info.internal_page_count),
            purgeable: UInt64(info.purgeable_count),
            wired: UInt64(info.wire_count),
            compressed: UInt64(info.compressor_page_count)
        )
    }

    /// Sums physical interfaces (en*) only, so VPN tunnels don't double-count traffic.
    static func readNetBytes() -> NetBytes {
        var bytes = NetBytes(received: 0, sent: 0)
        var addresses: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addresses) == 0 else { return bytes }
        defer { freeifaddrs(addresses) }

        var cursor = addresses
        while let entry = cursor?.pointee {
            defer { cursor = entry.ifa_next }
            guard entry.ifa_addr?.pointee.sa_family == UInt8(AF_LINK),
                  String(cString: entry.ifa_name).hasPrefix("en"),
                  let data = entry.ifa_data?.assumingMemoryBound(to: if_data.self).pointee
            else { continue }
            bytes.received += UInt64(data.ifi_ibytes)
            bytes.sent += UInt64(data.ifi_obytes)
        }
        return bytes
    }

    static func readBatteryProperties() -> [String: Any] {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return [:] }
        defer { IOObjectRelease(service) }

        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dictionary = properties?.takeRetainedValue() as? [String: Any]
        else { return [:] }
        return dictionary
    }
}

extension Battery {
    /// SF Symbols only has a bolt variant for the full battery.
    var symbol: String {
        if isCharging { return "battery.100percent.bolt" }
        return "battery.\(Int((charge * 4).rounded()) * 25)percent"
    }
}
