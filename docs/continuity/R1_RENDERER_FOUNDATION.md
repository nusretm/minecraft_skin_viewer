# R1 — Renderer Foundation (Windows)

Status: **APPROVED / PARTIALLY IMPLEMENTED / NOT YET VALIDATED**. Approval was given in the conversation to start the first checkpoint; repository created and GitHub access granted on 2026-10-22.

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
