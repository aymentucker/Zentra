# Zentra V1 Release Audit

## Scan activation contract

File and workspace scans are user initiated. Opening a module must not start a filesystem scan.

- Smart Care: Scan / Scan Again
- Cleanup: Scan for Cleanup
- Storage: Analyze selected locations
- Duplicates: starts only after the user chooses folders
- Tidy Up: starts only after the user chooses a folder
- Applications: Scan Applications / Rescan
- Developer & Creator: Scan Workspace / Rescan
- Performance is the exception: it is a live read-only dashboard, not a file scan. Sampling runs only while the Performance module is selected.

## Localization

SwiftUI text follows the selected in-app locale. Foundation/model formatting must use `ZentraLocalization` so formatted strings and byte values do not silently fall back to the macOS system language.

## Packaging baseline

- macOS 14+
- Bundle ID: `com.zentra.app`
- Marketing version: 1.0.0
- Build: 1
- Hardened Runtime: enabled
- App Sandbox: disabled
- Category: Utilities
- Automatic code signing during development

Distribution still requires a valid Developer ID / App Store signing choice, archive validation, notarization where applicable, and testing the signed artifact on a clean Mac.

## Application uninstall blocker

The current uninstaller intentionally stops if macOS denies moving an app bundle from `/Applications`. It never continues by deleting leftovers after the main bundle fails.

Finder reveal is a safe fallback, but it is not considered the final V1 uninstall experience.

A future privileged removal component must not be a generic root file service. Before it can ship it must:

1. authenticate that requests originate from the signed Zentra application;
2. accept only a narrowly defined application-removal request;
3. canonicalize and validate the target as an eligible `.app` bundle under an approved Applications directory;
4. reject system/protected applications and arbitrary paths;
5. provide no shell-command or arbitrary file-operation interface;
6. perform an authorization flow visible to the user;
7. preserve recoverability and verify the result;
8. remove selected leftovers only after the app bundle operation succeeds;
9. be code signed and tested as part of the release artifact.

Until those requirements are implemented and tested end-to-end, direct privileged uninstall remains a V1 release blocker.
