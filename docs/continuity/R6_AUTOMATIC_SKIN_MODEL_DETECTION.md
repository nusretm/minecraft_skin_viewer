# R6 — Automatic Skin Model Detection

Status: IMPLEMENTED on Draft PR #7; CI and Windows user smoke PENDING.
Date: 2026-10-23
Repository: nusretm/minecraft_skin_viewer
Feature branch: feature/r6-auto-skin-model-detection
Base: main at 23bef1b44d9f62c4d2792ac7ed0f728d742e9efc
PR: https://github.com/nusretm/minecraft_skin_viewer/pull/7
Approval: User explicitly approved source-inspired minimal single-checkpoint adaptation.

## Contract

- MtnMinecraftSkinTexture.fromPng(png) selects a model automatically.
- An explicit modelType: classic/slim always wins; no independent detection on this path.
- 64x32 legacy uses Classic when unspecified; explicit Slim on legacy remains allowed.
- Modern 64x64 uses an adapted bs-community/skinview-utils inferModelType heuristic on original decoded RGBA before base-face alpha normalization.
- Any nonopaque alpha pixel in one of the four unused Slim arm atlas areas yields Slim; all four areas uniformly opaque black, or all uniformly opaque white, also yield Slim; otherwise Classic.
- This is a heuristic, not authoritative account metadata. No unknown/confidence public API is added in this deliberately minimal scope. A user can override incorrectly classified skins.
- 2D/3D renderers, controller and UV layout are unchanged; one decode and one detection at most per fromPng call. No new dependency or online API.
- MIT algorithm source: https://github.com/bs-community/skinview-utils/blob/master/src/process.ts
- MIT notice copied to docs/third_party/SKINVIEW_UTILS_LICENSE.md. The upstream test PNG binaries were not copied.

## Implementation

- lib/src/mtn_minecraft_skin_texture.dart: optional modelType and private detection on original RGBA.
- test/mtn_minecraft_skin_texture_test.dart: focused synthetic Classic, Slim alpha, black/white edge, legacy and manual override tests.
- example/lib/r4d_viewer_gallery.dart: initial skin load uses auto detection; Classic/Slim selector stays manual.
- README.md, CHANGELOG.md, ARCHITECTURE.md and CURRENT_TARGET.md: document behavior and provenance.

## Gates remaining

- GitHub pull-request Windows CI: root flutter analyze/test, example analyze/test, release example build.
- User local: flutter --version; flutter pub get; flutter analyze --no-pub; flutter test --no-pub test/; example analyze, Windows flutter run -d windows --enable-flutter-gpu; release EXE with actual locally owned Classic/Slim PNGs; verify inferred arm geometry and manual override.
- git diff --check, git status and final PR diff review on a checkout with user files preserved.
- Do not claim LIVE_VALIDATED or CLOSED until Windows validation and PR acceptance. No launcher integration, pub.dev release or changes to other repos.
