# Minecraft Skin Viewer — Current Target

**Repository:** `nusretm/minecraft_skin_viewer`
**Base branch:** `main`
**Active feature:** `feature/r1-renderer-foundation`
**Open PR:** [#1 — R1 Renderer Foundation (Draft)](https://github.com/nusretm/minecraft_skin_viewer/pull/1)
**Current checkpoint:** R1 Windows 3D renderer feasibility — `IMPLEMENTED (PARTIAL) / WINDOWS DEBUG VISUALLY VERIFIED / CI FAILED / RELEASE NOT RUN`
**Merge:** NOT APPROVED; do not merge.

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
