# Zentra Development Workflow

## Branch strategy

- `main` is always kept stable.
- Never develop features directly on `main`.
- Feature branches use `feat/<milestone-or-feature>`.
- Fix branches use `fix/<short-description>`.
- Documentation/chore branches may use `docs/` and `chore/`.

Current branch: `feat/m0-foundation`.

## Local workflow

Clone once:

```bash
mkdir -p ~/Developer
cd ~/Developer
git clone https://github.com/aymentucker/Zentra.git
cd Zentra
```

Switch to the current development branch:

```bash
git fetch origin
git switch feat/m0-foundation
git pull --ff-only origin feat/m0-foundation
```

After an Xcode project exists:

```bash
open Zentra.xcodeproj
```

Before beginning work:

```bash
git status
git pull --ff-only
```

Before committing:

```bash
git status
git diff
```

Use focused commit messages such as:

```text
feat: add localized app shell
feat: add cleanup scanner
fix: preserve RTL sidebar alignment
refactor: extract storage service
test: cover duplicate hashing
docs: update development workflow
```

## Pull requests

Each milestone/feature is reviewed through a PR before reaching `main`. Keep unrelated changes out of the same PR.

## Local testing baseline

For every meaningful change:

1. Build with Xcode.
2. Run the app.
3. Test English/LTR.
4. Test Arabic/RTL when UI is affected.
5. Test light/dark appearance when relevant.
6. Verify destructive operations against disposable test data only.
7. Run automated tests before merging.

Never test cleanup/deletion code first against irreplaceable personal files.
