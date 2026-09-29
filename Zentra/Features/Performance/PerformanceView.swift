import SwiftUI

struct PerformanceView: View {
    @StateObject private var model = PerformanceModel()
    let isActive: Bool

    init(isActive: Bool = true) {
        self.isActive = isActive
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.zentraBackground, Color.zentraBackground, Color.zentraAccent.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if let snapshot = model.snapshot {
                        metrics(snapshot)
                        memoryCard(snapshot.memory)
                        processes(snapshot.processes)
                        startup(snapshot.startupItems)
                    } else { loading }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 48).padding(.vertical, 36)
            }
        }
        .task { updateRefreshState() }
        .onChange(of: isActive) { _, _ in updateRefreshState() }
        .onDisappear { model.stopAutoRefresh() }
    }

    private func updateRefreshState() {
        if isActive { model.startAutoRefresh() }
        else { model.stopAutoRefresh() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 7) {
                Text("performance.title").zentraFont(30, weight: .bold).foregroundStyle(Color.zentraTextPrimary)
                Text("performance.subtitle").zentraFont(13).foregroundStyle(Color.zentraTextSecondary)
            }
            Spacer()
            Button("performance.refresh") { model.refresh() }.buttonStyle(.plain).foregroundStyle(Color.zentraAccent)
        }
    }

    private func metrics(_ s: PerformanceSnapshot) -> some View {
        HStack(spacing: 12) {
            metric("performance.cpu", String(format: "%.0f%%", s.cpuPercent), "cpu")
            metric("performance.memory", String(format: "%.0f%%", s.memory.pressure * 100), "memorychip")
            metric("performance.uptime", uptime(s.uptime), "clock")
        }
    }

    private func metric(_ title: LocalizedStringKey, _ value: String, _ icon: String) -> some View {
        ZentraCard { VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(Color.zentraAccent)
            Text(value).zentraFont(19, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
            Text(title).zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
        }.frame(maxWidth: .infinity, alignment: .leading) }
    }

    private func memoryCard(_ memory: MemorySnapshot) -> some View {
        ZentraCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("performance.memory.title").zentraFont(14, weight: .semibold)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: Int64(memory.used), countStyle: .memory) + " / " + ByteCountFormatter.string(fromByteCount: Int64(memory.total), countStyle: .memory)).zentraFont(10).foregroundStyle(Color.zentraTextSecondary)
                }
                ProgressView(value: memory.pressure).tint(Color.zentraAccent)
                HStack {
                    Text("performance.memory.note").zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: Int64(memory.available), countStyle: .memory) + " " + String(localized: "performance.available")).zentraFont(9.5).foregroundStyle(Color.zentraTextSecondary)
                }
            }
        }
    }

    private func processes(_ items: [CPUProcess]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("performance.processes").zentraFont(15, weight: .semibold)
            ZentraCard {
                VStack(spacing: 0) {
                    ForEach(items) { process in
                        HStack {
                            Image(systemName: "gearshape.2").foregroundStyle(Color.zentraAccent).frame(width: 24)
                            Text(process.name).lineLimit(1).zentraFont(10.5, weight: .medium)
                            Spacer()
                            Text("PID \(process.pid)").zentraFont(8.5).foregroundStyle(Color.zentraTextTertiary)
                            Text(String(format: "%.1f%%", process.cpuPercent)).frame(width: 58, alignment: .trailing).zentraFont(10, weight: .semibold)
                        }.padding(.vertical, 8)
                        if process.id != items.last?.id { Divider().opacity(0.3) }
                    }
                }
            }
        }
    }

    private func startup(_ items: [StartupItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("performance.startup").zentraFont(15, weight: .semibold)
                Spacer()
                Text(String(format: String(localized: "performance.startup.count"), items.count)).zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
            }
            Text("performance.startup.note").zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
            ZentraCard {
                if items.isEmpty { Text("performance.startup.empty").zentraFont(10.5).foregroundStyle(Color.zentraTextSecondary) }
                else {
                    VStack(spacing: 0) {
                        ForEach(items.prefix(30)) { item in
                            HStack {
                                Image(systemName: item.domain == "user" ? "person.crop.circle" : "gearshape").foregroundStyle(Color.zentraAccent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).lineLimit(1).zentraFont(10.5, weight: .medium)
                                    Text(item.domain == "user" ? "performance.startup.user" : "performance.startup.system").zentraFont(8.5).foregroundStyle(Color.zentraTextTertiary)
                                }
                                Spacer()
                                Button("storage.action.reveal") { model.reveal(item) }.buttonStyle(.plain).zentraFont(9.5).foregroundStyle(Color.zentraTextSecondary)
                            }.padding(.vertical, 8)
                            if item.id != items.prefix(30).last?.id { Divider().opacity(0.3) }
                        }
                    }
                }
            }
        }
    }

    private var loading: some View {
        ZentraCard { HStack(spacing: 12) { ProgressView(); Text("performance.loading").zentraFont(11).foregroundStyle(Color.zentraTextSecondary); Spacer() } }
    }

    private func uptime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let days = hours / 24
        return days > 0 ? String(format: String(localized: "performance.uptime.days"), days) : String(format: String(localized: "performance.uptime.hours"), hours)
    }
}
