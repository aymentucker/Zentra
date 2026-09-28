import Foundation

struct MemorySnapshot: Sendable {
    let total: UInt64
    let used: UInt64
    let available: UInt64
    let pressure: Double
}

struct CPUProcess: Identifiable, Hashable, Sendable {
    let pid: Int32
    let name: String
    let cpuPercent: Double
    var id: Int32 { pid }
}

struct StartupItem: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String
    let domain: String
    var id: String { url.path }
}

struct PerformanceSnapshot: Sendable {
    let cpuPercent: Double
    let memory: MemorySnapshot
    let uptime: TimeInterval
    let processes: [CPUProcess]
    let startupItems: [StartupItem]
    let capturedAt: Date
}
