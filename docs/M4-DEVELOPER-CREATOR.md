# M4 — Developer & Creator Cleaner

M4 adds a dedicated workspace-cleaning experience without treating project/source data as disposable.

## Developer discovery
- Xcode DerivedData (safe), iOS Device Support (review), Archives (protected)
- Dart/Flutter package cache
- npm, pnpm, Yarn caches
- Gradle cache
- CocoaPods download cache
- Homebrew cache
- Docker Desktop data is detected but protected

## Creator discovery
- Adobe cache
- DaVinci Resolve CacheClip
- Final Cut application cache (review)

## Safety
Safe locations are selected after discovery. Review locations require explicit selection. Protected locations cannot be selected. Cleanup uses macOS Trash; Zentra never empties Trash automatically. Project source, Xcode Archives, creator media, Docker volumes/databases and Final Cut libraries are not automatically removed.

## UX
Developer/Creator segmented views, per-location size/file count, safety badges, path visibility, Finder reveal, rescan/cancel, multi-selection, total selected bytes, and confirmation before moving anything to Trash.
