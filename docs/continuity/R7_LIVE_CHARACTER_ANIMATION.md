# R7 — Live Character Animation

**State:** APPROVED / implementation on feature branch; GitHub CI and Windows user visual validation pending.
**Date:** 2026-10-23
**Base:** main `0e46ca48d0dde18893e9faa0bef78b1f7de68731`
**Branch:** `feature/r7-live-character-animation`
**PR:** [#8 — R7 Live Character Animation](https://github.com/nusretm/minecraft_skin_viewer/pull/8) (Draft; Windows CI running)

## Approved behavior

- `MtnMinecraftSkinPose` gains `live`, while `idle` and `walk` remain selectable.
- `MtnMinecraftSkinViewerController` defaults to `live` (including the widget-owned controller), with `setPose` remaining the sole host control.
- Live breath: over 3.8 seconds shoulders smoothly rotate out from the body during inhale, then in during exhale; right/left signs are mirrored. Legs remain static, torso remains static, and both skin models use their existing pivot locations.
- Live head: occasional randomly chosen right, left, up, down looks. A 2–5 second neutral pause before each glance, 0.4-second smooth rotate, 1–4 second hold, 0.4-second smooth return; side looks approximately 12–25 degrees; vertical 8–16 degrees.
- On Live→Idle/Walk, both shoulder Z and neck yaw/pitch return to neutral. Controller orbit, camera zoom, cape/outer visibility must not restart the current animation cycle.
- Live and Walk use the already-present 3D Ticker and Node joint rotations. Idle remains static with ticker stopped.
- The view-owned random head scheduler takes Ticker time (no timers, tasks, new dependencies, mesh/texture regeneration, or new controller source of truth).
- 2D head/skin widgets remain static. No launcher application changes.

## Implementation location

- `lib/src/mtn_minecraft_skin_pose_cape.dart`: enum extension, pure pose frame angles for shoulders/neck.
- `lib/src/mtn_minecraft_skin_live_head_motion.dart`: time-based seeded/testable stochastic glance scheduler, resetting per new Live session.
- `lib/src/mtn_minecraft_skin_viewer_3d.dart`: existing Ticker for Live and Walk, full-axis joint transforms, lifecycle and pose transition handling.
- `lib/src/mtn_minecraft_skin_viewer_controller.dart`: default Live.
- `example/lib/r4d_viewer_gallery.dart`: Live button along with Idle/Walk, default Live and 20× scene recreate harness kept.
- `test/`: focused breath, four directions/hold/reset, controller default/transition tests.
- README, CHANGELOG, ARCHITECTURE and CURRENT_TARGET: contract and evidence.

## Validation gates

- Exact GitHub feature-head Windows workflows: root and example analyzer, full tests, release Windows build; no false success claims.
- User Windows debug `flutter run -d windows --enable-flutter-gpu` with real skin and cape: watch full breathing cycle, all four head directions, transitions Live→Idle→Walk→Live, camera movement, texture replacement and 20× recreate.
- User Windows release build and direct EXE interactive visual smoke; debug success does not certify release.
- `git diff --check`, `git status -sb`, source diff review and scoped PR; do not change the four existing user modified generated files or unrelated repos.
- Only close/squash merge when agreed acceptance is verified. No pub.dev release or Flutter upgrade.

## 2026-10-23 — Initial Windows compile blocker and corrective commit

- User checked out `feature/r7-live-character-animation` and ran `flutter pub get`, root `flutter analyze --no-pub`, root `flutter test --no-pub test/`, example analyze and Windows GPU debug launch.
- Root analysis **FAILED** with two `undefined_method` errors at `lib/src/mtn_minecraft_skin_viewer_3d.dart` around lines 312 and 317: `Quaternion.multiply` is unavailable in the pinned `vector_math 2.4.3`. Root tests and Windows debug build **BLOCKED** by the same compile errors; example analyzer alone **PASSED** and does not prove package compilation. No live GPU acceptance was possible at this revision.
- Exact prior HEAD `4703b1d893edf322aebe62132fbfdab869c2b0da`: Windows R1 [#39961671476](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39961671476), R2 [#39961671367](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39961671367), R3 [#39961671720](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39961671720), R4 [#39961671763](https://github.com/nusretm/minecraft_skin_viewer/actions/runs/39961671763) all **FAILED**. These failures are not counted as acceptance evidence.
- Scoped fix commit `4b40156cc06956c978ebb8b4954b8fa6dd7bde1e`: replace both unsupported cascaded `..multiply(q)` calls with the supported, typed `Quaternion * Quaternion` operator, preserving axis order X→Z for arms and Y→X for the head. API source: https://pub.dev/documentation/vector_math/latest/vector_math/Quaternion-class.html
- New exact-head Windows CI and user re-test **PENDING**. No merge/closure or unverified compile success claim. User's four modified generated/lock files remain excluded from GitHub changes.
