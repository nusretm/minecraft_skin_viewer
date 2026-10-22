# R4 — Full 3D Minecraft Java Viewer

Date: 2026-10-22
Status: R4-A/B/C WINDOWS VERIFIED; R4-D CODE+46/46 TESTS+WINDOWS CI AND DEBUG/RELEASE BUILD PASS; GPU 20× LIFECYCLE/MEMORY TREND STILL PENDING
Feature branch: feature/r4-full-3d-skin-viewer
Base main: bb32bcb86c14fca60aa62f03279ca1c2041284f0

## Approved plan and sequencing

- R4-A **WINDOWS-VALIDATED**: Backend-neutral 24-vertex/36-index cuboid mesh data,
  source-of-truth R2 six-face UV mapping, Classic/Slim sizes, standing pose
  part centers, synthetic Windows GPU atlas-face smoke and automated tests.
- R4-B **DEBUG GPU VERIFIED, PATCH RELEASE CHECK PENDING**: Independently offset outer-layer geometries, their
  face UVs and alpha handling, Classic/Slim real full skin appearance.
- R4-C **WINDOWS 40/40 AND DEPTH DEBUG VERIFIED; CAPE UV ORIENTATION CORRECTION PENDING LIVE TEST**: 64x32 cape geometry+UV with back hinge, simple
  shoulder/hip pivots and idle/walk basic poses; no cloth physics.
- R4-D **IMPLEMENTED ON FEATURE, NOT ACCEPTED**: Public MtnMinecraftSkinViewer (3D), working
  controller/interaction/lifecycle, true skin+cape hot swapping,
  repeated mount/unmount and memory observations, Windows release checks.

Feature implementation approval does not mean all checkpoints are completed.
Code will remain on the one approved feature branch and Draft PR. Conditional
merge authority requires scope completion, full tests and user live acceptance.

## R4-A design and source files

- lib/src/mtn_minecraft_skin_mesh.dart: MtnMinecraftSkinBoxMesh.forBodyPart
  makes 24 face-local vertices, 36 outward-wound triangle indices and
  explicit normals. Position scale: 1 model pixel = 1/16 world unit.
  Coordinates: Y up, Z toward the camera/front, X to the model's left.
- R2 MtnMinecraftSkinUvLayout is the *only* atlas authority; no hardcoded
  texture net offsets in R4. The six face-local quads map in the identical
  TL/TR/BR/BL order as the R2 normalizedCorners (top-left image origin).
  Bottom face follows R2 flipVertically. Distinct face quad vertices avoid
  wrapped/adjacent-corner UV errors of generic geometry primitives.
- centerFor places Classic/Slim arms at their correct neutral x offsets,
  legs on ground, head top at y=2. This is NOT the animated pose skeleton.
- test/mtn_minecraft_skin_mesh_test.dart: six-face UV equivalence,
  normal/outward triangle cross products, dimensions, placement and
  defensive snapshots for Classic and Slim.
- example/lib/r4a_mesh_gallery.dart: a separate Windows R4-A visual test
  screen entered via R1 example app bar 3D icon. Uses synthetically drawn
  64x64 PNG face colors and corner markers (white TL, red TR, blue BL),
  decodes using the R2 skin texture, uploads straight RGBA once via
  flutter_scene Texture2D.fromPixels, and creates six MeshGeometry.fromArrays.
  Mouse orbit and wheel zoom preserved. Classic/Slim switch recreates scene.
- flutter_scene remains in example/ only. No new root GPU dependency,
  external texture fetch, authentication, user skin assets or other repo edits.

## Verification and gates

- Automated root tests must pass including R1-R3 regressions and new mesh.
- CI Windows: root/example analyzers and tests, release compile.
- **Human Windows live smoke required** before marking R4-A validated:
  run debug with Flutter GPU and directly launch Windows release EXE;
  open R4-A gallery, orbit 360 degrees and inspect all 6 faces and UV
  orientation/corner markers from front/back/left/right/top/bottom; toggle
  Classic/Slim and verify 3px/4px arm widths, resize and mouse zoom.
- Build success alone cannot verify front/back or bottom UV direction.
- No production 3D viewer until R4-D, no cape/outer/poses until B/C.
- R1 deferred GPU memory leak/20x mount-unmount benchmark still open;
  it becomes a R4-D gate. The R1 scene prototype remains in example.
- No merge from this Draft PR until all four checkpoints and actual Windows
  acceptance, unless user explicitly requests a separately reviewed
  intermediate integration boundary.

## Draft PR and interim Windows CI (2026-10-22)

- Draft PR #4: https://github.com/nusretm/minecraft_skin_viewer/pull/4
- Initial Windows R4-A CI run 39699923786 on functional SHA 9657bfb8:
  root analyzer and entire R1-R4A root test suite PASS, example analyzer PASS.
  R1 control regression and release compilation were still pending.
- Six face triangle-winding vectors separately inspected: outward-facing
  normals match indexed triangles for back/right/front/left/top/bottom.
- Actual GPU atlas UV orientation, Classic/Slim appearance, release EXE
  interaction, resize, repeated scene disposal and GPU memory remain NOT
  LIVE-VALIDATED. No merge until agreed gates are complete.

## R4-A Windows closure evidence (2026-10-22)

- User root analysis PASS, 30/30 root tests PASS, example analysis PASS,
  example widget regression 1/1 PASS.
- Debug Windows GPU scene built/launched, 3D atlas works; Classic/Slim switch
  preserves camera orientation. Release build PASS, EXE launched.
- Functional acceptance is user-confirmed but screenshots/pixel captures of
  all six orientations and a repeated memory soak were not supplied.
- GitHub full R4-A CI for commit 981ef194: run 39700425421 SUCCESS.
- The earlier debug line "Lost connection to device" has no proven cause;
  do not label it a confirmed application crash or clean debug shutdown.

## R4-B overlay geometry and gallery (2026-10-22)

- MtnMinecraftSkinBoxMesh.forBodyPart now accepts named layer=base/outer
  (base is default, preserves existing R4-A callers). A dedicated R2 UV face
  is used for each outer layer; head inflated +0.5 model pixel per side,
  jacket/sleeves/trousers +0.25 per side. Position and normals remain
  renderer-neutral.
- New outer-mesh tests check all R2 UV face corners, 24-vertex/36-index
  geometry, outward triangle winding, and shell expansion on all 6 parts
  and Classic/Slim. All R1-R4A tests remain regression gates.
- Windows example R4-A/B 3D gallery keeps synthetic UV face markers and
  adds partial-alpha orange outer-stripe sentinels. Six base/outer meshes
  read the SAME validated R2 skin atlas. Base pass opaque; outer
  UnlitMaterial alphaMode=blend; outer nodes render after base and have
  a visibility toggle without a texture reload.
- Users can paste a Windows file path to an existing local Java skin PNG
  and select "Load PNG"; invalid PNG is rejected by R2. "Use UV test atlas"
  restores generated fixtures. Files are read only locally; no plugin,
  network or copyrighted skin file is shipped. ModelType remains explicit.
- Classic/Slim geometry scene recreation keeps yaw/pitch/distance values,
  outer visibility, and selected PNG bytes. GPU blend/render-order behavior
  must still be visually validated; no shader alpha mask guarantee.
- **No R4-B Windows live smoke or current-source CI success yet.** In
  particular, orbit from the back/sides with a real transparent sleeve
  should be checked for translucency sorting/bleed; adjust if required.
- Cape/poses and production viewer remain R4-C/D (not started).

## R4-B Windows live review and surface-conflict correction (2026-10-22)

- User tested real locally loaded 3D Java skin on Slim, synthetic UV atlas
  on Classic, and all R4-B controls. Screenshots supplied and user reports
  correct output. Root analyze clean, 36/36 tests, example analyze clean,
  1/1 example regression, debug/release Windows build/launch successful.
- Functional code commit 6caca7de passed R1/R2/R3/R4 CI; specifically
  R4 run 39701856967 and 39701863413 succeeded.
- Debug logging nevertheless reported repeated pairs of coplanar inflated
  outer shell faces at jacket/sleeve and left/right trouser edges. These
  may be invisible in a static pose but flicker during orbit/animation.
- Patch fbdcbbf applies intentional per-material flutter_scene
  depthLayer priorities: base=0; outer head/body/rightLeg=1;
  outer rightArm/leftArm/leftLeg=2. This keeps UV coordinates, shell
  geometry and alpha intact. flutter_scene's supported depthLayer is a
  distance-independent subpixel depth offset for coplanar surfaces.
- **CI and real Windows GPU feedback for the fix are still required.**
  Check log for previous six coplanar-overlap warnings, validate seams
  from front/back/sides, nearest/alpha, model switch and release run.
- `Lost connection to device` from debug is recorded as observed with
  unknown origin, not as a proven renderer crash.
- R4-C cape and poses (already approved) must not start until this
  R4-B visual/memory-risk checkpoint is accepted.

## R4-B closure evidence and R4-C implementation — 2026-10-22

- User verified R4-B depthLayer fix in Windows debug: warning about 6
  coplanar overlaps no longer appears, root tests 36/36 pass and analyzers
  have zero issues. All CI workflows for commit f0da7fc succeeded.
  Local post-depth-fix Windows release EXE launch was not reported.
- User clarified Lost connection to device is expected after closing
  the example window; it is not a renderer crash in their workflow.
- Default example Windows test skin path:
  D:\development\cross-platform\9fede215f7cb6884.png.
  Auto-loaded when present/valid with explicitly selected Slim model;
  falls back to synthetic atlas in CI/other environments.
  The PNG file is not checked in or embedded.
- R4-C provides pure Dart cape cuboid with R2 Java cape UV, and pose/pivot
  definitions, exported publicly without a Flutter GPU dependency.
  Automated tests cover six cape UV faces, geometry, winding, shoulder
  and hip pivots, idle/walk opposite-limb motion and cape hinge range.
- Example R4-C adds scene pivot parents for base/outer meshes, a hinged
  nearest-sampled cape with its own 64x32 atlas and optional local cape
  path, plus Cape and Idle/Walk controls. Synthetic cape is generated
  in memory if no file selected. Animation Ticker is tied to widget
  lifespan; the real GPU/resource 20-cycle stress test is deferred to R4-D.
- Intermediate incomplete commits during R4-C screen construction failed
  analyzer because helper/UI methods were not yet connected. Current code
  must be judged by its own Windows CI, not earlier incomplete commits.
- No complete R4-C Windows live visual validation is claimed yet.
  Check correct cape orientation and pivot direction from all viewpoints,
  Classic/Slim switching while walking, outer layers, zoom/resize,
  quick scene replacement, and both debug/release GPU runs.

## R4-C Windows validation and final material overlap (2026-10-22)

- Source 1537f5d: root analyzer clean, 40/40 tests pass, example analyzer clean, example regression 1/1 pass, Windows debug scene built and release EXE compiled/launched.
- Screenshot shows Slim skin, blue cape, Walk selected. A still screenshot does not independently prove the animation or every cape atlas face.
- One z-fighting overlap warning remains at body/outer vs rightLeg/outer while both materials use depthLayer=1.
- Patch 44d219d gives rightLeg.outer depthLayer=3 (vs body 1 and other limb shells 2). Base meshes remain at 0. No physical size, texture, UV, cape hinge or motion changes.
- Fix not yet Windows GPU verified. Must re-run debug with front/back orbit and verify overlap diagnostic disappears; Windows release and current CI must pass. Do not merge or proceed to R4-D before evidence.
- The observed Lost connection to device after closing the window is normal user behavior, not an application crash.

## R4-C cape outside/inside UV regression and default local cape (2026-10-22)

- On feature 36b054d, user Windows root analyze clean, 40/40 root tests
  PASS, example analyze clean and debug GPU launched. The previous
  body/rightLeg overlap warning disappeared; only normal depth messages.
  Post-36b054d release smoke is still not shown.
- Screenshots reveal decorated cape texture is on the wrong side: the
  intended external face (with white 1) was not shown on the cape's
  world-facing -Z rear side. User provided cape reference and 64x32 PNG.
- `MtnMinecraftCapeBoxMesh.build()` now maps R2 atlas `front` source
  onto world rear (-Z) mesh face, and atlas `back` source onto world
  front (+Z) inner mesh face. Side/top/bottom unchanged; no hinge,
  pose or geometry rotation. Mesh UV tests explicitly lock the outer
  decorative face and inner face mapping, including UV corner order.
- Example R4 gallery now defaults local optional cape path to
  `D:\development\cross-platform\cape.png`, validates on startup and
  loads it if present; otherwise synthetic cape fallback. As before,
  only local file paths are committed, never skin/cape PNG bytes.
- Current source CI and real Windows cape rear/front/side orientation,
  Idle/Walk and post-fix release visual acceptance still pending.
  Keep feature PR #4 Draft and R4-D unstarted.

## R4-C horizontal mirror and outer-layer independence (2026-10-22)

- After Windows live smoke 7ba661e (41/41, analyzers clean, debug and
  release EXE launched), user screenshots showed the decorated cape '1'
  flipped horizontally and different cape appearance when toggling skin
  outer layers. No coplanar warning in this session.
- Prior front/back UV source swap remains correct for outward -Z facing
  cape, but the external face's horizontal UV corners must be flipped.
  New mapping swaps corners 0<->1 and 2<->3 ONLY for geometry back(-Z).
  Inner (+Z), top/bottom/edge faces, V, geometry and pivots untouched.
  Test coverage ensures decorated face + correct U mirroring.
- `Outer layers` never directly toggled the cape (separate node/pivot).
  Its skin alpha pass used renderOrder=1, while cape fabric defaulted
  to 0 and could therefore be composited underneath translucent shells.
  Example-only cape fabric now draws at renderOrder=2, keeping its
  independent visual presentation after shell overlays and retaining
  opaque depth occlusion. Check shoulder/arm realism and overlap in
  Windows before accepting this ordering tradeoff.
- Changes are R4-C-scoped and have not been live GPU-validated; current
  HEAD CI and Windows debug/release must complete before R4-D can begin.

## R4-C Windows closure and R4-D production viewer implementation

- User Windows acceptance on 029f4ac: root 42/42 PASS, root/example analysis
  clean, Windows debug GPU scene running, Windows release EXE built and
  launched; user image shows cape white 1 no longer mirrored, with no
  z-fighting warning. Feature HEAD R1/R2/R3/R4 CI all green.
- R4-D adds a public MtnMinecraftSkinViewer for already decoded R2 skin
  and optional cape objects. Model type comes only from skin.modelType.
  Controller owns camera only; pose, outer layers and cape visibility are
  widget props. No local test file paths, network, authentication or
  backend renderer classes exposed through the widget interface.
- flutter_scene 0.24.3 and vector_math are explicitly added to the root
  package as the Windows-validated GPU backend. Previous example-only
  renderer prototype and R4-C test gallery remain available.
- State generational guard prevents stale asynchronous GPU scene setup
  from becoming active; texture object swap rebuilds scene, while layer
  and pose changes reuse meshes; all scene resources, ticker and internally
  owned camera dispose at unmount. Caller-owned camera never disposed.
- R4-D example includes controls and a real 20-cycle mount/unmount and
  GPU frame-present stress loop; run it on Windows release, observe memory
  before/after and capture any exceptions/diagnostics. The button by
  itself cannot certify zero memory leaks without external measurements.
- **Updated Windows evidence:** exact-head f3ad33c root 46/46 tests PASS,
  root/example analyzers PASS, example regression 1/1 PASS, Windows debug
  GPU app and release executable successfully built/launched. All matching
  CI workflows SUCCESS. Interactive R4-D viewer controls, hot swaps and
  20x completed cycle with memory trend are not yet confirmed; these remain
  R4-D acceptance gates before any conditional merge.

## R4-D Windows evidence and single memory snapshot (2026-10-22)

- User feature f3ad33c: local Windows root tests 46/46 PASS, root/example
  analyzers clean, example widget test 1/1 PASS, Windows debug GPU built
  and launched, release build PASS and EXE launched.
- GitHub feature-head CI R1/R2/R3/R4 all SUCCESS (39750542501,
  39750542507, 39750542493, 39750542477; PR run 39750535419).
- Repeated 24-bit depth messages were informational, NOT a
  'surface overlap will flicker' warning. User-confirmed window-close
  disconnect is expected, not a crash.
- One process measurement: Private Memory 606.1 MB, Working Set 337.7 MB.
  No baseline, time-series, repeat-cycle completion, post-GC or GPU
  memory comparison supplied. This is neither evidence of a leak nor
  proof of bounded memory.
- Explicit R4-D interactive smoke (20/20, public viewer texture/model
  replacement, layer/cape separation, pose, camera, resize) and memory
  plateau still required. Keep Draft PR #4 unmerged.
