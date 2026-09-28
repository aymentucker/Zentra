# M1 — Scanner & Safety Engine

M1 begins with a strictly read-only filesystem scanner.

## Phase 1
- Scan explicit targets only.
- Collect URL, size, directory flag and modification date.
- Skip symbolic links.
- Skip package descendants and hidden files by default.
- Report progress without blocking the UI.
- Support cooperative cancellation.
- Never delete, move or mutate filesystem content.

## Next
1. Add test fixtures and scanner tests.
2. Add disk-volume metadata service.
3. Add scan target policies.
4. Add safety classification: safe / review / protected.
5. Build review UI.
6. Only then design deletion plans and recoverable Trash operations.

No cleanup feature may bypass the safety layer.
