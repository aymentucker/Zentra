# Zentra Architecture

Zentra is a native macOS application built with Swift and SwiftUI.

## Target structure

```text
Zentra/
├── App/
├── Core/
│   ├── FileSystem/
│   ├── Scanner/
│   ├── Cleaning/
│   ├── Permissions/
│   ├── Database/
│   └── Logging/
├── DesignSystem/
│   ├── Colors/
│   ├── Typography/
│   ├── Components/
│   ├── Icons/
│   └── Motion/
├── Features/
│   ├── SmartCare/
│   ├── Cleanup/
│   ├── Storage/
│   ├── Duplicates/
│   ├── TidyUp/
│   ├── Applications/
│   ├── Performance/
│   ├── Startup/
│   ├── Developer/
│   ├── Privacy/
│   └── Settings/
├── Models/
├── Services/
├── Localization/
└── Resources/
```

Folders are introduced when implementation requires them; empty placeholder folders are not committed.

## Engineering rules

### Safety
Scanning and deletion are separate operations. A scanner produces findings; it does not delete data. Destructive operations require explicit plans and safety classification.

### Feature boundaries
Features own their views, view models, feature-specific models, and feature-specific services. Shared system functionality belongs in Core or Services.

### Localization
User-facing strings must be localizable. English and Arabic are first-class languages. Layout must support both LTR and RTL rather than merely translating text.

### Design
Zentra uses its own design system and custom visual identity. Reference products may inform usability, but implementation and branding remain original.

### Platform
Prefer native Apple frameworks over unnecessary third-party dependencies. Dependencies require a concrete technical justification.

## Initial milestones

- M0: Foundation, app shell, design system, localization, navigation
- M1: Scanner and safety engine
- M2: Cleanup
- M3: Storage intelligence
- M4: Developer and creator cleanup
- M5: Duplicates and Tidy Up
- M6: Applications
- M7: Performance
- M8: Smart Care integration
