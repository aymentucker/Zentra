import Foundation

actor WorkspaceCleanerAnalyzer {
    func analyze(_ locations: [WorkspaceCleanupLocation]) async -> [WorkspaceCleanupResult] {
        var output: [WorkspaceCleanupResult] = []
        for location in locations {
            if Task.isCancelled { break }
            let result = await analyze(location)
            output.append(result)
        }
        return output
    }

    private func analyze(_ location: WorkspaceCleanupLocation) async -> WorkspaceCleanupResult {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: location.url.path, isDirectory: &isDirectory) else {
            return .init(location: location, bytes: 0, fileCount: 0, exists: false)
        }
        guard isDirectory.boolValue else {
            let v = try? location.url.resourceValues(forKeys: [.fileAllocatedSizeKey, .fileSizeKey])
            return .init(location: location, bytes: Int64(v?.fileAllocatedSize ?? v?.fileSize ?? 0), fileCount: 1, exists: true)
        }

        let keys: [URLResourceKey] = [.isRegularFileKey, .isSymbolicLinkKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey, .fileSizeKey]
        guard let e = fm.enumerator(at: location.url, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles, .skipsPackageDescendants], errorHandler: { _,_ in true }) else {
            return .init(location: location, bytes: 0, fileCount: 0, exists: true)
        }
        var bytes: Int64 = 0, count = 0
        while let url = e.nextObject() as? URL {
            if Task.isCancelled { break }
            guard let v = try? url.resourceValues(forKeys: Set(keys)), v.isSymbolicLink != true, v.isRegularFile == true else { continue }
            bytes += Int64(v.totalFileAllocatedSize ?? v.fileAllocatedSize ?? v.fileSize ?? 0)
            count += 1
        }
        return .init(location: location, bytes: bytes, fileCount: count, exists: true)
    }
}

@MainActor
final class WorkspaceCleanerModel: ObservableObject {
    @Published private(set) var results: [WorkspaceCleanupResult] = []
    @Published private(set) var isScanning = false
    @Published private(set) var isCleaning = false
    @Published var selected = Set<String>()
    @Published var errorMessage: String?
    @Published var lastCleanedBytes: Int64 = 0

    private let catalog = WorkspaceCleanupCatalog()
    private let analyzer = WorkspaceCleanerAnalyzer()
    private var task: Task<Void, Never>?

    func scan() {
        task?.cancel()
        results = []
        selected.removeAll()
        lastCleanedBytes = 0
        isScanning = true
        errorMessage = nil
        task = Task {
            let values = await analyzer.analyze(catalog.locations())
            guard !Task.isCancelled else {
                isScanning = false
                return
            }
            results = values.filter(\.exists)
            selected = Set(results.filter { $0.location.safety == .safe && $0.bytes > 0 }.map { $0.id })
            isScanning = false
        }
    }

    func cancel() { task?.cancel(); task = nil; isScanning = false }

    var selectedResults: [WorkspaceCleanupResult] { results.filter { selected.contains($0.id) && $0.location.safety != .protected } }
    var selectedBytes: Int64 { selectedResults.reduce(0) { $0 + $1.bytes } }

    func toggle(_ result: WorkspaceCleanupResult) {
        guard result.location.safety != .protected else { return }
        if selected.contains(result.id) { selected.remove(result.id) } else { selected.insert(result.id) }
    }

    func moveSelectedToTrash() {
        let items = selectedResults
        guard !items.isEmpty else { return }
        isCleaning = true; errorMessage = nil
        Task {
            var cleaned: Int64 = 0
            var failures: [String] = []

            for item in items {
                guard FileManager.default.fileExists(atPath: item.location.url.path) else { continue }
                do {
                    var destination: NSURL?
                    try FileManager.default.trashItem(at: item.location.url, resultingItemURL: &destination)
                    if !FileManager.default.fileExists(atPath: item.location.url.path) {
                        cleaned += item.bytes
                        selected.remove(item.id)
                    }
                } catch {
                    failures.append("\(item.location.name): \(error.localizedDescription)")
                }
            }

            lastCleanedBytes = cleaned
            isCleaning = false

            if failures.isEmpty {
                scan()
            } else {
                errorMessage = failures.joined(separator: "\n")
            }
        }
    }
}
