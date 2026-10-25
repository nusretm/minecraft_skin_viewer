# Minecraft Skin Viewer

A Flutter/Dart library for Minecraft Java Edition skin/cape textures, shared
UV layouts, and reusable 2D and 3D player widgets.

- Repository: nusretm/minecraft_skin_viewer
- Package: mtn_minecraft_skin_viewer
- First target: Windows desktop
- R1: GPU-backed 3D feasibility prototype in example/ (closed, Windows-verified).
- R2: PNG normalization and renderer-independent Classic/Slim/cape face UVs (closed, merged).
- R3: 2D head/body/cape Flutter widgets (closed, Windows-verified and merged).
- R4–R6: 3D viewer, public widget controller and Classic/Slim auto-detection merged.
- R7: Live breathing and four-way head glances under Windows review.

## R2 usage: atlas data only

~~~dart
import 'dart:typed_data';
import 'package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart';

Future<void> inspectSkin(Uint8List png) async {
  final skin = await MtnMinecraftSkinTexture.fromPng(
    png,
    modelType: MtnMinecraftSkinModelType.slim,
  );

  // Both modern 64x64 and legacy 64x32 inputs become 64x64 RGBA.
  final Uint8List pixels = skin.rgba;
  final uv = const MtnMinecraftSkinUvLayout(
    MtnMinecraftSkinModelType.slim,
  ).face(MtnMinecraftSkinBodyPart.head, MtnMinecraftSkinFace.front);

  print('Decoded RGBA bytes: ' + pixels.length.toString());
  print('Head face UV x/y: ' + uv.x.toString() + '/' + uv.y.toString());
}
~~~

The application provides its own PNG bytes. Since R6, the model may be inferred
from PNG pixels when `modelType` is omitted. Explicit Classic/Slim is still
supported for manual override. Detection is heuristic, not account metadata;
64×32 legacy skins default to Classic. The package does not fetch Minecraft
profiles or manage accounts.
A 64x32 cape is decoded via MtnMinecraftCapeTexture.fromPng, with pixel-space
rectangles from MtnMinecraftCapeUvLayout.

The coordinates describe an image with top-left origin; renderer adapters must
apply their own GPU UV origin and vertex-order conventions. R2 does **not**
yet display a real Minecraft skin on the R1 block character.

## Repository workflow

See docs/WORKING_RULES.md and docs/continuity/CURRENT_TARGET.md.
New implementation needs explicit scope approval and is developed in a feature
branch/Draft PR. After passing agreed validation, conditional merge authority
may be exercised under docs/WORKING_RULES.md.

## R3 2D widget example

```dart
MtnMinecraftSkinHead(texture: skin, size: 64, showOuterLayer: true);
MtnMinecraftSkinPreview(texture: skin, height: 256, view: MtnMinecraftSkinView.back);
MtnMinecraftCapePreview(texture: cape, height: 160);
```

Here `skin` and `cape` are R2 validated textures. In the Windows example,
use the app bar's R3 2D gallery button for a generated-atlas demonstration.

## R4-A six-face 3D UV smoke (feature branch)

The public `MtnMinecraftSkinBoxMesh.forBodyPart(part, modelType)` builds
renderer-neutral face-local vertices, normals and R2 atlas UVs.
From the example's R1 screen click `R4-A 3D UV gallery` (cube icon).
Orbit around the character and inspect synthetic corner markers on each
face, then switch Classic/Slim. This screen deliberately does NOT include
cape, outer layers, poses or the production 3D viewer. Windows debug/release
visual acceptance is pending; see `docs/continuity/R4_FULL_3D_VIEWER.md`.

## R4-B alpha-layer smoke (feature branch; Windows verification pending)

The example's R4 3D gallery now includes an **Outer layers** toggle,
synthetic semitransparent orange shell markers, and optional local Java
Minecraft skin PNG loading. The local file is not uploaded or cached.
Use Classic/Slim model selection; camera orientation/zoom is retained
while the GPU mesh scene is rebuilt. Outer geometry follows the shared
R2 UV layout and is independently expanded. Real cape, animation and
public 3D viewer remain R4-C/D.

## R4-C Windows example (feature, not live validated)

The 3D gallery uses D:\development\cross-platform\9fede215f7cb6884.png
as its local default skin when present/valid, selecting Slim; no fixture
binary is distributed, and CI uses synthetic PNG instead. The gallery
now supports a separate local Java 64x32 cape PNG, a generated fallback
cape, Cape toggle and Idle/Walk animation. R4-D public 3D viewer and GPU
resource benchmark remain separate.

### Local Windows cape test fixture (R4-C pending acceptance)

The example's 3D gallery tries `D:\development\cross-platform\cape.png`
alongside the optional local skin. Both PNG files are user-local and
are **not** checked into the repository. If unavailable, the example
generates a synthetic cape. The decorated atlas surface should render
on the cape's outward-facing rear (-Z); confirm visually in Windows
debug and release before R4-C closure.

## R5 — Three public widgets (feature branch; Windows validation pending)

`MtnMinecraftSkinViewerController` is the single 3D authority for
camera, Idle/Walk pose, outer layers and cape visibility. The host application
only provides a decoded R2 skin and optional cape texture; this package does
not fetch profile URLs, manage accounts or cache downloads.

```dart
final controller = MtnMinecraftSkinViewerController(
  pose: MtnMinecraftSkinPose.idle,
  showOuterLayer: true,
  showCape: true,
);

MtnMinecraftSkinViewer(
  texture: decodedSkin,
  cape: decodedCape, // optional
  controller: controller,
);

// UI events:
controller.setPose(MtnMinecraftSkinPose.walk);
controller.setShowOuterLayer(false);
controller.setShowCape(true);
controller.reset(); // camera only; does not reset pose or layers

// Dispose caller-owned controllers in the host widget's dispose().
```

The two 2D widgets do not need a controller and are already public:
```dart
MtnMinecraftSkinPreview(
  texture: decodedSkin,
  height: 256,
  view: MtnMinecraftSkinView.front,
  showOuterLayer: true,
);

MtnMinecraftSkinHead(
  texture: decodedSkin,
  size: 64,
  view: MtnMinecraftSkinView.front,
  showOuterLayer: true,
);
```

Use `MtnMinecraftSkinTexture.fromPng(bytes)` to decode, auto-select
Classic/Slim and normalize an input skin. Pass `modelType:` to override a
heuristic misclassification. Optional
`MtnMinecraftCapeTexture.fromPng(bytes)` requires 64×32 Java cape pixels.

Unlike the R4 public API, the R5 3D widget no longer accepts `pose`,
`showOuterLayer` or `showCape` constructor arguments. These state values
live **only** on its controller. Passing a controller means the caller owns and
disposes it; omitting one uses a widget-owned default controller.
Skin/cape object replacement rebuilds the GPU scene without resetting
the supplied controller; pose/visibility/camera changes do not re-upload meshes.
The example's R4-D button triggers 20 distinct GPU viewer mount/unmount
cycles, waiting for readiness and a rendered frame on each. Check
Task Manager/Process Explorer GPU/dedicated-memory trends externally
before claiming lifecycle stability. GPU opt-in required on Windows.

## Git-only package candidate (R5-C)

The next candidate is `0.1.0-dev.2`, not a published package.
A host Flutter project can **later**, after Windows R5 acceptance, pin
`mtn_minecraft_skin_viewer` as a Git dependency to an explicitly verified
commit SHA rather than a moving `main` reference:

```yaml
dependencies:
  mtn_minecraft_skin_viewer:
    git:
      url: https://github.com/nusretm/minecraft_skin_viewer.git
      ref: <verified-commit-sha>
```

This package's `pubspec.yaml` requires Flutter **3.47.1 or newer** and
uses `flutter_scene: 0.24.3`. The three public widgets are imported through
`package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart`.
Run 3D on Windows with Flutter GPU enabled (`--enable-flutter-gpu`) and
check the built release executable; 2D head/body widgets do not create GPU
scenes. Local example PNG fixture paths are optional and never bundled.

Changing 3D controller pose/layers/cape is an in-place presentation update;
changing the decoded skin/cape texture object reconstructs scene resources.
`onReady` and `onError` expose scene setup outcomes, while invalid PNG
input raises a `FormatException` during `fromPng`. No network, accounts,
cache, launcher integration, pub.dev upload or release binaries are owned
by this package. See `CHANGELOG.md` and
`docs/continuity/R5_PUBLIC_WIDGET_API.md`.

## R6 — Automatic model inference

```dart
final skin = await MtnMinecraftSkinTexture.fromPng(pngBytes); // auto
final forced = await MtnMinecraftSkinTexture.fromPng(
  pngBytes, modelType: MtnMinecraftSkinModelType.slim); // override
```

Modern 64×64 skins use the alpha and black/white unused-arm-region heuristic
adapted from [skinview-utils](https://github.com/bs-community/skinview-utils/blob/master/src/process.ts)
(MIT; see `docs/third_party/SKINVIEW_UTILS_LICENSE.md`). Legacy 64×32 defaults
to Classic. PNG pixels cannot prove the original Minecraft account model;
manual override remains available. No API, network or dependency is needed to
detect the model, and the same decoded texture works in 2D and 3D.

## R7 — Living character (merged via PR #8)

`MtnMinecraftSkinViewerController()` now defaults to `MtnMinecraftSkinPose.live`.
Live gently opens the shoulders while inhaling and closes them when exhaling;
the head periodically looks left/right/up/down and returns to center after a
random 1–4-second hold. The camera is independent.

```dart
final controller = MtnMinecraftSkinViewerController(); // Live by default
MtnMinecraftSkinViewer(texture: skin, controller: controller);

controller.setPose(MtnMinecraftSkinPose.idle); // static pose
controller.setPose(MtnMinecraftSkinPose.walk); // limb animation
controller.setPose(MtnMinecraftSkinPose.live); // breathing + glances
```

Live and Walk reuse the viewer's existing ticker. Skin/cape textures are not
re-uploaded when changing pose; 2D previews remain still. Dispose a controller
you create yourself. See `docs/continuity/R7_LIVE_CHARACTER_ANIMATION.md`.

## R7-F1 — 3D skin edge quality (Windows verification pending)

The GPU 3D viewer now uses a very small per-face atlas UV inset to reduce
neighboring texel sampling at cube edges, while canonical skin UVs remain
unchanged for 2D previews and atlas tests. Its Scene selects
`AntiAliasingMode.smaa` by default to preserve visually smooth character
edges without the zoom-dependent hairlines seen under automatic AA.
This follows an accepted Windows test with SMAA explicitly enabled. No
`--dart-define` flags are needed by callers and none of the temporary
R7-F1 diagnostic flags remain. The extra GPU cost of SMAA has not been
measured; final no-define Windows release confirmation is pending.
See `docs/continuity/R7_F1_RENDER_SEAM_FIX.md`.
