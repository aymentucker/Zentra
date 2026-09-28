# Local typography assets

Zentra uses:
- **Cairo** for Arabic UI.
- **Inter** for English UI.

Both are licensed under the SIL Open Font License 1.1.

The binary font files are fetched by `scripts/fetch-fonts.sh` and bundled into the application by XcodeGen. The app never downloads fonts at runtime.

Sources:
- Cairo: google/fonts, `ofl/cairo`
- Inter: google/fonts, `ofl/inter`
