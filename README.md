# Minecraft Skin Viewer

A Flutter/Dart library for Minecraft Java Edition skin/cape textures, shared
UV layouts and (in later checkpoints) reusable 2D and 3D player widgets.

- Repository: nusretm/minecraft_skin_viewer
- Package: mtn_minecraft_skin_viewer
- First target: Windows desktop
- R1: GPU-backed 3D feasibility prototype in example/ (closed, Windows-verified).
- R2: PNG normalization and renderer-independent Classic/Slim/cape face UVs (closed, merged).
- R3: 2D head/body/cape Flutter widgets (closed, Windows-verified and merged).
- R4: 3D viewer approved; R4-A mesh UV prototype on feature branch, R4-B/C/D not yet implemented.

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
