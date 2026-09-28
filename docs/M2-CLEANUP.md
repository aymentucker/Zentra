# M2 — Cleanup

M2 turns the M1 scanner/safety foundation into a user-facing cleanup workflow.

## Flow
Cleanup source catalog → source size analysis → selected-source scan → classification → safety dashboard → bounded review preview → full safe selection → cleanup plan → explicit confirmation → recoverable macOS Trash move → verification.

## Sources
- User caches
- Application logs
- Developer caches: Xcode DerivedData, Gradle caches, Dart pub cache
- Creator caches: known Adobe and DaVinci cache locations

Only existing locations are scanned.

## Safety
- Personal user content is protected.
- Xcode Archives are not treated as disposable developer cache.
- Creator source media/projects are not treated as cache.
- Recent caches/logs require review.
- Only safe results become CleanupCandidate values.
- Review/protected results cannot enter a candidate-based cleanup plan.
- Execution uses macOS Trash and never empties Trash automatically.

## Performance
- Progress updates are throttled.
- Direct file targets count correctly.
- Review UI retains only the largest 30 preview items per category.
- All safe results remain selectable through compact CleanupCandidate values.
- ScanReviewBuilder is independently testable.

## Validation
Run locally: ./scripts/bootstrap.sh, then Build (Command-B), Unit Tests (Command-U), and Run (Command-R).

GitHub changes alone do not constitute local macOS validation.
