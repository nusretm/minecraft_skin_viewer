# Minecraft Skin Viewer

A Flutter/Dart library for Minecraft Java Edition skin/cape textures, shared
UV layouts and (in later checkpoints) reusable 2D and 3D player widgets.

- Repository: nusretm/minecraft_skin_viewer
- Package: mtn_minecraft_skin_viewer
- First target: Windows desktop
- R1: GPU-backed 3D feasibility prototype in example/ (closed, Windows-verified).
- R2: PNG normalization and renderer-independent Classic/Slim/cape face UVs (closed, merged).
- R3: 2D head/body/cape Flutter widgets (closed, Windows-verified and merged).
- R4: R4-A/B/C Windows verified; R4-D public 3D widget and lifecycle harness implemented on feature, validation pending.

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

The application provides its own PNG bytes and selects Classic or Slim
explicitly. The package does not fetch Minecraft profiles or manage accounts.
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

## R4-D public 3D widget (feature; Windows live review pending)

```dart
MtnMinecraftSkinViewer(
  texture: decodedSkin,
  cape: decodedCape, // optional
  showOuterLayer: true,
  showCape: true,
  pose: MtnMinecraftSkinPose.idle,
  enableInteraction: true,
)
```

Use pre-decoded R2 skin/cape objects; no file paths or network in public
widget. Optional `MtnMinecraftSkinViewerController` owns orbit/zoom and
can be retained through skin/model changes. The caller owns and disposes
a supplied controller, otherwise the widget manages one internally.
The example's R4-D button triggers 20 distinct GPU viewer mount/unmount
cycles, waiting for readiness and a rendered frame on each. Check
Task Manager/Process Explorer GPU/dedicated-memory trends externally
before claiming lifecycle stability. GPU opt-in required on Windows.
