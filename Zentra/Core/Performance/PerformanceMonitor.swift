import Foundation
import Darwin

actor PerformanceMonitor {
    func snapshot() -> PerformanceSnapshot {
        PerformanceSnapshot(
            cpuPercent: cpuUsage(),
            memory: memorySnapshot(),
            uptime: ProcessInfo.processInfo.systemUptime,
            processes: topProcesses(),
            startupItems: StartupItemScanner().scan(),
            capturedAt: Date()
        )
    }

    private func cpuUsage() -> Double {
        var count: mach_msg_type_number_t = 0
        var info: processor_info_array_t?
        var processorCount: natural_t = 0
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processorCount, &info, &count)
        guard result == KERN_SUCCESS, let info else { return 0 }
        defer { vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(count) * vm_size_t(MemoryLayout<integer_t>.size)) }
        var used: UInt64 = 0
        var total: UInt64 = 0
        for cpu in 0..<Int(processorCount) {
            let offset = Int(CPU_STATE_MAX) * cpu
            let user = UInt64(info[offset + Int(CPU_STATE_USER)])
            let system = UInt64(info[offset + Int(CPU_STATE_SYSTEM)])
            let nice = UInt64(info[offset + Int(CPU_STATE_NICE)])
            let idle = UInt64(info[offset + Int(CPU_STATE_IDLE)])
            used += user + system + nice
            total += user + system + nice + idle
        }
        return total > 0 ? min(100, Double(used) / Double(total) * 100) : 0
    }

    private func memorySnapshot() -> MemorySnapshot {
        let total = ProcessInfo.processInfo.physicalMemory
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return MemorySnapshot(total: total, used: 0, available: total, pressure: 0) }
        let page = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * page
        let wired = UInt64(stats.wire_count) * page
        let compressed = UInt64(stats.compressor_page_count) * page
        let used = min(total, active + wired + compressed)
        let available = total > used ? total - used : 0
        return MemorySnapshot(total: total, used: used, available: available, pressure: total > 0 ? Double(used) / Double(total) : 0)
    }

    private func topProcesses() -> [CPUProcess] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-A", "-o", "pid=,pcpu=,comm=", "-r"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do { try task.run(); task.waitUntilExit() } catch { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }
        return output.split(separator: "\n").compactMap { line in
            let parts = line.split(maxSplits: 2, whereSeparator: { $0.isWhitespace })
            guard parts.count == 3, let pid = Int32(parts[0]), let cpu = Double(parts[1]) else { return nil }
            return CPUProcess(pid: pid, name: URL(fileURLWithPath: String(parts[2])).lastPathComponent, cpuPercent: cpu)
        }.prefix(8).map { $0 }
    }
}

struct StartupItemScanner {
    func scan() -> [StartupItem] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let locations: [(String, URL)] = [
            ("user", home.appendingPathComponent("Library/LaunchAgents")),
            ("system", URL(fileURLWithPath: "/Library/LaunchAgents")),
            ("system", URL(fileURLWithPath: "/Library/LaunchDaemons"))
        ]
        var result: [StartupItem] = []
        for (domain, root) in locations {
            guard let urls = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { continue }
            for url in urls where url.pathExtension == "plist" {
                result.append(StartupItem(url: url, name: url.deletingPathExtension().lastPathComponent, domain: domain))
            }
        }
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
