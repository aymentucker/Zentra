import Foundation

@objc protocol ZentraRemovalServiceProtocol {
    func removeApplication(
        path: String,
        expectedBundleIdentifier: String?,
        withReply reply: @escaping (Bool, String?) -> Void
    )
}
