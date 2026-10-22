# Minecraft Skin Viewer — Current Target

**Repository:** `nusretm/minecraft_skin_viewer`
**Base branch:** `main`
**Active implementation:** R4-A verified; R4-B depth correction Windows DEBUG accepted but post-patch release smoke pending; R4-C implemented on feature and awaiting CI/Windows live checks. R4-D not started.
**Merged PRs:** [#1 — R1](https://github.com/nusretm/minecraft_skin_viewer/pull/1), [#2 — R2](https://github.com/nusretm/minecraft_skin_viewer/pull/2), [#3 — R3 2D Previews](https://github.com/nusretm/minecraft_skin_viewer/pull/3)
**R1 squash commit:** `530dd4a757b29a162d932bd658d269a7d35f5e23`
**Current checkpoint:** R4-C — USER WINDOWS 41/41 ROOT TESTS, DEBUG+RELEASE EXECUTED ON 7ba661e; CAPE HORIZONTAL MIRROR + ALPHA COMPOSITING FIX IMPLEMENTED, CURRENT CI AND WINDOWS LIVE RECHECK PENDING / DRAFT PR #4 / NOT MERGED. R4-D not started.

## 2026-10-22 — Intermediate CI failure during horizontal cape UV change

- In intermediate code-only commit `032e6c74`, the cape mesh's outward face U values were mirrored but its two existing UV tests still asserted the pre-mirror corner order. Windows R4 [39745878385](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39745878385) failed at root tests (**39 passed, 2 failed**); downstream example resolve/analyze/regression/release steps were SKIPPED. Corresponding R2/R3 workflows likewise saw those outdated tests.
- Follow-up commit `4ab9c784` updated both expectations and added an explicit horizontal-U-only regression case. Windows R4 [39746006746](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39746006746) then showed root analyze and root test PASS, example analyze PASS, with later steps still in progress when reviewed. Do not misattribute any intermediate failure to a current-head passing run; final CI on `841337d7` or newer is still pending.

## 2026-10-22 — R4-C cape horizontal mirror and independent outer-layer draw order

- **User Windows verification for 7ba661e:** root `flutter analyze --no-pub` PASS (13.3s); root `flutter test --no-pub test/` **41/41 PASS**; example analyzer PASS (5.8s); GPU debug Windows built (8.6s) and visually inspected; release Windows built (36.5s) and executable launched. No `surface overlap ... will flicker` warning in this session; informational 24-bit depth messages and normal window-close `Lost connection to device` remain.
- **Two new issues found in user screenshots:** Local decorated cape external UV shows white `1` **horizontally mirrored** despite the prior front/back atlas-face swap. Separately, enabling `Outer layers` alters cape's visible composition. The visibility toggle in source only touches six skin outer nodes; separate cape pivot and texture are not directly modified. Rendering order was cape at 0 vs translucent skin shells at 1, so skin shells can blend *over* cape.
- **New targeted code changes, awaiting Windows live verification:** `MtnMinecraftCapeBoxMesh.build` keeps external atlas source `front` mapped to physical rear (-Z) but swaps U corners 0↔1 and 2↔3 for that outward face only; V, physical mesh, inward face, thin edge UVs, hinge and pose remain unchanged. Added UV tests ensuring rear is horizontally mirrored in the intended direction and all other face UVs remain untouched. In the example-only GPU adapter, set cape fabric `Node.renderOrder=2` after translucent skin shells `renderOrder=1`, while the opaque body remains depth-tested; cape now composites independently of `Outer layers` alpha shells. This visual priority can change shoulder overlap and must be inspected in GPU screenshots.
- **Acceptance gate:** Current HEAD CI, root+example analyzers/tests, Windows debug and release launches; compare same orbit/camera view with `Outer layers` off/on while cape stays enabled, check the white `1` orientation against uploaded reference and confirm no limb/shoulder clipping or z-fighting. Keep PR #4 Draft, do not merge and do not start R4-D.

## 2026-10-22 — Intermediate CI failure after cape UV code change

- Early functional source 4f40a8e and example-path source 7cb2833 updated mesh UVs without yet updating the previous cape UV test expectation. Windows R4 workflow [39744017453](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39744017453) failed at `Test root R1-R4A`: 39 passed / 1 failed in `test/mtn_minecraft_skin_pose_cape_test.dart` (expected 0.1875, actual 0.015625), so downstream example/release steps were skipped in that workflow. Windows R2 workflow [39744074694](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39744074694) also failed at `Test R2 skin/cape texture and UV models` for that same outdated expectation.
- Follow-up test commit b10ce01d updated the R4-C assertion for the intended rear world-face / decorated atlas-face swap and added explicit inner-versus-outer UV regression coverage. Current-head CI on docs commit e07ac804 must pass before acceptance; **the intermediate failures are not passing evidence, nor are they necessarily current-head failures.**

## 2026-10-22 — R4-C overlap resolved, cape exterior UV correction and local default

- User tested feature HEAD 36b054d on Windows: root analyzer NO ISSUES (17.4s), root tests 40/40 PASS (15s), example analyzer NO ISSUES (69.2s), Flutter GPU debug build/launched (24.5s). The previous single `body/outer` vs `rightLeg/outer` coplanar-overlap warning is absent; only informational 24-bit depth messages remain. `Lost connection to device` after window close is the user's confirmed normal termination. A post-36b054d local release build/launch was not included in this log; do not claim otherwise.
- User supplied side/rear screenshots and Minecraft cape reference screenshot plus actual `cape.png`: **decorative face with white number 1 must be visible on the outside/back of the character**, but the GPU mesh showed the inner/rainbow face outside. This is a verified cape UV face-orientation defect despite green tests.
- Fix `4f40a8e`: in `MtnMinecraftCapeBoxMesh.build()`, swap the **source atlas** front/back face for mesh geometry back(-Z) and front(+Z), retaining R2 atlas mapping, winding, physical mesh, hinge and side/top/bottom faces. The R2 cape atlas `front` region holds the decorative outward surface, R2 `back` the inside. Do NOT rotate the cape node; its pose/pivot motion must remain unchanged.
- User's requested default cape path is `D:\development\cross-platform\cape.png`, alongside existing skin default. Example init pre-fills cape path, validates and auto-loads it when present, with synthetic cape fallback if absent/unreadable/invalid. No user PNG binary was committed.
- `test/mtn_minecraft_skin_pose_cape_test.dart` updated to verify all six face UV corners and explicit -Z outer decorated / +Z inner UV correspondence; old test that assumed face names matched geometrical outward/inner orientation was corrected.
- Windows release and actual debug/release visual recheck of changed cape UV, its left-right orientation, idle/walk motion, and latest CI pending. Draft PR #4 remains unmerged; R4-D not started until R4-C accepted.

## 2026-10-22 — R4-C Windows test and remaining torso/right-leg overlap

- User fast-forwarded local feature to 1537f5d. Root analyze no issues (11.8s), root tests 40/40 PASS, example analyze no issues (5.9s), example widget test 1/1 PASS, Windows debug GPU scene launched (9.1s), release build PASS (24.8s) and release EXE launched.
- Screenshot demonstrates default Slim skin automatically loaded, cape visually present and Walk selected; outer/cape enabled. The still image does not separately prove dynamic motion, correct every cape UV side or continuous animation behavior.
- Debug showed one real coplanar warning (root/body/body/outer vs root/rightLeg/rightLeg/outer, largest 0.01 m2). This was introduced/exposed by R4-C pivots despite 40 passing tests. Do not claim all visual checks passed while warning persists.
- Targeted source patch 44d219d: material priority becomes base=0, head/body outer=1, both arms and left leg outer=2, right leg outer=3. This separates the remaining overlapping right-leg/torso materials without changing UVs, geometry, textures, pose calculations, cape hinge or lifecycle.
- Patch CI and user Windows GPU warning/log review NOT yet complete. Until verified, keep R4-C open, PR #4 Draft and R4-D unstarted. User has explained Lost connection to device is their normal window-close behavior, not a crash.
- Next: Windows CI results for latest feature HEAD; user debug/release recheck for absence of surface-overlap warning, and orbit/Idle-Walk/Classic-Slim/cape controls.

## 2026-10-22 — R4-B depth fix accepted in debug; R4-C code and local test skin default

- User ran R4-B source f0da7fc: root analyzer PASS (10.6s), root suite 36/36 PASS, example analyzer PASS (6.0s), Windows debug/Impeller launched. Prior repeating 6 surface overlaps warning is absent after the Material.depthLayer patch. All R1/R2/R3/R4 Windows CI workflows for f0da7fc completed SUCCESS. A post-patch local Windows release EXE smoke was NOT included in latest evidence; keep it open.
- User explicitly explains Lost connection to device is normal when they close the application window, not a crash; using CLI q exits without that line. Treat this as expected in their Windows test workflow, superseding older uncertainty.
- User supplied their default Windows test skin: D:\development\cross-platform\9fede215f7cb6884.png. Example's 3D gallery pre-fills and auto-loads the path on startup if a valid PNG exists, selecting Slim explicitly. When unavailable or invalid it uses the generated UV atlas. Only the path is in source; PNG data NOT committed.
- R4-C renderer-independent geometry now implemented on approved feature: MtnMinecraftCapeBoxMesh for all six faces of R2 Java 64x32 cape, 10x16x1 dimensions, 24 vertices / 36 outward triangles; MtnMinecraftSkinPivot and MtnMinecraftSkinPoseFrame.at(idle/walk) for shoulder/hip/cape hinge and limb counter-swing. New tests cover UV, geometry winding, physical size, pivot positions, pose symmetry/limits.
- Example R4-C GPU gallery: parent Node pivots for six parts, separate straight-alpha cape texture with generated cape fallback or optional local cape PNG, visibility toggles for outer layer and cape, idle/walk selection and Ticker-driven motion. Existing orbit, zoom and model switch remain. R4-D production widget/controller, 20-cycle GPU memory soak and other-repo work not started.
- Validation state: Latest R4-C source not yet Windows live-validated; Windows CI initiated but complete green checks not established at this entry. Earlier intermediate commits with incomplete gallery methods caused analyzer failures; those do not establish final-head failure or success. Draft PR #4 stays open and unmerged. Next: finish current-head CI, correct any issues, user debug/release cape & animation acceptance, then R4-D.

## 2026-10-22 — R4-B real PNG Windows acceptance; coplanar overlap follow-up

- **User screenshots:** Real Java skin PNG rendered as a full 3D **Slim** character with distinct head/body/arm/leg textures and outer geometry; second screenshot displays the synthetic face+UV atlas on **Classic** with outer layers enabled. User reports all works.
- **User Windows commands for source `6caca7de`:** feature fast-forward from `981ef19` to `6caca7d`, root `flutter analyze --no-pub` **PASS** (10.2s), root `flutter test --no-pub test/` **36/36 PASS**, example analyzer **PASS** (7.5s), example regression **1/1 PASS**, Windows debug build **PASS** (10.4s), Windows release build **PASS** (25s) and release EXE launched. Debug session ended with `Lost connection to device`; no claim of proven crash. The three generated Windows registrant files were modified locally before the pull; user files must be preserved.
- **Exact `6caca7de` CI:** Windows R1 `39701863568`, R2 `39701863516`, R3 `39701863709`, and R4 `39701863413` / `39701856967` all **SUCCESS**. Earlier R4-B lint failures were fixed with interpolated node name in `6caca7de`.
- **New log caveat (NOT cleared by screenshots):** Repeated `flutter_scene` coplanar overlap warnings identify six overlapping outer shell surfaces, specifically `body/outer` with both `arm/outer`, and `leftLeg/outer` with `rightLeg/outer`. The mathematical 0.25 model-pixel expansion produces overlapping planar face fragments at adjacent joints. This can flicker from certain camera angles despite the user's functional approval; R4-B quality follow-up required before beginning R4-C.
- **Targeted fix `fbdcbbf` (Windows NOT RECHECKED):** Give base material `depthLayer=0`, outer jacket/right-leg/head `depthLayer=1`, outer arms/left-leg `depthLayer=2`, using supported `flutter_scene 0.24.3` material depth offset. Pairwise conflicting outer shell faces now have distinct layer priorities without altering source R2 UVs or physical mesh inflation. `Node.renderOrder=1` remains alpha-pass ordering. This is intended to eliminate depth-buffer fighting; actual GPU behavior and absence of diagnostic warnings **not yet established**. Source: `https://github.com/bdero/flutter_scene/blob/flutter_scene-0.24.3/packages/flutter_scene/lib/src/material/material.dart`.
- **Next gate:** Current-head Windows CI plus user debug/release R4-B check, particularly `Scene.findCoplanarOverlaps` log, shoulders/leg seams when orbiting, true skin alpha and texture reload, Classic/Slim orbit retention. Only then mark R4-B closed and begin approved R4-C. PR #4 stays Draft/unmerged.

## 2026-10-22 — R4-A Windows acceptance; R4-B transparent outer skins implemented

- **R4-A user verification:** On Windows, root `flutter analyze --no-pub` PASS (10.8s); `flutter test --no-pub test/` **30/30 PASS**; example analysis clean (10.8s) and `flutter test --no-pub test/widget_test.dart` **1/1 PASS**. Debug `flutter run -d windows --enable-flutter-gpu` built in 11.5s, user confirmed the 3D atlas viewer worked. Switching Classic/Slim preserved view/orbit orientation (important UX property); Windows release built in 35.0s and EXE was launched. Exact feature-head [CI 39700425421](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39700425421) **SUCCESS** and prior feature CI `39700110173` successful. User did not separately enumerate screenshots of every top/bottom corner; consider R4-A functionally Windows-verified, not GPU face-by-face pixel-captured.
- **Debug terminal caveat:** `Lost connection to device` appeared after the session and repeated flutter_scene depth-information messages; user reported no running-gallery fault. No unsupported crash or memory-leak-free claim.
- **R4-B implemented after A acceptance (same approved PR #4):** Extend `MtnMinecraftSkinBoxMesh.forBodyPart` with a base/outer layer, R2-provided outer UVs and expanded shells (head 0.5 model pixel per side; other parts 0.25). Synthetic alpha-pattern atlas overlays plus optional **local Java 64×64/legacy 64×32 PNG path** added to the GPU gallery. Six base and six outer mesh nodes share the normalized R2 straight-RGBA texture; outer alpha blended and independently shown/hidden. Classic/Slim changes preserve orbit and layer settings. No skin downloads or third-party assets.
- **R4-B tests:** New `test/mtn_minecraft_skin_outer_mesh_test.dart` checks both models, all six parts, all face outer UVs, outward winding and shell inflation. Current R4-B CI, actual alpha sorting from all camera angles, local real-skin file smoke and Windows release **PENDING**; do not infer visual validity from math-only tests.
- **R4-C/D:** approved but **NOT STARTED**; no cape, poses, production 3D widget or GPU memory soak. Draft PR #4 remains unmerged. Next: verify full Windows CI and real debug/release R4-B skin/layer visibility, transparency, Classic/Slim and camera behavior.

## 2026-10-22 — R4-A Draft PR #4 and first CI evidence

- **Draft PR:** [#4 — R4-A 3D Mesh UV Foundation](https://github.com/nusretm/minecraft_skin_viewer/pull/4), targeting `main`. Draft, not merged. R4-B/C/D approved but **not implemented**.
- **Initial Windows CI:** [run 39699923786](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39699923786) on feature code `9657bfb8`: `flutter --version`, root dependencies, root analyzer, **entire root test suite including R4-A mesh tests**, example dependencies and example analyzer **PASS**. R1 controls regression was **IN PROGRESS** and Windows release compile **NOT YET RUN** at inspection; no complete green CI claim.
- **Reviewer diff:** 11 files on PR #4; no added-line trailing whitespace found in GitHub patch scan. Geometric cross-product arithmetic checked separately for all six face quads: outward winding matches face normal. Real `git diff --check` on a Windows worktree and direct GPU visual validation have **not** been run by assistant.
- **Next required evidence:** completed current-head Windows CI and user's actual debug+release R4-A gallery UV-face/corner marker check. Keep PR Draft and do not merge; R4-B begins only after R4-A visual checkpoint review.

## 2026-10-22 — R4 approved; R4-A Mesh & UV Foundation implementation

- **User approval:** Explicit R4-A/B/C/D full 3D plan approval, with instruction to start **R4-A only**, feature branch `feature/r4-full-3d-skin-viewer`, Draft PR, Windows live acceptance gate. Conditional merge delegation remains subject to completing the approved scope and actual tests.
- **Base/head:** Started from clean `main` `bb32bcb86c14fca60aa62f03279ca1c2041284f0`. No concurrent open PR at branch creation; user previously confirmed local `main` status clean. No changes to other repositories.
- **R4-A implemented:** Renderer-neutral `MtnMinecraftSkinBoxMesh` generates 24 vertices/36 outward-facing triangle indices, flat normals and R2-sourced per-face UVs for Classic/Slim. Includes standing six-part center placements and defensive array snapshots. No duplicate Minecraft atlas-coordinate table.
- **Windows visual harness:** New R4-A screen accessible from R1 example app bar renders six R2-atlas textured GPU meshes using `flutter_scene` 0.24.3, `MeshGeometry.fromArrays` and `Texture2D.fromPixels`. Synthetic atlas has distinct face color and TL/TR/BL corner sentinels. Preserves R1 and R3 screens. R4-B outer layer, R4-C cape/pose and R4-D production viewer are **not started**.
- **Validation state:** Mesh unit tests and Windows R4-A workflow added; CI and Windows live smoke **NOT YET VERIFIED**. Existing R1-R3 acceptance remains intact; do not infer live GPU UV validity from analyzer/build success.
- **Next:** inspect CI, resolve issues strictly within R4-A, review Draft PR, then user Windows debug+release face orientation/Classic-Slim/resize smoke. No merge. See `docs/continuity/R4_FULL_3D_VIEWER.md`.

## 2026-10-22 — R3 CLOSED: Windows 2D gallery accepted, PR #3 merged

- **User Windows live acceptance:** clean `main` at checkout, then tracked `feature/r3-2d-skin-cape-preview`; root `flutter pub get` PASS, `flutter analyze --no-pub` NO ISSUES (12.4s), `flutter test --no-pub test/` **22/22 PASS**; example `flutter analyze --no-pub` NO ISSUES (6.5s), `flutter test --no-pub test/widget_test.dart` **1/1 PASS**.
- **Windows application:** debug `flutter run -d windows --enable-flutter-gpu` built (14.2s), user confirmed the 2D gallery and all controls worked; Windows release build PASS (27.9s) and user launched the release EXE, confirming all functionality. Debug log ended with `Lost connection to device` after session output; cause not established and no continuing defect reported. Do not misrepresent the line as a proven crash or an entirely clean Flutter debug shutdown.
- **Exact feature HEAD CI:** commit `dfb02af07acd36a5f96c7f8bd301c5584cc4e8bb`; R1 [39696653097](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39696653097), R2 [39696653047](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39696653047), and R3 [39696653054](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39696653054) + [39696646453](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39696646453) all completed **SUCCESS**, including R3 root pixel tests, example regression and Windows release builds.
- **Review:** PR #3 diff scoped to 11 files, no added-line trailing whitespace in patch scan; original gallery lint failure corrected earlier on feature. No force push or extra repository changes.
- **Merge:** user had delegated conditional merge authority for already-approved, validated scopes. Marked PR [#3](https://github.com/nusretm/minecraft_skin_viewer/pull/3) ready and squash merged as `3c4a56f4ca126ecbeb857e8e58f6dbf8755b0d56`; GitHub verified PR closed/merged and `main` matched squash SHA immediately afterward.
- **Delivered:** 2D head/body/cape Flutter widgets, Classic/Slim and legacy layout, front/back, outer layer toggles, nearest sampling, deterministic generated gallery, image lifecycle guards. Fully textured 3D Minecraft character is **NOT** part of R3.
- **Remaining:** R1-controlled GPU memory soak still unmeasured; full-texture 3D UV/animations R4 planned but **not approved**. No local post-build `git status -sb` was provided; preserve local user changes. Next: user sync `main` and independently approve R4 scope before coding.

## 2026-10-22 — R3 Draft PR #3 and initial Windows CI findings

- **Draft PR:** [#3](https://github.com/nusretm/minecraft_skin_viewer/pull/3), base main, active feature `feature/r3-2d-skin-cape-preview`. NOT MERGED.
- **Initial failure:** Windows [CI 39695839244](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39695839244) stopped at root `flutter analyze --no-pub` with three `example/lib/r3_gallery.dart` lints: two `prefer_interpolation_to_compose_strings` and one `curly_braces_in_flow_control_structures`; downstream tests and release build SKIPPED. The three lines were fixed in commit `3405360`.
- **Async widget-test hardening:** R3 capture/fixture tests involve engine codec and pixel readback Futures. To prevent Flutter widget FakeAsync from blocking those I/O completions, `test/mtn_minecraft_skin_2d_test.dart` now uses `tester.runAsync` for fixture encoding/capture and pumps after actual decode in commit `3e97145`. Validation of this correction is still **NOT CONFIRMED**.
- **Current source verification:** earlier pre-gallery R3 root analysis passed, but later gallery lints failed as above; no confirmed fully green current-head CI or Windows R3 gallery live visual smoke yet. Preserve Draft and do not conditionally merge until checks and user visual acceptance pass.
- **Diff:** PR contains eleven R3-specific files, with no added-line trailing whitespace found in GitHub patch scan. No local Windows commands were run by the assistant.
- **Next:** verify current head's root analyze/pixel tests, example analyzer/regression and Windows release build; user to inspect head/body/cape gallery and controls in debug/release.

## 2026-10-22 — R3 2D previews implementation (not yet accepted)

- User explicitly approved the R3 2D head/body/cape plan with front/back,
  outer layers, Classic/Slim, nearest scaling, lifecycle and Windows tests.
  The optional conditional merge delegation **does not override** quality gates.
- Branch: feature/r3-2d-skin-cape-preview from main 6493273; only this
  repository changed. Production 2D API exports MtnMinecraftSkinHead,
  MtnMinecraftSkinPreview, MtnMinecraftCapePreview and MtnMinecraftSkinView.
- Widget internals use R2 atlas UVs, CustomPainter and cached/disposed Flutter
  ui.Image from correctly premultiplied R2 RGBA; no Flutter GPU at package root.
- Pixel-capture fixture tests check head/body/cape, front/back, layers,
  Classic/Slim, legacy left limbs, 32/64/128/256 nearest sizes and texture
  replacement. Example adds a generated-fixture gallery accessible from R1.
- This is IMPLEMENTED source, not yet Windows LIVE_VALIDATED. GitHub CI must
  complete root tests + example analyze/regression + Windows release; user
  must inspect actual gallery visuals/resize before the PR can merge.
- R1 GPU memory soak deferred. R4 full 3D mapping not included.
- Detailed checkpoint: docs/continuity/R3_2D_PREVIEW.md.

## 2026-10-22 — R2 CLOSED and conditional merge authorization updated

- **Approval:** user explicitly authorized the assistant to merge when necessary, rather than requesting permission for every merge. The existing mandatory *feature implementation approval* remains unchanged. Conditional merge delegation applies only to approved, scoped work after reviewing actual test/CI evidence and material risks; blockers or scope changes must be surfaced rather than silently merged.
- **R2 PR #2:** marked ready and squash merged as `00da98ab0356cd43d4ebf0de061735a7253a1ea9`; GitHub reports PR #2 closed/merged and `main` HEAD matched the squash SHA immediately afterward.
- **Included:** R2-A PNG decode/validation and legacy conversion; R2-B backend-independent Classic/Slim UV atlas with overlay/cape; R2-C 15 synthetic tests, root/example CI and integration contract. No full Minecraft-textured 3D player or 2D production widget claimed.
- **Acceptance evidence:** user Windows root tests **15/15 PASS**, root/example `flutter analyze` clean, existing example widget test 1/1 PASS, Windows release built/launched and resize/interactions fine. CI for earlier functional R2 SHA `19d0ee20` passed; latest feature HEAD `38c20dd8` CI was still running at merge time (docs-only changes from tested code).
- **Remaining risks:** GPU memory soak not measured; real Minecraft atlas rendering belongs to R3/R4; there is no claim of full 3D player visual proof from R2.
- **Next:** user should sync local `main` with `origin/main` after checking worktree. R3 is **PROPOSED**, not approved for implementation. Review/approve R3 2D previews before creating feature code. Local/remote feature-branch deletion is not implied by a merge.
- **Continuity:** merge-related working rules and AGENTS updated on `main`. This closure changes documentation only.

## 2026-10-22 — User Windows acceptance evidence for R2-A/B/C

- **Checkout:** user's original `main...origin/main` was clean; fetched remote feature branch and switched with `git switch --track origin/feature/r2-skin-texture-uv-foundation`. Local post-test `git status -sb` was **not supplied**; do not infer worktree remains clean after Flutter tooling.
- **Local R2 core results (user output):** `flutter pub get` PASS; `flutter analyze --no-pub` **No issues found!** (10.8s); `flutter test --no-pub test/` **15/15 passed** (6s), including all legacy mirror tests.
- **Local R1 example regression (user output):** `flutter pub get` PASS; `flutter analyze --no-pub` **No issues found!** (7.2s); `flutter test --no-pub test/widget_test.dart` **1/1 passed** (2s).
- **Windows release:** `flutter build windows --release` PASS (25.1s); user launched `build/windows/x64/runner/Release/mtn_minecraft_skin_viewer_example.exe` and reported all interactive controls work, including window resizing. The example still renders the R1 synthetic checker texture, **not** a fully mapped Minecraft skin. No controlled GPU-memory soak or 10–20-cycle measurement was reported.
- **CI cross-check:** R2 Windows run [39692800346](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39692800346) (earlier feature commit `97a701a9`) **SUCCESS** with root analyze, R2 tests, example analyze, R1 widget test, and release build. Latest source/docs HEAD `9bab7217` runs [39693218190](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39693218190) / [39693213017](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39693213017) were still **IN PROGRESS** at verification; their analyze and R2 tests had already passed.
- **Status / gate:** R2-A/B/C implemented and local validation successful, but PR [#2](https://github.com/nusretm/minecraft_skin_viewer/pull/2) remains **Draft / unmerged**. Await final CI and explicit user acceptance/merge authorization; do not merge automatically.

## 2026-10-22 — R2 validation and Draft PR #2

- **Draft PR:** [#2 — R2 Texture & UV Foundation](https://github.com/nusretm/minecraft_skin_viewer/pull/2), feature branch `feature/r2-skin-texture-uv-foundation` against `main`; **not merged**.
- **Initial CI** [39692378455](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39692378455): Flutter root analyzer **PASS**, 12/14 synthetic tests PASS, 2 codec-dependent RGB-under-alpha exact-value assertions FAIL. This was an overly strict fixture expectation, not evidence that alpha was wrong.
- **Test fix:** semi-transparent/fully-transparent pixel tests now check preserved alpha without assuming invisible RGB exactness. Deterministic truncated-PNG error fixture added. In the subsequent [39692470025](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39692470025), Windows CI root analyze, R2 texture/UV tests, example resolution and example analyze all **PASS**. At observation, R1 controls regression step was **IN PROGRESS**, and Windows release build result **NOT YET CONFIRMED**.
- **Additional R2-C test:** all 12 legacy mirroring face copies now compare the destination's left/right sentinel pixels to their corresponding source ends. This newer test is **not yet confirmed by a completed CI run**.
- **Diff review:** PR #2 contains 12 files and no added-line trailing whitespace found in patch scan. A real local Git worktree is not available in this session; no independent local `git diff --check` or Flutter run was claimed.
- **Next gate:** finish latest Windows CI, then user may validate with `flutter analyze --no-pub` and `flutter test --no-pub test/`. Do not merge before user acceptance and separate merge authorization.

## 2026-10-22 — R2 texture/UV foundation on feature branch

- User explicitly approved R2-A PNG/legacy normalization, R2-B skin/cape
  face UVs for Classic/Slim, and R2-C synthetic tests + Windows CI + Draft PR.
  Merge is **not** approved.
- Branch `feature/r2-skin-texture-uv-foundation` created from clean main
  `8a8bb2c`; no unrelated repository modifications.
- Added normalized 64x64 skin/cape RGBA containers, PNG header/decode checks,
  legacy left-leg/left-arm per-face mirrors, base alpha rules and the
  64x64/64x32 UV layouts. Models use explicit Classic/Slim and face/layer enums.
- Synthetic tests cover face bounds/positions, mirror direction, alpha,
  malformed images and cape. Separate R2 Windows CI also regression-tests
  the R1 example. At this writing, successful CI verification is **pending**.
- Scope boundary: R2 is a shared data contract, not a production skin viewer.
  Minecraft texture application in a full 3D character remains R4; 2D UI is R3.
- See `docs/continuity/R2_TEXTURE_UV_FOUNDATION.md` for precise data behavior.
  Next: review actual CI, resolve failures, and open a Draft PR without merge.
  The R1 GPU memory soak is still deferred.

## 2026-10-22 — R1 CLOSED: PR #1 squash-merged into main

- **User acceptance and merge authorization:** user explicitly approved squash merge of [PR #1](https://github.com/nusretm/minecraft_skin_viewer/pull/1). GitHub confirmed successful squash merge as `530dd4a757b29a162d932bd658d269a7d35f5e23` and `main` HEAD matched that exact SHA immediately after merge. The PR is closed/merged; it is no longer Draft.
- **Delivered R1:** independent Flutter package scaffold, Windows example and persistent `project.set_enable_flutter_gpu(true)`, `flutter_scene 0.24.3` 3D six-part prototype, orbit/zoom, translucent head overlay, synthetic 8×8 PNG texture with nearest sampling, and manual `Recreate viewer` lifecycle harness. Production 2D/3D skin/cape widgets and Minecraft atlas UVs **NOT** implemented.
- **Real Windows acceptance:** Flutter 3.47.7 debug/release binaries both launched and visibly rendered synthetic texture; user confirmed interactions and recreation work. Local Flutter analyzer clean and focused GPU-free widget test 1/1 passed. GitHub Actions runs `39689222086` and `39689226713` green for functional code `4424597`; the final merge also contains documentation-only commits.
- **Consciously deferred validation:** `Recreate viewer` functional behavior was confirmed, but a controlled 10–20-iteration GPU memory/long-duration leak soak was **not measured**; do not claim leak-free operation. Follow this up before production/publication as appropriate.
- **Current handoff:** no implementation active on `main`. R2 texture/atlas model remains `PROPOSED`; scope, acceptance criteria and branch should be approved before implementation. See `PLANNED_2026-10-22_SKIN_CAPE_VIEWERS.md`.
- **Local cleanup still owned by user:** ensure `git status -sb` is safe, then `git fetch origin`, `git switch main`, `git pull --ff-only origin main` and verify `git log -1`. Do not delete working tree/user files. Delete local feature branch only after verifying merge and no unpushed changes.
- **Continuity closure note:** this entry was written to `main` after verified PR squash merge and does not change rendering source code.

## 2026-10-22 — Windows PNG nearest-filter and recreate smoke PASS; Draft PR review next

- **User-confirmed Windows local run on feature commit `4424597056a1f3397f2281608e2144bf033895a4`:** `flutter analyze --no-pub` on `example/` **No issues found!** (7.8s), GPU-free `flutter test --no-pub test/widget_test.dart` **+1 All tests passed**, `flutter run -d windows --enable-flutter-gpu` debug executable built (11.6s) and displayed an interactive 3D character with sharp 8x8 yellow/purple PNG head. `flutter build windows --release` produced release EXE (24.7s), which was launched directly and showed the textured head in a second screenshot.
- **Manual UI observation:** user stated all functions work, including existing mouse orbit, zoom, overlay and new `Recreate viewer` control. Test images show the new control in debug and release. No measured count of recreate cycles or before/after GPU memory was provided, so do **not** claim a full soak test or absence of GPU leaks.
- **Texture conclusion:** synthetic PNG -> `Texture2D.fromEncodedBytes` -> nearest min/mag sampling -> cuboid geometry UV pipeline visually works in Windows debug and release. This does **not** validate real Minecraft 64x64/64x32 skin face layout, cape UV, Classic/Slim differences or 2D widget APIs (R2+).
- **CI verified for exact feature commit:** Windows Actions runs [39689222086](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39689222086) and [39689226713](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39689226713) both completed **success**: root analyze, example analyze, GPU-free widget test and Windows release compilation all **PASS**. CI does not run interactive GPU smoke; Windows screenshots/user feedback provide that evidence.
- **Gate:** functional R1 acceptance evidence is ready for review. Source remains on [Draft PR #1](https://github.com/nusretm/minecraft_skin_viewer/pull/1). **No merge approval or merge performed.** Optional bounded memory measurement is still an identified, not silently passed, risk.

## 2026-10-22 — R1 synthetic texture and lifecycle smoke implementation (awaiting Windows validation)

- **User authorization:** user agreed to proceed with remaining R1 work; no merge authorization.
- **Implementation on R1 feature branch:** example creates an 8×8 synthetic yellow/purple checker as PNG bytes, uploads via `Texture2D.fromEncodedBytes`, disables mipmaps, sets GPU min/mag filters to `MinMagFilter.nearest`, and applies it to the head cuboid's built-in UVs. This proves a texture pipeline only if visually verified; **not** Minecraft skin atlas mapping or a full UV implementation.
- **Lifecycle harness:** `Recreate viewer` temporarily unmounts the scene view and reconstructs a new scene. `Scene.dispose()` is called in widget disposal; texture objects do not expose a direct disposal API, so no leak-free claim is made until repeated Windows observation.
- **No source dependency changes.** CI analysis/widget smoke/release compilation and user-visible debug/release texture and lifecycle verification remain required. R1 remains open in Draft PR #1.
- **Earlier verified state:** Windows Flutter 3.47.7 debug/release untextured scene, orbit, zoom, overlay successful; Windows runner opt-in committed at `84fac44`.

## 2026-10-22 — Windows runner persisted to GitHub in commit 84fac44

- **LIVE verified local release setup is now versioned:** user staged 22 generated Flutter example scaffold/source files, reviewed `git diff --cached --check` (**clean**) and the staged `example/windows/runner/main.cpp` diff, committed as `84fac44e64dacaf47f40349a3d64920213cd8a24` (`build(example): persist Windows runner and Flutter GPU configuration`) and successfully pushed `feature/r1-renderer-foundation`.
- **GitHub independently verified:** feature remote HEAD matched `84fac44e64dacaf47f40349a3d64920213cd8a24`; fetched `example/windows/runner/main.cpp` includes both `flutter::DartProject project(L"data");` and `project.set_enable_flutter_gpu(true);`. `example/.gitignore`, `example/.metadata`, `example/analysis_options.yaml`, `example/pubspec.lock`, and Windows runner files are now tracked; root package lockfile remains ignored.
- **Line-ending warnings:** Git reported LF-to-CRLF warnings for selected files; successful `git diff --cached --check`, commit, and push provide no evidence of a blocking whitespace error.
- **CI at observation:** runs [39688345578](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39688345578) and [39688352204](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39688352204) for `84fac44` were **IN PROGRESS**; do not mark new HEAD CI passed yet.
- **R1 next action:** synthetic PNG textured geometry + nearest-filter verification and repeated widget mount/unmount/lifecycle smoke, followed by Windows validation and review. **Not** full Minecraft skin atlas, 2D production widgets or R2 scope. PR #1 remains Draft, unmerged.

## 2026-10-22 — Windows release GPU render recovery LIVE VERIFIED

- **Actual user Windows release proof:** after opening/editing the local `example/windows/runner/main.cpp`, user ran `flutter build windows --release` and it succeeded in **8.2s**, then launched `build/windows/x64/runner/Release/mtn_minecraft_skin_viewer_example.exe`. Supplied screenshot shows 3D block character, normal Flutter scaffold, colored geometry and enabled head overlay. User confirmed **all functions still work** (orbit, zoom, overlay) in this release run. This closes the previous release GPU opt-in runtime blocker on the user's local machine.
- **GPU opt-in persistence still pending:** the successful `example/windows/` runner source was generated locally and was previously untracked. **Do not infer it is committed**. Stage and review only intended source/config files, including `windows/runner/main.cpp` with `project.set_enable_flutter_gpu(true);`, and push feature branch after local diff check. Do not remove local files or blindly commit generated build output.
- **Other actual R1 validation:** Windows debug 3D and interactions PASS; local `flutter analyze --no-pub` and `flutter test --no-pub test/widget_test.dart` PASS. Latest GitHub Actions R1 commit results were still in progress at observation time; green CI not claimed for latest HEAD.
- **Still outside validated scope:** a real pixel-texture/nearest-neighbor test, face UV mapping, and repeat mount/unmount/lifecycle resource check. Production skin/cape widgets remain unimplemented. PR #1 stays Draft; user has not approved merge.
- **Next immediate task:** preserve the working Windows runner and its release GPU opt-in in Git, then finish R1 texture sampling and lifecycle tests before checkpoint acceptance.

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
