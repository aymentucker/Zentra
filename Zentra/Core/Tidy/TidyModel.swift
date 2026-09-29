import Foundation
import SwiftUI
import AppKit

@MainActor
final class TidyModel: ObservableObject {
    @Published private(set) var analysis: TidyAnalysis?
    @Published private(set) var isScanning = false
    @Published private(set) var isOrganizing = false
    @Published var selected = Set<URL>()
    @Published var errorMessage: String?

    private let analyzer = TidyAnalyzer()
    private var scanTask: Task<Void, Never>?

    func scan(_ folder: URL) {
        scanTask?.cancel()
        analysis = nil
        selected.removeAll()
        errorMessage = nil
        isScanning = true

        scanTask = Task {
            do {
                let result = try await analyzer.analyze(folder: folder)
                guard !Task.isCancelled else {
                    isScanning = false
                    return
                }
                analysis = result
                selected = Set(result.items.map(\.url))
                isScanning = false
            } catch is CancellationError {
                isScanning = false
            } catch {
                guard !Task.isCancelled else {
                    isScanning = false
                    return
                }
                analysis = nil
                selected.removeAll()
                errorMessage = error.localizedDescription
                isScanning = false
            }
        }
    }

    func toggle(_ item: TidyItem) {
        if selected.contains(item.url) {
            selected.remove(item.url)
        } else {
            selected.insert(item.url)
        }
    }

    func organize(in folder: URL) {
        guard let analysis, !isOrganizing else { return }
        let items = analysis.items.filter { selected.contains($0.url) }
        guard !items.isEmpty else { return }

        isOrganizing = true
        errorMessage = nil

        var failures: [String] = []
        for item in items {
            let name: String
            switch item.category {
            case .images: name = "Images"
            case .video: name = "Videos"
            case .audio: name = "Audio"
            case .documents: name = "Documents"
            case .archives: name = "Archives"
            case .installers: name = "Installers"
            case .other: name = "Other"
            }

            let destinationFolder = folder
                .appendingPathComponent("Zentra Organized")
                .appendingPathComponent(name)

            do {
                try FileManager.default.createDirectory(
                    at: destinationFolder,
                    withIntermediateDirectories: true
                )
                var destination = destinationFolder.appendingPathComponent(item.url.lastPathComponent)
                var n = 2

                while FileManager.default.fileExists(atPath: destination.path) {
                    let base = item.url.deletingPathExtension().lastPathComponent
                    let ext = item.url.pathExtension
                    let collisionName = ext.isEmpty ? "\(base) \(n)" : "\(base) \(n).\(ext)"
                    destination = destinationFolder.appendingPathComponent(collisionName)
                    n += 1
                }

                try FileManager.default.moveItem(at: item.url, to: destination)
                selected.remove(item.url)
            } catch {
                failures.append("\(item.url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        isOrganizing = false
        if failures.isEmpty {
            scan(folder)
        } else {
            errorMessage = failures.joined(separator: "\n")
        }
    }
}
