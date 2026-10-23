import Foundation
import Observation

@MainActor @Observable
final class Monitor {
    static let interval = 5.0
    static let historyLength = 60

    private(set) var cpu = 0.0
    private(set) var cpuHistory = History(limit: historyLength)
    private(set) var memoryUsed: UInt64 = 0
    let memoryTotal = ProcessInfo.processInfo.physicalMemory
    private(set) var download = 0.0
    private(set) var upload = 0.0
    private(set) var downloadHistory = History(limit: historyLength)
    private(set) var uploadHistory = History(limit: historyLength)
    private(set) var battery: Battery?

    private var lastTicks: CPUTicks?
    private var lastNet: NetBytes?
    private var lastSample = ContinuousClock.now

    // Samples for the app's lifetime, so graphs already have data when the panel opens.
    init() {
        Task {
            while true {
                sample()
                try? await Task.sleep(for: .seconds(Self.interval))
            }
        }
    }

    private func sample() {
        let now = ContinuousClock.now
        let seconds = (now - lastSample) / .seconds(1)
        lastSample = now

        if let ticks = Stats.readCPUTicks() {
            if let lastTicks {
                cpu = Stats.cpuUsage(from: lastTicks, to: ticks)
                cpuHistory.append(cpu)
            }
            lastTicks = ticks
        }

        if let pages = Stats.readMemoryPages() {
            memoryUsed = Stats.memoryUsed(pages, pageSize: UInt64(getpagesize()))
        }

        let net = Stats.readNetBytes()
        if let lastNet {
            download = Stats.rate(from: lastNet.received, to: net.received, seconds: seconds)
            upload = Stats.rate(from: lastNet.sent, to: net.sent, seconds: seconds)
            downloadHistory.append(download)
            uploadHistory.append(upload)
        }
        lastNet = net

        battery = Stats.battery(from: Stats.readBatteryProperties())
    }
}
