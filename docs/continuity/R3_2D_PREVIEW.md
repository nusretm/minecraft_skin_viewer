# R3 — 2D Minecraft Skin and Cape Preview

Date: 2026-10-22
Status: CLOSED / PR #3 SQUASH MERGED / WINDOWS DEBUG+RELEASE FUNCTIONALLY VALIDATED
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

## Closure — 2026-10-22

- User reported the 2D gallery and all interactive controls work on Windows,
  after debug run and successful release build/executable launch. Head/body/cape
  visual confirmation was functional, but no long GPU memory soak was measured.
- Root `flutter analyze --no-pub` clean and `flutter test --no-pub test/`
  **22/22 PASS**. Example analyzer clean, GPU-independent controls test
  **1/1 PASS**, Windows release build **PASS**.
- R1, R2 and R3 Actions workflows for final feature source SHA `dfb02af0`
  all green; notably R3 runs `39696653054`, `39696646453`, including
  pixel-level rendering checks, R1 regression and release compilation.
- User's debug log also contained `Lost connection to device`; it is unclear
  whether this was ordinary session termination or an unexpected disconnect.
  No further debug-session stability claim is made from the log alone.
- PR #3 squash merged as `3c4a56f4ca126ecbeb857e8e58f6dbf8755b0d56`.
  Full textured 3D character and resource soak remain deferred to future work.
