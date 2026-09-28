import Foundation

protocol CleanupMoving: Sendable {
    func moveRecoverably(_ url: URL) throws -> URL
    func exists(_ url: URL) -> Bool
}

struct SystemCleanupMover: CleanupMoving {
    func moveRecoverably(_ url: URL) throws -> URL {
        var destination: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &destination)
        guard let destination = destination as URL? else {
            throw CleanupExecutionError.destinationUnavailable
        }
        return destination
    }

    func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}

actor CleanupExecutor {
    private let mover: any CleanupMoving

    init(mover: any CleanupMoving = SystemCleanupMover()) {
        self.mover = mover
    }

    func execute(_ plan: CleanupPlan) async -> CleanupExecutionReport {
        let started = Date()
        var results: [CleanupExecutionItem] = []

        for item in plan.items {
            if Task.isCancelled { break }
            do {
                guard mover.exists(item.url) else {
                    throw CleanupExecutionError.sourceMissing(item.url)
                }
                let destination = try mover.moveRecoverably(item.url)
                guard !mover.exists(item.url), mover.exists(destination) else {
                    throw CleanupExecutionError.verificationFailed(item.url)
                }
                results.append(CleanupExecutionItem(sourceURL: item.url, destinationURL: destination, size: item.size, succeeded: true, message: nil))
            } catch {
                results.append(CleanupExecutionItem(sourceURL: item.url, destinationURL: nil, size: item.size, succeeded: false, message: error.localizedDescription))
            }
            await Task.yield()
        }

        return CleanupExecutionReport(startedAt: started, finishedAt: Date(), items: results)
    }
}
