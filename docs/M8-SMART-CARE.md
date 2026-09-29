# M8 — Smart Care

Smart Care is Zentra's fast, read-only overview. It coordinates existing engines rather than creating a second cleanup implementation.

## Scan stages

1. Cleanup safety scan.
2. Lightweight storage-capacity snapshot of the Data volume.
3. Developer and Creator workspace analysis.
4. Installed applications inventory.
5. CPU, memory, uptime, process and startup-service snapshot.

Duplicate hashing and Tidy Up are intentionally excluded because they are deeper workflows and should remain explicit user actions.

## Status

Zentra does not present a synthetic “health score”. Smart Care reports a descriptive status:

- Ready: no review items and no high resource/storage signal.
- Review recommended: review items exist, disk usage is at least 85%, or sampled CPU is at least 85%.
- Attention needed: disk usage is at least 95% or sampled memory pressure is at least 90%.

This is a product heuristic for prioritizing review, not a diagnosis of macOS health.

## Safety

Smart Care is analysis-only. It never deletes automatically. Safe/review/protected totals preserve the scanner and workspace safety policies. Destructive actions remain in their dedicated modules with review and confirmation.

## Storage

Smart Care reads volume capacity only; it does not perform the full Storage Analyzer traversal. This keeps the integrated scan fast. Detailed storage mapping remains in Storage.
