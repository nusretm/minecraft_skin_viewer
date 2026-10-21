# Minecraft Skin Viewer — Current Target

**Repository:** `nusretm/minecraft_skin_viewer`
**Base branch:** `main`
**Active feature:** `feature/r1-renderer-foundation`
**Open PR:** [#1 — R1 Renderer Foundation (Draft)](https://github.com/nusretm/minecraft_skin_viewer/pull/1)
**Current checkpoint:** R1 Windows 3D renderer feasibility — `IMPLEMENTED (PARTIAL) / WINDOWS DEBUG LIVE VERIFIED / LOCAL WIDGET TEST PASS / RELEASE GPU OPT-IN MISSING (BLOCKED)`
**Merge:** NOT APPROVED; do not merge.

## 2026-10-22 — Windows GPU release blocker confirmed by local runner inspection

- **User environment:** Windows, Flutter 3.47.7. Local active branch `feature/r1-renderer-foundation` was fast-forwarded from `bbf6080` to `2a684d0` without overwriting untracked example runner files.
- **PASS — local analyzer:** `flutter analyze --no-pub` in `example/` reported `No issues found!`.
- **PASS — local widget test:** `flutter test --no-pub test/widget_test.dart` reported `+1: All tests passed!` after GPU-free controls separation.
- **PASS — release compilation, FAIL — release rendering:** `flutter build windows --release` successfully produced an EXE, but launching it rendered the shell plus red error `Failed to initialize ShaderLibrary: Flutter GPU must be enabled via the Flutter GPU manifest setting`. This is a **runtime GPU configuration failure**, not a successful release smoke.
- **Confirmed root cause in local generated runner:** `Select-String example/windows/runner/main.cpp 'DartProject project|set_enable_flutter_gpu'` returned only `flutter::DartProject project(L"data");` at line 20; required `project.set_enable_flutter_gpu(true);` was absent. The example Windows runner remains untracked; GitHub CI adds the opt-in to its temporary runner and therefore its green release build does **not** prove the local EXE is properly configured.
- **Next validation:** add `project.set_enable_flutter_gpu(true);` immediately after `flutter::DartProject project(L"data");` in local `example/windows/runner/main.cpp`, rebuild release, launch EXE and verify actual 3D scene, orbit, zoom and overlay. Stage/review local runner sources only after success; avoid committing generated intermediates.
- **Not finished:** actual textured PNG nearest sampling and repeated mount/unmount/lifecycle; PR #1 remains Draft and requires explicit merge approval. This continuity update does not change Flutter source code or local runner.

## 2026-10-22 — Windows release blank screen and GPU-free test correction (R1 still open)

- **User evidence:** root and example `flutter analyze --no-pub` both PASS; initial `flutter test --no-pub test/widget_test.dart` FAIL with `Flutter GPU requires the Impeller rendering backend, but Impeller is not enabled` at `Scene()` initialization. Missing title/control assertions are secondary to the exception. This is a real test failure, not CI proof of GPU support.
- **Windows release:** `flutter build windows --release` produced an EXE; launching it displayed only a blank gray Flutter window (user screenshot). **RELEASE VISUAL SMOKE FAILED** despite successful compile. Local `example/windows/runner/main.cpp` was not provided; missing `project.set_enable_flutter_gpu(true);` is the leading hypothesis, not established fact. The Windows runner is still an untracked local path.
- **R1 fix on feature branch:** defer `Scene()` creation until guarded initialization so an unavailable GPU can yield a visible error instead of failing during widget state construction. Extract GPU-free overlay controls for normal widget testing. Replace the crashing scene test with a controls-only widget test and run it in GitHub Windows CI. Update example run instructions, leaving user-local generated Windows runner untouched.
- **CI evidence:** run [39685992762](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39685992762) on previous R1 HEAD passed Windows static analysis and release compilation; does not establish actual release rendering or headless widget-test support.
- **Next local validation:** confirm/edit `example/windows/runner/main.cpp` using Flutter GPU project opt-in, rebuild and **launch** release EXE; run corrected widget test; inspect generated runner sources before staging. Full R1 PNG nearest sampling and repeated lifecycle testing remain pending. **PR #1 stays Draft; no merge approval.**

## 2026-10-22 — Windows R1 pointer controls verified and generated files inventoried

- **User Windows live feedback:** manual mouse drag rotation, mouse-wheel zoom and head overlay toggle all **PASS** in the Flutter 3.47.7 Windows debug example. The GPU-backed 3D character screenshot was previously observed. This is specifically **debug render/interaction validated**, not release validation or 3D skin/cape texture completion.
- **Local Git status:** `feature/r1-renderer-foundation...origin/feature/r1-renderer-foundation`; no tracked modifications reported; generated untracked paths: `example/.gitignore`, `example/.metadata`, `example/analysis_options.yaml`, `example/pubspec.lock`, `example/test/`, `example/windows/`, `pubspec.lock`.
- **Git ownership:** `example/windows/` contains Windows runner source and should be reviewed and versioned after confirming `project.set_enable_flutter_gpu(true);` for release; example metadata/analysis config/lockfile should be tracked; root library `pubspec.lock` is ignored; avoid deleting or overwriting any existing local generated assets.
- **CI blocker fix implemented on feature branch:** added tracked `example/test/widget_test.dart` testing the R1 widget title and overlay control instead of Flutter-generated stale `MyApp` counter test. **CI result for new test not yet confirmed**; it may expose further analyze/build issues.
- **Local checkout caution:** because user's local `example/test/widget_test.dart` is untracked and remote now contains a tracked replacement, save or rename local test file before fetching/pulling. Never use `git clean -fd` to resolve the conflict.
- **R1 pending:** Windows release executable launch, nearest-filter/PNG smoke, repeated mount/unmount resource checks and CI green. Draft PR #1 is still open and merge unapproved.

## 2026-10-22 — Real Windows debug render observed after user Flutter upgrade

- **Environment:** user upgraded to Flutter **3.47.7 stable** (framework `abaf9c5237`) and Dart **3.13.5**; `flutter pub get` at root and `example/` succeeded; `flutter create . --platforms=windows` reported 0 new files (existing local example).
- **Windows debug observation:** user executed `flutter run -d windows --enable-flutter-gpu`; Flutter built `mtn_minecraft_skin_viewer_example.exe` successfully, logged Impeller OpenGLES backend activation, and rendered the R1 blocky human with visible head overlay in a supplied screenshot. This is **LIVE VISUALLY VERIFIED for initial Windows debug scene**, not proof that all R1 acceptance criteria pass.
- **Not yet observed:** actual manual orbit/zoom interaction, on/off overlay response, nearest-neighbor texture filtering (not yet implemented), 3D atlas UV mapping, repeated mount/unmount leak checks, Windows release compile **and launched release EXE**. No 2D skin/cape widgets have been implemented.
- **Debug termination:** after the render, CLI displayed `Lost connection to device.` followed by interrupted batch handling; could be a normal window close/debug disconnect or a crash. Cause is **UNVERIFIED**; do not claim clean exit or definite crash.
- **flutter_scene depth diagnostic:** 24-bit reversed depth and overlay `Material.depthLayer` notice is informational. Overlay alpha/depth correctness remains to be checked.
- **Git operations:** user attempted `git clone` and `git switch --track`; both refused because local checkout/feature branch already existed, not because of remote access failure. Local working tree/branch and any Flutter-generated changes were not independently inspected.
- **CI evidence:** latest GitHub Actions [39682365628](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39682365628) still **FAILED** at example `flutter analyze` (root `flutter analyze` and Windows example runner generation passed; release build skipped). Earlier [39681032211](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39681032211) identified an undefined `MyApp` in generated `example/test/widget_test.dart`; latest failing step matches this pattern but its exact analyzer log was not independently re-read.
- **This update:** documentation-only factual handoff after user's report; no source, dependency or CI changes, and no PR merge.

## 2026-10-22 — Working rules and continuity aligned with MTN Launcher App (DOCUMENTATION ONLY)

- **Source of standards:** [`mtn_launcher_app/docs/WORKING_RULES.md`](https://github.com/nusretm/mtn_launcher_app/blob/main/docs/WORKING_RULES.md); its `main` did not contain root `AGENTS.md` at review time. Adapted its single integration gate, explicit implementation/merge approvals, Windows evidence, branch cleanup, ownership and continuity-hand-off discipline to this package.
- **Files updated:** root `AGENTS.md`, `docs/WORKING_RULES.md`, this `CURRENT_TARGET.md`. **New future-only plan:** `PLANNED_2026-10-22_SKIN_CAPE_VIEWERS.md`.
- **Scope discipline:** documentation only for this update; no Flutter/source/CI modifications and no Flutter upgrade executed by assistant. User is upgrading their local Flutter SDK.
- **R1 CI evidence discovered:** [Windows run 39681032211](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39681032211) completed **failure**. Root package `flutter analyze`: **PASS**; `flutter create . --platforms=windows`: **PASS**; runner GPU enable step: **PASS**; example `flutter analyze`: **FAIL** at generated `example/test/widget_test.dart:16:35`, which expects undefined `MyApp` (`creation_with_non_type`); release build: **SKIPPED**. Other run attempts 39680994990, 39680991377, 39680937256 also concluded failure.
- **Next code task (not part of this doc-only change):** after Flutter upgrade, reconcile the generated example's default widget test with the actual app entrypoint, then rerun analyze/build. Do not prematurely declare GPU support validated.

## 2026-10-22 — R1 foundation prototype opened in Draft PR #1

- **Approved and implemented (partial):** package `pubspec.yaml` and placeholder public Dart library; `example/pubspec.yaml` with `flutter_scene 0.24.3`; six Classic-proportion cuboids; pointer drag orbit, mouse-wheel zoom, alpha-blended head overlay toggle; Windows GitHub Actions analyze/build workflow.
- **R1 status:** proposed 3D API is *not* public; real skin atlas UV mapping, synthetic pixel texture/nearest-filter verification, final transparency policy, repeated mount/unmount cleanup and 2D previews are **NOT IMPLEMENTED/NOT VALIDATED**.
- **Live Windows status:** neither debug interactive smoke nor launched release executable observed yet. GitHub build success, if obtained later, will still not replace this visual validation.
- **Ownership:** root Flutter package owns future skin/cape data and public widgets; experimental `flutter_scene` dependency remains inside `example/`.
- **Approval:** user authorized starting R1; PR #1 is Draft; merge requires separate explicit user acceptance.

## Current work boundary and next action

1. Flutter 3.47.7 upgrade and initial Windows debug 3D display were confirmed by user; verify local `git status -sb` and active branch before further changes.
2. Fix generated example's stale `MyApp` test reference on the active feature branch only with user-authorized R1 implementation continuation; rerun CI.
3. Verify actual mouse orbit, wheel zoom, overlay toggling, and debug exit behavior; then build and **launch** Windows release EXE.
4. Implement/check a small synthetic PNG nearest-filter and overlay transparency smoke within R1 scope, verify lifecycle, and record results.
5. Complete R1 review and obtain explicit merge approval. R2–R5 remain `PROPOSED / NOT APPROVED FOR IMPLEMENTATION` in `PLANNED_2026-10-22_SKIN_CAPE_VIEWERS.md`.

See `docs/continuity/ARCHITECTURE.md`, `docs/continuity/R1_RENDERER_FOUNDATION.md` and `docs/WORKING_RULES.md` for authoritative boundaries.
