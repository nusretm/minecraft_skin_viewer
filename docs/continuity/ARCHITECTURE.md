# Architecture — Minecraft Skin Viewer

Status: R1/R2/R3/R4 CLOSED in main; R5-A/B/C package-only public widget finalization code on Draft PR #5, Windows CI and live verification pending. GPU dedicated-memory metrics remain unmeasured.

## Scope

One Flutter package: `mtn_minecraft_skin_viewer` in repository `nusretm/minecraft_skin_viewer`. A single-technology Flutter repository uses package-standard root `lib/`, `test/` and `example/`, plus root `docs/`; do not introduce empty `rust/`, `dart/` or `ui/` directories.

## Ownership boundaries

1. **Input data / texture representation**: image bytes, decoded pixel data, original PNG dimensions, decode/validation errors.
2. **Minecraft mapping**: Classic vs Slim geometry dimensions; 64x64 and legacy 64x32 UV/overlay layout; cape layout. Explicit model type input.
3. **2D renderer**: head and body previews rendered with Flutter primitives from the common atlas model.
4. **3D geometry and render adapter**: character parts, local transforms, camera/gesture interaction; texture/UV data is not owned by Flutter Scene-specific public classes.
5. **Public widget layer**: `MtnMinecraftSkinHead`, `MtnMinecraftSkinPreview`, and `MtnMinecraftCapePreview` are implemented in R3. `MtnMinecraftSkinViewer` (3D) is implemented and Windows functionally validated, squash-merged in PR #4.

Package does not log in to accounts, download user profile skins, manage credentials or call Mojang/Microsoft APIs.

## Planned sequence

- **R1**: prove a minimal Windows 3D scene with 6-part blocky human, camera orbit/zoom, texture nearest sampling feasibility, transparent overlay feasibility and proper cleanup. Prototype-only dependency is permitted in `example/`; do not freeze the production public API.
- **R2**: shared atlas decode/validation and correct per-face UVs for Classic/Slim and modern/legacy; tests with synthetic fixtures.
- **R3**: 2D widgets and crop/layer/preview behaviors.
- **R4**: complete 3D viewer including real skin atlas, cape and basic poses/animations.
- **R5**: launcher embedding, performance/resource smoke and release validation.

## Render candidate

`flutter_scene` (published package, MIT) is the R1 candidate, currently 0.24.3 as checked on 2026-10-22. Built on Flutter GPU; APIs may change in pre-1.0 releases. Its setup command is `dart run flutter_scene:init`, and `Scene.initializeStaticResources()` must resolve before constructing GPU resources. For native debug run use `flutter run -d windows --enable-flutter-gpu`; on Windows release, Flutter 3.47.1+ and `flutter::DartProject::set_enable_flutter_gpu(true)` in `windows/runner/main.cpp` are required.

Primary references:
- https://pub.dev/packages/flutter_scene
- https://github.com/bdero/flutter_scene/blob/master/packages/flutter_scene/README.md
- https://github.com/bdero/flutter_scene/blob/master/AGENTS.md
- https://github.com/flutter/flutter/issues/190871

R1 debug/release visual rendering was user-verified. R2 shared data mapping has not yet been integrated with a full textured GPU character.

## R2 shared atlas authority

The canonical 64x64 skin atlas and pixel-space UV face layout live in
`lib/src/mtn_minecraft_skin_texture.dart` and
`lib/src/mtn_minecraft_skin_uv.dart`. Their APIs are renderer-independent,
with explicit Classic/Slim model input and deterministic legacy mirroring.
Java 64x32 cape UVs share the same face convention. 2D widgets (R3) and
3D mesh adapters (R4) must consume these mappings, not maintain separate
Minecraft coordinate tables.

## R3 2D Flutter painting

Three public widgets consume R2 normalized texture objects. A private
stateful raw-image holder and CustomPainter share painting/lifecycle logic;
all UV crops come from R2 face mappings, never a second coordinate table.
Front/back and overlays are widget presentation inputs. No flutter_scene
dependency is introduced into the root package. See R3_2D_PREVIEW.md.

## R4 renderer-neutral 3D mesh and flutter_scene prototype

The pure Dart R4-A cuboid builder produces centered 24-vertex meshes with
6 independent face normal/UV sets and 36 outward-wound indices, directly
consuming R2 UV rects. Default part centers are in Minecraft units/16.
The example-only adapter uploads R2 normalized straight RGBA with
flutter_scene Texture2D.fromPixels, creates MeshGeometry.fromArrays and
attaches six nodes to a Scene. Production GPU dependency/viewport decision
is deferred to R4-D after observed Windows behavior. See R4_FULL_3D_VIEWER.md.

## R4-B expanded outer mesh geometry (2026-10-22)

The R4-A cuboid mesh API now supports MtnMinecraftSkinLayer.base and .outer
with the SAME R2 UV face authority. Only the extents inflate for the outer
shell, independently of the atlas dimensions. The example-only GPU adapter
draws six opaque base meshes and six transparent alpha-blended outer meshes
from the same uploaded straight-RGBA texture. Outer layer visibility is a
presentation control that does not mutate source texture data. Real Windows
blend sorting remains an explicit visual-acceptance gate, not proven by CI.

## R4-C renderer-neutral cape, pose and GUI hinge

MtnMinecraftCapeBoxMesh, MtnMinecraftSkinPivot and
MtnMinecraftSkinPoseFrame are pure Dart models built from the R2 atlas,
not GPU-specific types. Example-only flutter_scene Node parenting
implements shoulder/hip rotation and a cape hinge. A frame Ticker updates
rotations for the Walk pose without re-generating mesh/UV buffers.
Full public viewer/lifecycle integration belongs to R4-D.

## R4-D production renderer

Root package now depends on flutter_scene 0.24.3 for the proven Windows
GPU backend, isolated inside MtnMinecraftSkinViewer. R2 textures, R4
geometry/pose remain pure data. MtnMinecraftSkinViewerController only
owns camera angles and zoom; parent widget provides skin/cape, pose and
layer visibility, with no duplicate state. The viewer owns scenes,
texture uploads, optional internal controller and animation ticker;
generation checks discard stale async scene builds. Manual repeated GPU
mount/unmount stress and visual verification remain explicit gates.

## R4 merge closure

R4 public 3D renderer/controller, Java cape, transparent layers and pose logic were Windows user-tested and squash-merged as `6b4bc20` in PR #4. Scene lifecycle stress CPU process readings were not monotonically increasing in the sampled release run; direct GPU memory telemetry was not collected, so leak-free GPU behavior is not certified. R5 launcher embedding/release polish remains an unapproved proposal.

## R5 package-only widget contract (approved 2026-10-22)

- Public widgets: `MtnMinecraftSkinViewer` (GPU 3D), `MtnMinecraftSkinPreview` (2D full-body), `MtnMinecraftSkinHead` (2D avatar). Existing `MtnMinecraftCapePreview` stays exported but is outside the three-widget deliverable.
- Shared model: R2 decoded and validated skin/cape texture objects are supplied by the host. This package does not own HTTP download, accounts, cache or launcher integration.
- The 3D `MtnMinecraftSkinViewerController` is the only source of pose (Idle/Walk), outer-layer visibility, cape visibility and camera state. 3D widget constructor keeps texture/cape/controller/interaction callbacks and removes redundant pose/visibility args. There is no second copy of control state on the widget or example.
- The 2D widgets remain declarative, with `texture`, `size`/`height`, front/back and outer-layer bool parameters. They are intentionally not controlled by the 3D controller.
- Controller changes update active joint/cape nodes and camera without reconstructing GPU meshes; changing decoded skin/cape identity rebuilds GPU resources but retains a supplied controller. Host-created controller remains host-owned; default controller is widget-owned.
- `reset()` maintains backward-compatible camera-only semantics; pose/visibility stay unchanged.
- Breaking API change is allowed before the first stable release, but documented in README and accompanied by updated example/test coverage. All acceptance gates remain subject to CI and actual Windows GPU debug/release smoke; no package publication or launcher code changes in R5.

## R6 model inference (CLOSED / merged 2026-10-23)

The texture decoder remains the only PNG decode authority. When the caller omits
`modelType`, modern Java 64×64 input is classified from decoded unmodified
RGBA before the model-specific base-layer alpha fixup. It adapts the MIT
skinview-utils `inferModelType` heuristic: unused Slim arm atlas areas with
nonopaque alpha, or all-black/all-white fills, indicate Slim; otherwise
Classic. Legacy 64×32 defaults to Classic. Explicit `modelType` bypasses
inference. The inference is fallible; callers can override. The resolved
Classic/Slim value is stored in the existing texture model and shared by
2D/3D; no new public confidence API, second UV atlas, widget state or GPU work.
Merged by squash PR #7 as `3b2c7b442681c086c9ef98b90e5d30b6b69922ca`. Final feature-head Windows CI 4/4 SUCCESS; user Windows debug accepted. Interactive release EXE smoke was not independently supplied. See R6_AUTOMATIC_SKIN_MODEL_DETECTION.md for evidence and caveats.

## R7 Live character animation (CLOSED / squash merged 2026-10-23)

`MtnMinecraftSkinViewerController` remains the sole authority for the selected
pose and camera/layer state. Its default is now `live`; `idle` remains
selectable and static, `walk` is tuned from 1.15 to 0.90 Hz. Pose frame angles add symmetric
opposing Z rotations at existing shoulder pivots (open during inhale, close
during exhale) and head yaw/pitch at the existing head/neck pivot.
Four-direction stochastic glances are scheduled inside the GPU viewer state
using only existing Ticker elapsed time and injectable `dart:math.Random`.
The scheduler has no independent timer, observer, GPU allocation or authority
over selected pose. Ticker runs only for Walk/Live, stops for Idle. Changing
camera does not restart animation; switching poses resets neck/shoulder angles.
2D widgets, texture decoding and GPU geometry are unchanged.
PR #8 squash merged as `89796975c8ec52bab256670545f0a4f75b3f477b` after 4/4 Windows CI SUCCESS, 63/63 user tests and accepted Windows GPU debug. Release EXE built/launched; independent interactive release visual check and dedicated GPU memory samples were not supplied. See `R7_LIVE_CHARACTER_ANIMATION.md`.

## R7-F1 3D atlas hairline mitigation (feature, visual trial accepted 2026-10-25)

The renderer-neutral R2 UV atlas remains the canonical map. The GPU scene
reads a separate 3D-only 0.02-texel inward face UV buffer to reduce adjacent
texel leakage; base and inflated outer shell positions remain unchanged.
The Windows A/B tests isolated zoom-dependent head/outer hairlines to the
anti-aliasing path: disabling AA removed them, nearest final compositing did
not, and the user visually accepted SMAA. Only the 3D skin viewer's Scene
chooses `AntiAliasingMode.smaa` by default; no global scene setting or public
controller parameter is introduced. Temporary compile-time diagnostic toggles
were removed. SMAA's additional GPU cost has not been profiled; final-head
tests and Windows no-define/release verification remain pending. Details:
`R7_F1_RENDER_SEAM_FIX.md`.
