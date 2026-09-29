import Foundation

private let machServiceName = "com.zentra.app.removal-service"

final class RemovalService: NSObject, ZentraRemovalServiceProtocol {
    func removeApplication(
        path: String,
        expectedBundleIdentifier: String?,
        withReply reply: @escaping (Bool, String?) -> Void
    ) {
        // The daemon revalidates every request. The UI process is never trusted
        // as the authority for filesystem scope.
        let url = URL(fileURLWithPath: path)
        guard RemovalServicePolicy.validate(url: url, expectedBundleIdentifier: expectedBundleIdentifier) else {
            reply(false, "invalid_request")
            return
        }

        // V1 security gate: privileged mutation remains disabled until the
        // signed XPC client identity requirement is configured and verified.
        reply(false, "authorization_not_configured")
    }
}

final class ListenerDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        // IMPORTANT: Do not accept the connection until a release signing
        // requirement has been configured for the Zentra client.
        return false
    }
}

let listener = NSXPCListener(machServiceName: machServiceName)
let delegate = ListenerDelegate()
listener.delegate = delegate
listener.resume()
RunLoop.current.run()
