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
