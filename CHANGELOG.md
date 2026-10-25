# Changelog

## Unreleased — R7-F1 3D skin seam fix (feature under final verification)

- Derive a 0.02-texel inset only for the 3D GPU face UV buffer. Preserve
  authoritative R2 atlas UVs, model geometry, UV direction and 2D previews.
- Set the 3D viewer Scene anti-aliasing mode to SMAA by default after the user
  visually accepted the SMAA Windows A/B result; remove the temporary
  diagnostic dart-define switches.
- Outer depth priorities, texture nearest sampling, animations, and public
  controller contract unchanged. Existing 67 tests passed before default SMAA
  selection; exact-head CI and no-define Windows debug/release visual smoke
  pending. SMAA GPU overhead has not been measured.


## Unreleased — R7 Live character animation (merged 2026-10-23)

- User-requested visual tuning: slow Walk cadence from 1.15 to 0.90 Hz (about 22% fewer cycles per second), leaving limb swing amplitude and Live breath/head movements unchanged. Fix floating-point-sensitive Live inhale-peak test with a 1e-12 tolerance.


- Add `MtnMinecraftSkinPose.live` with subtle inhale/exhale shoulder Z motion
  and head turns chosen randomly among left/right/up/down, with easing and
  random 1–4-second glance holds.
- Default the public controller and widget-owned viewer controller to Live;
  keep Idle and Walk explicitly selectable. Pose switch resets neck and
  shoulder axes to neutral and does not rebuild 3D meshes.
- Reuse the single viewer ticker; use a clock-driven head scheduler rather than
  timers. Tests use injected fixed or seeded random values.
- Extend the example mode selector and focused regression coverage.
- PR #8 squash-merged as `8979697` after exact-head 4/4 Windows CI success,
  user 63/63 tests, root analyzer pass, and accepted Windows GPU debug visual.
  Release EXE build/launch passed; interactive release visual smoke and direct
  GPU-memory measurement were not independently reported. No new dependency,
  renderer mesh change, networking or launcher integration.


## Unreleased — R6 automatic skin model detection (feature; validation pending)

- Infer Classic/Slim in `MtnMinecraftSkinTexture.fromPng(bytes)` for 64×64 Java
  skins using the MIT-licensed skinview-utils unused-arm-area heuristic.
  Default legacy 64×32 skins to Classic. Explicit `modelType` overrides both.
- Detect on original RGBA in the existing single PNG decode before alpha
  normalization. No additional dependency, renderer/controller change, or API.
- Cover standard Classic/Slim, transparent arm gaps, all-black/all-white gaps,
  legacy and explicit override with focused synthetic tests.
- Windows real-PNG, CI and release smoke still need confirmation; no new
  published version or GPU memory claims.

This package is pre-stable and intentionally uses Git dependencies during
Windows-first development. No pub.dev publication has been authorized.

## 0.1.0-dev.2 — 2026-10-22 (R5 candidate; validation pending)

- Expose three independent Flutter widgets: `MtnMinecraftSkinViewer` (GPU
  3D), `MtnMinecraftSkinPreview` (2D body), `MtnMinecraftSkinHead`
  (2D player avatar). Existing `MtnMinecraftCapePreview` remains exported.
- Make `MtnMinecraftSkinViewerController` the sole source of camera,
  `MtnMinecraftSkinPose` (Idle/Walk), outer layer and cape visibility.
  Add `setPose`, `setShowOuterLayer` and `setShowCape`; state changes
  notify listeners only when values actually change.
- Remove the duplicate `pose`, `showOuterLayer` and `showCape` arguments
  from the 3D widget constructor (breaking early-development API change).
  A supplied controller remains caller-owned; when not supplied the viewer
  creates and disposes a default controller.
- The viewer updates pose, layer visibility and camera without rebuilding
  GPU meshes, while a new skin/cape texture object still recreates the scene.
  Camera changes do not reset the Walk frame and `reset()` remains
  camera-only.
- Expand focused controller/2D regression tests and show all three widgets
  with a shared decoded skin in the example gallery.
- Keep the currently selected Idle or Walk pose through the example's
  20× scene recreate/dispose stress; the harness no longer resets to Idle.

### Host integration expectations

Host applications own URLs, download/cache, and skin/cape PNG retrieval;
the viewer receives already-normalized texture objects. Choose Classic/Slim
explicitly when decoding Java skins. Windows 3D uses Flutter GPU and
`flutter_scene 0.24.3`; launch with `--enable-flutter-gpu` and validate
the release runner's GPU initialization. Check 3D GPU resource lifecycle
separately from 2D painting. No signed release or pub.dev upload yet.

### Known limitations

- Windows is the only platform with completed user live GPU tests so far.
- R4 release 20× recreate CPU-memory stress did not show monotonic growth
  in the supplied sample, but dedicated/shared GPU memory was not measured,
  so zero GPU resource leaks cannot be certified.
- R5 controller-driven behavior and three-widget side-by-side example
  require new local Windows debug/release acceptance before merge.

## 0.1.0-dev.1 — R1–R4 foundation

- Build R2 validated 64×64/legacy 64×32 Java skin and 64×32 cape atlases;
  Classic/Slim UV mapping and renderer-neutral geometry.
- Add independent 2D player head/full-body/cape widgets and Windows-tested
  real textured 3D character/cape with orbit, zoom, Idle/Walk, outer layers
  and asynchronous scene lifecycle.
- R4 implementation squash-merged from PR #4 as `6b4bc20`.
