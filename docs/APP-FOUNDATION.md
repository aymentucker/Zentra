# Reusable macOS App Foundation

Zentra is the first product built on a reusable internal application foundation. Product-specific system-care code must remain separate from reusable app infrastructure.

## Reusable layer

The following concepts should be reusable by future native macOS products:

- App shell and window composition
- LTR/RTL shell placement
- English/Arabic localization architecture
- Language preferences
- Theme/design tokens
- Reusable cards, buttons, selectors and settings rows
- SVG icon loader
- Sidebar/navigation primitives
- Settings architecture
- UserDefaults preference wrappers
- Logging
- Error presentation
- Empty/loading/error states
- About/update/license surfaces when implemented
- Testing conventions

## Product layer

Zentra-specific features remain outside the reusable foundation:

- Cleanup rules
- Disk scanning
- Duplicate detection
- App uninstall logic
- Developer/creator cleanup
- Performance analysis
- Smart Care recommendations

## Goal

Do not copy the entire Zentra repository to start every future app. The long-term structure should extract the reusable layer into a local/private Swift Package, tentatively called `AymanAppKit` (working internal name), consumed by Zentra and future apps.

This prevents bug fixes, RTL improvements, settings changes and reusable UI components from diverging across copied projects.

## Planned package shape

```text
Packages/AppFoundation/
├── Sources/
│   ├── AppShell/
│   ├── DesignSystem/
│   ├── Localization/
│   ├── Navigation/
│   ├── Preferences/
│   ├── Settings/
│   └── UIComponents/
└── Tests/
```

The extraction should happen after M0 stabilizes so the package is based on proven components rather than premature abstractions.
