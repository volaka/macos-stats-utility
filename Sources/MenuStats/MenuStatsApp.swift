import Charts
import SwiftUI

@main
struct MenuStatsApp: App {
    @State private var monitor = Monitor()

    var body: some Scene {
        MenuBarExtra("MenuStats", systemImage: "gauge.with.dots.needle.50percent") {
            StatsPanel(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
    }
}

struct StatsPanel: View {
    let monitor: Monitor

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            VStack(spacing: 10) {
                Card(title: "CPU", symbol: "cpu", value: Format.percent(monitor.cpu)) {
                    Sparkline(values: monitor.cpuHistory.values, maxValue: 1, color: .blue)
                }

                Card(title: "Memory", symbol: "memorychip",
                     value: "\(Format.memory(Double(monitor.memoryUsed))) / \(Format.memory(Double(monitor.memoryTotal)))") {
                    ProgressView(value: Double(monitor.memoryUsed), total: Double(monitor.memoryTotal))
                        .tint(.purple)
                }

                Card(title: "Network", symbol: "network",
                     value: "↓ \(Format.rate(monitor.download))  ↑ \(Format.rate(monitor.upload))") {
                    let peak = max((monitor.downloadHistory.values + monitor.uploadHistory.values).max() ?? 1, 1)
                    ZStack {
                        Sparkline(values: monitor.downloadHistory.values, maxValue: peak, color: .green)
                        Sparkline(values: monitor.uploadHistory.values, maxValue: peak, color: .orange)
                    }
                }

                if let battery = monitor.battery {
                    Card(title: "Battery", symbol: battery.symbol,
                         value: "\(Format.percent(battery.charge)) · \(batteryState(battery))") {
                        HStack {
                            Text("Health \(Format.percent(battery.health))")
                            Spacer()
                            Text("Cycles \(battery.cycles)")
                            Spacer()
                            Text(String(format: "%.1f °C", battery.temperature))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Spacer()
                    Button("Quit") { NSApplication.shared.terminate(nil) }
                        .keyboardShortcut("q")
                        .buttonStyle(.glass)
                }
            }
        }
        .padding(12)
        .frame(width: 320)
    }

    private func batteryState(_ battery: Battery) -> String {
        if battery.isCharging { return "Charging" }
        return battery.isPluggedIn ? "Plugged in" : "On battery"
    }
}

struct Card<Content: View>: View {
    let title: String
    let symbol: String
    let value: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: symbol)
                    .font(.headline)
                Spacer()
                Text(value)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            content
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}

/// History graph; the y-axis scales to the data unless `maxValue` is given.
struct Sparkline: View {
    let values: [Double]
    var maxValue: Double?
    let color: Color

    var body: some View {
        Chart(Array(values.enumerated()), id: \.offset) { point in
            AreaMark(x: .value("Sample", point.offset), y: .value("Value", point.element))
                .foregroundStyle(color.opacity(0.25).gradient)
            LineMark(x: .value("Sample", point.offset), y: .value("Value", point.element))
                .foregroundStyle(color)
        }
        .chartXScale(domain: 0...(Monitor.historyLength - 1))
        .chartYScale(domain: 0...(maxValue ?? max(values.max() ?? 1, 1)))
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 36)
    }
}
