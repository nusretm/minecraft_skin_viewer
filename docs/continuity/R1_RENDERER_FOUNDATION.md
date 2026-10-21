# R1 — Renderer Foundation (Windows)

Status: **CLOSED / SQUASH-MERGED IN PR #1 / WINDOWS DEBUG+RELEASE FUNCTIONALLY VALIDATED / MEMORY SOAK DEFERRED**. Approval was given in the conversation to start the first checkpoint; repository created and GitHub access granted on 2026-10-22.

## Goal

Establish whether `flutter_scene` can correctly render a simple Minecraft-shaped character on Windows in both debug and packaged release. Keep this as a feasibility prototype, not an irreversible production dependency.

## Implementation scope

- Initialize root Flutter package named `mtn_minecraft_skin_viewer`, with small `example/` Flutter app. Keep `flutter_scene` inside example unless concrete R1 needs prove otherwise.
- Verify Windows Flutter toolchain version first; require Flutter 3.47.1+ for desktop release GPU opt-in. Do **not** auto-upgrade the user's Flutter install.
- Add `flutter_scene` (currently 0.24.3; confirm before pinning), run `dart run flutter_scene:init` from the **example app root** for generated assets/hooks if the selected package version requires it.
- Initialize `Scene.initializeStaticResources()` before scene resource usage.
- Draw six character segments: head, torso, both arms, both legs, proportionally matching Classic Steve proportions at the prototype level (no full UV/skin atlas yet).
- Test mouse drag to orbit and mouse wheel zoom with sane limits and stable camera target.
- Test a small synthetic pixel-art texture with nearest-neighbor sampling. Record whether filtering can be configured without postprocessing.
- Test alpha transparency on a simple slightly larger outer-layer cube; record sorting/occlusion and performance issues.
- Dispose widget-owned scene resources and verify repeated mount/unmount does not crash or leak.
- Enable Flutter GPU in `example/windows/runner/main.cpp` on Flutter 3.47.1+: after `flutter::DartProject project(L"data");`, set `project.set_enable_flutter_gpu(true);`.

## Non-goals

- No full Minecraft UV atlas, production Classic/Slim model detection, cape cloth/physics, animators, Microsoft/Mojang/Ely.by API calls, persistent caching or launcher integration.
- Do not promise web/mobile support without testing.
- Do not introduce Rust or a generic provider/registry.

## Validation / exit criteria

1. `flutter --version`, `flutter doctor -v` recorded (secrets/private paths redacted).
2. `flutter pub get`, `flutter analyze`, `flutter test` execute without R1 errors.
3. Windows debug: launch actual example and observe 3D character, orbit, wheel zoom, texture and overlay.
4. Windows release: build, **launch executable directly** and observe actual rendering (compile alone is insufficient).
5. Mount/unmount repeats; no disposal exceptions or apparent resource accumulation.
6. `git diff --check`, `git status -sb` and diff review.
7. Update `CURRENT_TARGET.md` with exact completed work, versions, test outcomes, remaining risks, branch and commit.
8. Open draft PR for review; **do not merge without explicit user approval**.

If GPU features are not feasible or toolchain too old, document precise failure and stop rather than inserting a fake 3D placeholder.

## External references verified at planning

- https://pub.dev/packages/flutter_scene/versions/0.24.3
- https://github.com/bdero/flutter_scene/blob/master/packages/flutter_scene/README.md
- https://github.com/bdero/flutter_scene/blob/master/AGENTS.md
- https://github.com/flutter/flutter/issues/190871

## Checkpoint progress (2026-10-22)

- Added root Flutter package metadata and R1-only `flutter_scene` example app on feature branch.
- Procedural Classic-sized six-part model, mouse drag orbit, wheel zoom, and alpha-blended head shell toggle implemented.
- Added Windows CI static analysis and release compile workflow; current result has not yet been evaluated.
- Still pending: real texture/nearest filtering test, local Windows debug/release GPU smoke, repeated mount/unmount validation, evidence in continuity and user acceptance.
- Do not consider R1 complete or approved for merge.

## Windows validation update — 2026-10-22

- **PASS (user, real Windows):** Flutter 3.47.7 debug app renders 3D character; mouse orbit/zoom and head overlay toggle work.
- **PASS (user, real Windows):** Flutter release EXE rebuilt in 8.2 seconds and **launched successfully**, screenshot shows full Flutter UI and 3D model; user says all controls work again. Previous release blank/error screen was caused by missing Flutter GPU project opt-in in the local Windows runner. Local fix worked, but the generated runner source still needs to be committed to the feature branch.
- **PASS (user, local):** `flutter analyze --no-pub` for root and example; GPU-free `flutter test --no-pub test/widget_test.dart` passed.
- **NOT DONE:** synthetic pixel texture nearest filtering feasibility proof, lifecycle mount/unmount soak, complete acceptance/merge. Latest R1 CI run should be checked after source synchronization.
- **Merge:** Draft PR #1 remains open and **not approved for merge**.

## R1 texture + lifecycle final smoke addition (2026-10-22)

- **IMPLEMENTED ON FEATURE / WINDOWS NOT RUN:** `example/lib/main.dart` generates an 8x8 yellow/purple checker PNG and uploads it with `Texture2D.fromEncodedBytes`; nearest min/mag filters with mipmaps disabled. The head `CuboidGeometry` receives the texture via `UnlitMaterial.baseColorTexture`.
- **IMPLEMENTED ON FEATURE / WINDOWS NOT RUN:** `Recreate viewer` removes the current viewer for one frame and remounts a new one, offering a manual scene lifecycle stress test. Use 10–20 cycles and check visually and through process memory; do not infer a lack of leaks from the button existing.
- **NO R2 WORK:** real skin atlases, per-face Minecraft UVs, Classic/Slim texture mapping, capes, 2D public widgets all remain future checkpoints.
- **Pending acceptance:** clean CI + real Windows debug/release texture and lifecycle smoke results, plus separate merge approval.

## 2026-10-22 — PNG/nearest & recreate Windows verification

- **Windows debug PASS:** Flutter 3.47.7, interactive 3D viewer with sharp synthetic 8x8 checker PNG on head; screenshot and user `herşey çalışıyor` confirmation.
- **Windows release PASS:** `flutter build windows --release` (24.7s); direct EXE launch shows the same textured head in a screenshot.
- **Local analysis PASS:** `flutter analyze --no-pub` clean; focused GPU-independent widget test 1/1 passed.
- **GitHub CI PASS:** exact feature code `4424597`, runs `39689222086` and `39689226713`, root/example analyze, widget test and Windows release build succeeded.
- **Lifecycle note:** user reports Recreate viewer working, but explicit repeat count and GPU memory measurement are absent; no zero-leak claim. A brief measured soak could strengthen acceptance before merge, or be tracked as explicit deferred risk with user agreement.
- **Scope / merge:** R1 functional GPU and synthetic texture feasibility verified. Real Minecraft UVs and 2D widgets belong to later milestones. PR #1 remains Draft; separate merge authorization required.

## R1 closure — 2026-10-22

- User explicitly approved squash merge of PR #1; GitHub merged as `530dd4a757b29a162d932bd658d269a7d35f5e23`, verified as `main` HEAD at merge time.
- Windows debug and release GUI, orbit/zoom/overlay, synthetic 8x8 PNG nearest sampling and basic Recreate viewer control verified by user. Local analyzer and focused widget test passed; CI passed for functional code.
- The R1 **feasibility checkpoint** is CLOSED. This does not claim production-grade Minecraft UVs or memory leak absence. Controlled GPU-resource/memory soak was not performed and remains a tracked deferred risk.
- R2/R3/R4/R5 implementation is not authorized by the R1 merge. Continue with design and explicit approval for the next checkpoint.
