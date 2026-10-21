# Architecture — Minecraft Skin Viewer

Status: R1 CLOSED and user live-validated; R2 approved and implemented on feature, pending test review.

## Scope

One Flutter package: `mtn_minecraft_skin_viewer` in repository `nusretm/minecraft_skin_viewer`. A single-technology Flutter repository uses package-standard root `lib/`, `test/` and `example/`, plus root `docs/`; do not introduce empty `rust/`, `dart/` or `ui/` directories.

## Ownership boundaries

1. **Input data / texture representation**: image bytes, decoded pixel data, original PNG dimensions, decode/validation errors.
2. **Minecraft mapping**: Classic vs Slim geometry dimensions; 64x64 and legacy 64x32 UV/overlay layout; cape layout. Explicit model type input.
3. **2D renderer**: head and body previews rendered with Flutter primitives from the common atlas model.
4. **3D geometry and render adapter**: character parts, local transforms, camera/gesture interaction; texture/UV data is not owned by Flutter Scene-specific public classes.
5. **Public widget layer**: later `MtnMinecraftSkinHead`, `MtnMinecraftSkinPreview`, `MtnMinecraftSkinViewer`, and `MtnMinecraftCapePreview`. These names are targets, not currently implemented contracts.

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
