import Foundation

struct DuplicateFile: Identifiable, Hashable, Sendable {
    let url: URL
    let size: Int64
    let modifiedAt: Date?
    var id: URL { url }
}

struct DuplicateGroup: Identifiable, Sendable {
    let fingerprint: String
    let files: [DuplicateFile]
    var id: String { fingerprint }
    var size: Int64 { files.first?.size ?? 0 }
    var reclaimableBytes: Int64 { size * Int64(max(0, files.count - 1)) }
}

struct DuplicateAnalysis: Sendable {
    let groups: [DuplicateGroup]
    let scannedFiles: Int
    let scannedBytes: Int64
    var duplicateFiles: Int { groups.reduce(0) { $0 + $1.files.count } }
    var reclaimableBytes: Int64 { groups.reduce(0) { $0 + $1.reclaimableBytes } }
}
