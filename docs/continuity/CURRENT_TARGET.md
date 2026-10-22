# Minecraft Skin Viewer — Current Target

**Repository:** `nusretm/minecraft_skin_viewer`
**Base branch:** `main`
**Active implementation:** None; R1/R2/R3 CLOSED and merged. R4 PROPOSED / NOT APPROVED.
**Merged PRs:** [#1 — R1](https://github.com/nusretm/minecraft_skin_viewer/pull/1), [#2 — R2](https://github.com/nusretm/minecraft_skin_viewer/pull/2), [#3 — R3 2D Previews](https://github.com/nusretm/minecraft_skin_viewer/pull/3)
**R1 squash commit:** `530dd4a757b29a162d932bd658d269a7d35f5e23`
**Current checkpoint:** R3 — `CLOSED / PR #3 SQUASH MERGED / WINDOWS DEBUG+RELEASE USER-VERIFIED / ROOT TESTS 22/22 PASS / CURRENT-HEAD CI SUCCESS`; next R4 PROPOSED.

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
