import Foundation
import CryptoKit

actor DuplicateFinder {
    typealias Progress = @Sendable (Int, Int64, URL?) async -> Void

    func find(roots: [URL], minimumSize: Int64 = 1_048_576, progress: Progress? = nil) async throws -> DuplicateAnalysis {
        let fm = FileManager.default
        let keys: Set<URLResourceKey> = [.isRegularFileKey,.isSymbolicLinkKey,.fileSizeKey,.contentModificationDateKey]
        var bySize: [Int64:[DuplicateFile]] = [:]
        var scanned = 0; var bytes: Int64 = 0
        for root in StorageTargetPolicy().normalized(roots) where fm.fileExists(atPath:root.path) {
            guard let e=fm.enumerator(at:root,includingPropertiesForKeys:Array(keys),options:[.skipsPackageDescendants],errorHandler:{_,_ in true}) else{continue}
            for case let url as URL in e {
                try Task.checkCancellation()
                guard let v=try? url.resourceValues(forKeys:keys),v.isRegularFile==true,v.isSymbolicLink != true else{continue}
                let size=Int64(v.fileSize ?? 0); scanned += 1; bytes += size
                if size >= minimumSize { bySize[size,default:[]].append(.init(url:url.standardizedFileURL,size:size,modifiedAt:v.contentModificationDate)) }
                if scanned % 300 == 0 { await progress?(scanned,bytes,url); await Task.yield() }
            }
        }
        var groups:[DuplicateGroup]=[]
        for (_, candidates) in bySize where candidates.count > 1 {
            var byHash:[String:[DuplicateFile]] = [:]
            for file in candidates {
                try Task.checkCancellation()
                let fingerprint = try hash(file.url)\n                byHash[fingerprint, default: []].append(file)
            }
            groups += byHash.compactMap { hash, files in files.count > 1 ? DuplicateGroup(fingerprint:hash,files:files.sorted{$0.url.path<$1.url.path}) : nil }
        }
        await progress?(scanned,bytes,nil)
        return .init(groups:groups.sorted{$0.reclaimableBytes>$1.reclaimableBytes},scannedFiles:scanned,scannedBytes:bytes)
    }

    private func hash(_ url: URL) throws -> String {
        let handle=try FileHandle(forReadingFrom:url); defer{try? handle.close()}
        var digest=SHA256()
        while autoreleasepool(invoking:{ () -> Bool in
            let data=try? handle.read(upToCount:1_048_576)
            guard let data, !data.isEmpty else{return false}
            digest.update(data:data); return true
        }) {}
        return digest.finalize().map{String(format:"%02x",$0)}.joined()
    }
}
