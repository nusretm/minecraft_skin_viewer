# R6 — Automatic Skin Model Detection

Status: CLOSED / squash-merged PR #7 to main as 3b2c7b442681c086c9ef98b90e5d30b6b69922ca; Windows debug smoke accepted. Interactive release EXE smoke not separately reported.
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

## Verification and merge closure (2026-10-23)

- Final R6 feature HEAD `be23568381dc20133fc5d00887b9681f8fd7cd2e`: GitHub Windows PR workflows all **SUCCESS**: R1 #39956090260, R2 #39956090183, R3 #39956090254, R4 #39956090299. These cover root/example analyzers, tests and Windows release build.
- User Windows: `flutter pub get` PASS; root `flutter analyze --no-pub` PASS (20.0s); root `flutter test --no-pub test/` **56/56 PASS**; example dependency resolution and `flutter analyze --no-pub` PASS (2.0s); `flutter run -d windows --enable-flutter-gpu` built debug EXE in 15.2s and launched with Impeller. User reported **"süper çalıştı"** for real UI/model detection. The log ended with `Lost connection to device`; not independently demonstrated to be a crash.
- Review: PR #7 contained exactly nine scoped files, no added-line trailing whitespace in reviewed GitHub patch; local `git diff --check` **NOT RUN** here. User worktree had four modified generated/dependency-lock files, preserved and excluded.
- User explicitly authorized **merge and cleanup**. PR #7 was marked ready, then **squash-merged** into `main` as `3b2c7b442681c086c9ef98b90e5d30b6b69922ca`. R6 is **CLOSED** on user acceptance and Windows debug evidence.
- **Deferred / unverified:** Windows release **build** passed in CI, but interactive release EXE **launch** and manual Classic/Slim override with separately documented cases were not supplied as independent evidence. No release live-validation claim and no zero-GPU-leak claim. These are not hidden regressions; check later if needed.
- No new dependencies, account/network API, launcher integration, pub.dev release or SDK upgrade in R6.
