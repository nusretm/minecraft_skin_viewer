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
