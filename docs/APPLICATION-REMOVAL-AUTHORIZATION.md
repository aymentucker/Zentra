# Application Removal Authorization Design

Status: **V1 release blocker until implemented and tested in a signed build.**

Zentra already has a safe unprivileged removal path. This document defines the boundary for the privileged path required when macOS denies modifying an eligible application in `/Applications`.

## Trust boundary

The privileged component must expose one operation only: request removal of one validated application bundle.

It must not expose shell execution, arbitrary move/delete APIs, wildcard paths, recursive root access, or caller-supplied destination paths.

## Request validation

Before a privileged operation, the service must independently:

- resolve symlinks and standardize the requested URL;
- require a `.app` bundle;
- require the canonical parent to be an approved Applications directory;
- reject `/System`, Apple/system applications, Zentra itself, symlinks escaping the approved root, and non-bundle targets;
- verify the connecting client is the expected signed Zentra application using the platform-supported XPC/audit-token/code-signing validation available to the chosen deployment mechanism;
- require an explicit user authorization flow.

Validation must live in the privileged component, not only in the UI process.

## Transaction order

1. User scans Applications explicitly.
2. User opens an app and reviews its related artifacts.
3. User confirms uninstall.
4. Zentra first tries the ordinary recoverable Trash path.
5. If macOS reports a permission failure for the app bundle, Zentra may request the narrowly scoped authorized operation.
6. Only after the app bundle operation is verified successful may the normal app process remove the user's selected leftovers.
7. Failures are surfaced without pretending uninstall succeeded.
8. Zentra never empties Trash automatically.

## Packaging gate

Do not ship the privileged path until the final distribution identity, helper installation mechanism, authorization model, XPC/client validation, hardened runtime settings, signing, notarization, upgrade behavior, uninstall behavior, and clean-Mac tests are verified together.

## Selected platform mechanism

Zentra targets macOS 14+, so V1 will use the modern ServiceManagement model: an app-bundled LaunchDaemon registered with `SMAppService.daemon(plistName:)`. The daemon plist belongs under `Contents/Library/LaunchDaemons`, uses `BundleProgram`, and points to a helper executable kept inside the Zentra app bundle.

Do not use the deprecated `SMJobBless` path for the V1 implementation.

Registration/authorization is explicit and user visible. Zentra must expose service status and must not silently retry authorization in a loop.

The privileged daemon remains a narrow broker for validated application-bundle removal; all trust-boundary requirements above still apply.


## Current implementation status

The repository now contains a hardened `ZentraRemovalService` tool target, an embedded LaunchDaemon plist, a Mach service declaration, a deliberately narrow XPC protocol, and daemon-side path/bundle validation.

The listener currently **fails closed** and rejects every XPC connection. Privileged filesystem mutation is also intentionally disabled. This is deliberate: the service must not become active until the release signing identity is known and the daemon can enforce a concrete Zentra client code-signing requirement.

For macOS 14+, the intended connection validation is an `NSXPCConnection` code-signing requirement before accepting privileged requests. The requirement must be derived from the final signed Zentra release identity and verified on a clean Mac. Do not weaken this to PID/name/path-only validation.

### Remaining activation gate

1. configure final Developer ID signing identity/team;
2. encode the expected Zentra client signing requirement;
3. enforce that requirement on incoming XPC connections;
4. implement the validated app-bundle move operation without exposing a generic file API;
5. wire the app-side XPC client only after `SMAppService` reports enabled;
6. test approval, denial, upgrade, unregister, notarization, and clean-Mac behavior;
7. only then remove the Finder fallback as the normal permission-denied path.
