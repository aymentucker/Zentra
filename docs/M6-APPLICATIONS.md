# M6 — Applications

Zentra's Applications module inventories applications in /Applications and ~/Applications, previews exact bundle-identifier leftovers, and uses recoverable Trash operations only.

## Safety model

- System applications, /Applications/Utilities, and Zentra itself are protected.
- A removal always attempts the .app bundle first.
- If macOS denies the application move, Zentra stops. It does not remove caches, preferences, containers, logs, or other leftovers.
- The UI offers Reveal in Finder for the denied app so the user can complete the macOS-authorized removal.
- Selected leftovers are moved to Trash only after the application bundle has been successfully removed.
- Protected items are never offered for removal.
- Zentra never empties Trash.

## macOS permissions

Some applications in /Applications require authorization that an ordinary app process does not have. Some Library/Containers content is separately protected by macOS privacy controls. These are distinct protections. Zentra does not bypass either protection and does not install an unrestricted privileged shell/helper.

A future signed privileged service must authenticate its client and expose only narrowly scoped operations before it can replace the Finder fallback.

## Artifact matching

Artifact discovery uses exact bundle-ID based locations for Application Support, Caches, Preferences, Saved Application State, Logs and Containers. Group Containers require an exact or suffix bundle-ID match. Only previewed artifacts can enter a removal request.
