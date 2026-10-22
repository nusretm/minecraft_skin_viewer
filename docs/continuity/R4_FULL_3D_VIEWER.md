# R4 — Full 3D Minecraft Java Viewer

Date: 2026-10-22
Status: USER APPROVED R4-A/B/C/D / ONLY R4-A IMPLEMENTED ON FEATURE /
        CI + REAL WINDOWS GPU UV SMOKE PENDING
Feature branch: feature/r4-full-3d-skin-viewer
Base main: bb32bcb86c14fca60aa62f03279ca1c2041284f0

## Approved plan and sequencing

- R4-A **CURRENT**: Backend-neutral 24-vertex/36-index cuboid mesh data,
  source-of-truth R2 six-face UV mapping, Classic/Slim sizes, standing pose
  part centers, synthetic Windows GPU atlas-face smoke and automated tests.
- R4-B **NOT STARTED**: Independently offset outer-layer geometries, their
  face UVs and alpha handling, Classic/Slim real full skin appearance.
- R4-C **NOT STARTED**: 64x32 cape geometry+UV with back hinge, simple
  shoulder/hip pivots and idle/walk basic poses; no cloth physics.
- R4-D **NOT STARTED**: Public MtnMinecraftSkinViewer (3D), working
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
