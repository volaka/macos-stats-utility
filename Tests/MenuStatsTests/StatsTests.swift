import Testing
import Foundation
@testable import MenuStats

@Test func cpuUsageIsBusyShareOfTicksBetweenSamples() {
    let old = CPUTicks(busy: 100, total: 1_000)
    let new = CPUTicks(busy: 130, total: 1_100)
    #expect(Stats.cpuUsage(from: old, to: new) == 0.3)
}

@Test func cpuUsageIsZeroWhenNoTicksElapsed() {
    let ticks = CPUTicks(busy: 100, total: 1_000)
    #expect(Stats.cpuUsage(from: ticks, to: ticks) == 0)
}

@Test func memoryUsedMatchesActivityMonitor() {
    let pages = MemoryPages(internal: 1_000, purgeable: 100, wired: 200, compressed: 50)
    #expect(Stats.memoryUsed(pages, pageSize: 16_384) == 1_150 * 16_384)
}

@Test func networkRateIsBytesPerSecond() {
    #expect(Stats.rate(from: 1_000, to: 6_000, seconds: 5) == 1_000)
}

@Test func networkRateIsZeroWhenCounterResets() {
    #expect(Stats.rate(from: 6_000, to: 1_000, seconds: 5) == 0)
}

@Test func batteryIsParsedFromSmartBatteryProperties() throws {
    let properties: [String: Any] = [
        "CurrentCapacity": 87, "MaxCapacity": 100, "IsCharging": true, "ExternalConnected": true,
        "AppleRawMaxCapacity": 5_231, "DesignCapacity": 6_249,
        "CycleCount": 180, "Temperature": 3_107,
    ]
    let battery = try #require(Stats.battery(from: properties))
    #expect(battery.charge == 0.87)
    #expect(battery.isCharging)
    #expect(battery.isPluggedIn)
    #expect(abs(battery.health - 0.837) < 0.001)
    #expect(battery.cycles == 180)
    #expect(battery.temperature == 31.07)
}

@Test func batteryIsNilWithoutBatteryProperties() {
    #expect(Stats.battery(from: [:]) == nil)
}

@Test func historyKeepsOnlyTheNewestValues() {
    var history = History(limit: 3)
    for value in [1.0, 2, 3, 4] { history.append(value) }
    #expect(history.values == [2, 3, 4])
}

@Test func systemReadersReturnPlausibleValues() throws {
    let ticks = try #require(Stats.readCPUTicks())
    #expect(ticks.total > ticks.busy)

    let pages = try #require(Stats.readMemoryPages())
    let used = Stats.memoryUsed(pages, pageSize: UInt64(getpagesize()))
    #expect(used > 0 && used < ProcessInfo.processInfo.physicalMemory)
}
