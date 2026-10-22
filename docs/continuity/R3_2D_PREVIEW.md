# R3 — 2D Minecraft Skin and Cape Preview

Date: 2026-10-22
Status: APPROVED / IMPLEMENTED ON FEATURE / CI AND WINDOWS LIVE GALLERY PENDING
Branch: feature/r3-2d-skin-cape-preview
Base main: 649327353b004add6c31167842555841dbc30283

## User-approved scope

- MtnMinecraftSkinHead(texture:, size: 64, view: front/back, showOuterLayer: true)
- MtnMinecraftSkinPreview(texture:, height: 256, view: front/back, showOuterLayer: true)
- MtnMinecraftCapePreview(texture:, height: 256, view: back/front)
- MtnMinecraftSkinView.front and .back.
- Use R2 validated skin/cape RGBA and R2 UV face rectangles as the sole
  Minecraft atlas authority. Body is 16x32; head is 8x8; cape is 10x16.
- Support Classic 4px and Slim 3px arms, legacy 64x32 normalized skin,
  outer-layer visibility, nearest-neighbor sampling at large/small sizes.

## Implementation

- Flutter CustomPainter and drawImageRect with FilterQuality.none.
- Private stateful image holder caches one image by texture object identity;
  view/layer/size changes do not upload the image again.
- Convert R2 straight RGBA into premultiplied RGBA for Flutter's raw
  ui.ImageDescriptor to avoid transparency halo/artifact behavior.
- Dispose decoded ui.Image on widget removal/replacement; invalidate pending
  asynchronous decode completions using generation tokens.
- Example retains existing R1 3D scene and adds the top-right "R3 2D gallery"
  button to display synthetic Classic/Slim, front/back, overlays, legacy and
  cape in a resize-friendly Wrap/scrollable layout.
- No new dependency or change in other repositories. R1 3D GPU renderer
  and R2 model semantics are unchanged.

## Acceptance gates

1. Root flutter analyze, flutter test (including pixel-capture fixture tests).
2. Front/back head, body, cape pixel correctness; left/right reversal from
   back, Classic/Slim arm width, legacy mirrored left limbs.
3. Outer-layer toggle, texture replacement, widget mount/unmount and
   32/64/128/256px nearest-neighbor scaling.
4. Example analyzer and R1 controls regression, Windows release build.
5. User Windows debug/release visual inspection of the R3 gallery, resizing,
   toggles, pixel sharpness and absence of obvious resource errors.
6. PR diff/checks and continuity accuracy. No merge until criteria met.

## Explicit exclusions

- Actual Minecraft skin textured 3D body, capes attached to 3D models,
  animation and controller belong to R4.
- Account/network/storage integrations, arbitrary HD/Bedrock skin formats
  and GPU long-run leak-free claims are excluded.
- R1 GPU memory soak remains a separately tracked deferred risk.

CI or code creation without observed results is NOT a passing test.
