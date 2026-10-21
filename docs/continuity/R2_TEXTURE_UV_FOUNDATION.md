# R2 — Java Skin/Cape Texture & UV Foundation

**Date:** 2026-10-22
**Status:** APPROVED / IMPLEMENTED ON FEATURE / CI VALIDATION PENDING
**Branch:** `feature/r2-skin-texture-uv-foundation`
**Base:** `main` at `8a8bb2c`
**Merge:** Not authorized.

## Authorized scope

- **R2-A:** Accept only modern 64x64 and legacy 64x32 Java PNG skins and
  64x32 Java capes. Validate signature/IHDR and decode into straight RGBA8888.
  Normalize legacy to a 64x64 skin atlas, mirrored face by face.
- **R2-B:** Shared render-backend-independent box-face UV rectangles, geometry
  dimensions, Classic/Slim arms, and inner/outer layers. Cape is a 10x16x1
  UV net with a 64x32 atlas.
- **R2-C:** Deterministic synthetic PNG fixtures/tests, Windows CI regression
  verification, and renderer integration contract.

## API

- `MtnMinecraftSkinTexture.fromPng(bytes, modelType: ...)` yields a normalized
  64x64 RGBA snapshot, `isLegacy`, a defensive `rgba` copy and
  `rgbaAt(x,y)` packed 0xRRGGBBAA.
- `MtnMinecraftCapeTexture.fromPng(bytes)` yields a verified 64x32 RGBA image.
- `MtnMinecraftSkinUvLayout(modelType)` maps six body parts x base/outer x
  six faces; `dimensions(part)` provides pixel dimensions.
- `MtnMinecraftCapeUvLayout().face(face)` maps 64x32 Java cape box faces.
- `MtnMinecraftSkinUvRect` exposes pixel bounds, local `pixelAt`, orientation
  and top-left-origin normalized UV corners.

All types are exported through `lib/mtn_minecraft_skin_viewer.dart`.

## Important data rules

- Model type is explicit, not inferred from transparent pixels or dimensions.
- Legacy left arm/leg need twelve independent horizontally mirrored rectangles.
  Mirroring the entire original limb net would interchange wrong face regions.
- Base-layer used face texels are forced opaque; outer-layer alpha is preserved.
- A fully opaque legacy input clears the old hat background, while modern
  opaque overlays are not silently removed.
- Skin UVs use a canonical 64x64 atlas even when source was legacy 64x32.
  Bottom-face orientation is flipped vertically in face-local image space.
- GPU adapters must account for bottom-left UV origin and their vertex order;
  neither 2D nor 3D renderer should calculate its own Minecraft atlas offsets.
- No account, network, cache or external texture downloads.
- Only 64x32 Java cape is supported in R2; HD/Bedrock/22x17/46x22 are excluded.

## Integration contract (R3 / R4 later)

```dart
final skin = await MtnMinecraftSkinTexture.fromPng(
  pngBytes, modelType: MtnMinecraftSkinModelType.slim);
final uv = const MtnMinecraftSkinUvLayout(MtnMinecraftSkinModelType.slim)
    .face(MtnMinecraftSkinBodyPart.rightArm, MtnMinecraftSkinFace.front);

// R3: crop a 2D Flutter image using uv.x/y/width/height.
// R4: upload skin.rgba to a 64x64 GPU texture; consume
// uv.normalizedCorners(64, 64) with the backend's vertex order and V origin.
```

R2 does **not** replace the R1 demo with a fully textured character and does
not add production 2D/3D widgets. Keep `flutter_scene` inside `example/`.

## Verification and residual risks

- Tests exercise Classic/Slim UV, six faces, layer bounds, cape, PNG errors,
  legacy mirroring and alpha semantics with generated RGBA PNG fixtures.
- CI on Windows must run root `flutter analyze` and `flutter test`,
  regression-test the GPU-independent R1 controls and compile example release.
- GitHub CI is **not** a substitute for live UV-render visual smoke in R3/R4.
- R1 deferred controlled GPU memory soak remains open.
- Draft PR required and **no merge** until explicit user approval.

## Coordinate reference comparison

- https://github.com/bs-community/skinview3d/blob/master/src/model.ts
- https://github.com/bs-community/skinview-utils/blob/master/src/process.ts

Only behavior/coordinate conventions were consulted. No source or assets were copied.
