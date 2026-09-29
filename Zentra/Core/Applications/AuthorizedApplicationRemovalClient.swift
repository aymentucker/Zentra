import Foundation

enum AuthorizedRemovalClientError: LocalizedError {
    case serviceUnavailable
    case invalidRequest
    case rejected(String)

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return ZentraLocalization.string("applications.authorization.serviceUnavailable")
        case .invalidRequest:
            return ZentraLocalization.string("applications.authorization.invalidRequest")
        case .rejected(let code):
            return code
        }
    }
}

@objc protocol ZentraRemovalServiceXPCProtocol {
    func removeApplication(
        path: String,
        expectedBundleIdentifier: String?,
        withReply reply: @escaping (Bool, String?) -> Void
    )
}

actor AuthorizedApplicationRemovalClient {
    static let machServiceName = "com.zentra.app.removal-service"

    func remove(_ application: InstalledApplication) async throws {
        guard let request = AuthorizedApplicationRemovalPolicy.makeRequest(for: application) else {
            throw AuthorizedRemovalClientError.invalidRequest
        }

        let connection = NSXPCConnection(
            machServiceName: Self.machServiceName,
            options: .privileged
        )
        connection.remoteObjectInterface = NSXPCInterface(with: ZentraRemovalServiceXPCProtocol.self)
        connection.resume()

        defer {
            connection.invalidate()
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let object = connection.remoteObjectProxyWithErrorHandler { _ in
                continuation.resume(throwing: AuthorizedRemovalClientError.serviceUnavailable)
            }

            guard let proxy = object as? ZentraRemovalServiceXPCProtocol else {
                continuation.resume(throwing: AuthorizedRemovalClientError.serviceUnavailable)
                return
            }

            proxy.removeApplication(
                path: request.canonicalApplicationPath,
                expectedBundleIdentifier: request.expectedBundleIdentifier
            ) { success, code in
                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(
                        throwing: AuthorizedRemovalClientError.rejected(
                            code ?? "removal_rejected"
                        )
                    )
                }
            }
        }
    }
}
