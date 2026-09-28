# M3 — Storage Analyzer

M3 adds a read-only storage analysis workflow for personal folders.

## Scope
- Analyze Desktop, Documents, Downloads, Movies, Music and Pictures.
- Categorize documents, images, video, audio, archives, applications, developer files and other data.
- Show analyzed bytes, file count and files >= 100 MB.
- Filter large files by category and adjustable size threshold.
- Reveal a result in Finder.
- No automatic deletion from Storage Analyzer.

## Safety
Storage is intentionally inspection-first. Personal files are not classified as cleanup-safe and this module does not delete them. A future explicit removal action must go through review/confirmation and Trash semantics.

## Performance
Enumeration skips symlinks, hidden files and package descendants. Progress updates are throttled. The large-file UI displays at most 200 rows at once while the analysis remains available for filtering.

## Validation
Run ./scripts/bootstrap.sh, then Build (Command-B), Unit Tests (Command-U), and Run (Command-R). GitHub changes alone are not local macOS validation.
