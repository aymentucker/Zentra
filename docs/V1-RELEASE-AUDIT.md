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

## Verified development baseline

On 2026-09-29 the generated Debug project was verified locally with:

- `BUILD SUCCEEDED`
- 54 unit tests executed
- 0 failures / 0 unexpected failures
- `TEST SUCCEEDED`

This verifies the current development target and test suite only. It does not replace signed Release archive, notarization, privileged-service approval, or clean-Mac distribution testing.

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


## Local build verification after removal-service target

After pulling this branch, regenerate the Xcode project before testing because `project.yml` now contains the `ZentraRemovalService` target:

```bash
rm -rf Zentra.xcodeproj
bash scripts/bootstrap.sh
```

Then verify in this order:

```bash
xcodebuild -project Zentra.xcodeproj -scheme Zentra -configuration Debug build
xcodebuild -project Zentra.xcodeproj -scheme Zentra -configuration Debug test
```

Before any privileged-removal activation, inspect the built app and confirm the service/plist are inside the signed bundle:

```bash
find ~/Library/Developer/Xcode/DerivedData/Zentra-*/Build/Products/Debug/Zentra.app/Contents -maxdepth 3 \
  \( -name 'ZentraRemovalService' -o -name 'com.zentra.app.removal-service.plist' \) -print
codesign --verify --deep --strict --verbose=2 ~/Library/Developer/Xcode/DerivedData/Zentra-*/Build/Products/Debug/Zentra.app
```

The expected security behavior at this stage is still fail-closed: the service is packaged, but it must reject privileged XPC requests until the final client signing requirement is configured.
