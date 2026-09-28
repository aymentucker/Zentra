# M5 — Duplicates + Tidy Up

## Duplicates
The finder first groups regular files by exact byte size, then SHA-256 hashes only same-size candidates. This avoids filename-based false positives and avoids hashing every file. Symlinks and package descendants are skipped. The UI lets the user choose one or more folders, inspect duplicate groups, reveal files in Finder and review selections. Zentra automatically selects redundant copies while retaining one copy in every group. A final guard prevents all members of a group from being removed. Deletion goes to macOS Trash.

## Tidy Up
Tidy Up is intentionally user-directed. It analyzes only the selected folder's top-level files and classifies them into Images, Videos, Audio, Documents, Archives, Installers and Other. It previews every selected item before organization. On confirmation, files are moved into `Zentra Organized/<Category>` inside the chosen folder. Name collisions are resolved by adding a numeric suffix. It never reorganizes nested project folders automatically.
