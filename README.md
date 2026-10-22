# Minecraft Skin Viewer

Reusable Minecraft Java Edition skin and cape previews for Flutter.

- Package: `mtn_minecraft_skin_viewer`
- Primary target: Windows desktop
- R1–R4: completed and merged into `main`
- R5: combined public-widget usage and documentation; Windows acceptance pending

## Public widgets

`MtnMinecraftSkinViewer` is the 3D player; `MtnMinecraftSkinPreview`
is a flat front/back full-body sprite; `MtnMinecraftSkinHead` is a flat
front/back avatar. `MtnMinecraftCapePreview` is available separately.

The caller supplies already-decoded skin/cape PNGs and explicitly selects
Classic or Slim. The package does **not** fetch accounts, player profiles,
files or network resources.

```dart
import 'package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart';

final skin = await MtnMinecraftSkinTexture.fromPng(
  skinPngBytes,
  modelType: MtnMinecraftSkinModelType.slim,
);
final cape = await MtnMinecraftCapeTexture.fromPng(capePngBytes);
```

Use the same texture instance in all three widgets:

```dart
// Inside a StatefulWidget build method:
MtnMinecraftSkinViewer(
  texture: skin,
  cape: cape,
  controller: camera,
  pose: walking ? MtnMinecraftSkinPose.walk : MtnMinecraftSkinPose.idle,
  showOuterLayer: showOuterLayer,
  showCape: showCape,
);
MtnMinecraftSkinPreview(
  texture: skin,
  height: 256,
  view: MtnMinecraftSkinView.front,
  showOuterLayer: showOuterLayer,
);
MtnMinecraftSkinHead(
  texture: skin,
  size: 64,
  showOuterLayer: showOuterLayer,
);
```

The 3D viewer needs bounded layout constraints and Flutter GPU enabled on
Windows. For development use `flutter run -d windows --enable-flutter-gpu`.
Validate Windows release builds and real GPU behavior separately.

### State ownership

`MtnMinecraftSkinViewerController` controls **only camera** orbit and zoom.
Its methods include `setOrbit`, `orbitBy`, `setDistance`, `zoomBy` and
`reset`. Keep `pose`, `showCape`, `showOuterLayer` and skin/cape selection
in Flutter widget state, then rebuild with new parameter values. This avoids
two competing sources of truth for pose or visibility.

Dispose a controller that your application creates (for example in
`State.dispose`). When no controller is supplied, the viewer owns its internal
controller and disposes it automatically. Skin/cape object identity changes
recreate the 3D scene; ordinary camera, pose and visibility changes do not.
Switching between `idle` and `walk` does not require rebuilding textures.

### 2D semantics

The 2D body is a straight-on 16×32 Minecraft sprite, not a perspective 3D
render. The head is an 8×8 avatar. Both support `front` and `back`, outer
layers and pixel-preserving nearest-neighbor sampling. Classic/Slim follows
`skin.modelType`; a PNG alone cannot reliably identify Slim arms.

The example's **R4-D public 3D viewer** gallery demonstrates all three
widgets together with shared texture, Classic/Slim switch, front/back,
outer-layer visibility and Idle/Walk controls. Its 20-cycle GPU mount/unmount
test remains a manual lifecycle aid, not proof of leak-free GPU memory.

## Development workflow

See `docs/WORKING_RULES.md` and
`docs/continuity/CURRENT_TARGET.md`. Changes require approved scope,
feature branch, Draft PR, targeted tests and actual Windows debug/release
smoke before live acceptance.
