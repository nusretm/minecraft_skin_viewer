# R7-F1 — 3D Skin UV Seam / Hairline Artifact

**State:** APPROVED / implementation in feature branch; Windows visual verification pending.
**Date:** 2026-10-25
**Repository:** `nusretm/minecraft_skin_viewer`
**Base HEAD:** `ca4e97b62c909a0ac4e1984e68799953c6ad6b3f` (`main`)
**Feature:** `feature/r7-f1-render-seam-fix`

## User report / target

Screenshots from real Minecraft Slim skin and the MTN Launcher integration show very thin seams around character head and arm edges. With outer layer disabled there is still a small upper-right head artifact; with outer enabled, fine seams appear on additional head intersections and at sleeve top/bottom. This establishes a recurring visual issue, not yet its proven root cause.

## Inspected existing behavior

- `MtnMinecraftSkinUvRect.normalizedCorners()` returns exact pixel-space face boundaries divided by atlas size (64x64).
- `MtnMinecraftSkinBoxMesh.forBodyPart()` generates six quads, each with its own four vertices, face-local TL/TR/BR/BL UVs, matching the canonical R2 atlas.
- `MtnMinecraftSkinViewer` already uses `TextureSampling(mipmaps:false, minFilter:nearest, magFilter:nearest, maxAnisotropy:1)`. Avoid speculative filter/dependency changes.
- Outer skin geometries are already inflated by 0.5 model pixels per side for head and 0.25 for body/sleeves/legs; renderer already applies different `depthLayer` priorities. Do not arbitrarily modify them.
- The working hypothesis is sampling exactly at a UV face boundary can fetch a neighbor atlas texel on pixel rounding. A second depth/alpha cause is possible; neither is confirmed without Windows before/after screenshots.

## Scope of first checkpoint — GPU sampling-only UV inset

- Pure mesh `texCoords` remain unchanged as the canonical R2 value; 2D renderer and source UV mapping are untouched.
- Provide opt-in `MtnMinecraftSkinBoxMesh.texCoordsWithInset(insetTexels:0.02)`: a fresh 3D sampling buffer nudged into each face by 0.02 texels per edge. Match each existing face's V orientation (the Minecraft bottom face reverses V). Reject nonfinite, negative, or >= 0.5 texel input. Zero preserves exact corners.
- The 3D viewer passes this buffer to GPU mesh upload for both base and outer layers, without new textures, animation/controller changes or extra GPU resources. Geometric positions, triangle winding, inflated shells, outer material alpha/depth and cape atlas remain unchanged.
- Focused unit tests verify every base/outer Classic/Slim part and face samples its own edge pixel, the R2 canonical UV data are unchanged, the inverted bottom-face orientation is respected and outer geometry is unaffected.
- Existing Windows example R7 gallery already supports toggling outer on/off, orbit, zoom and Idle/Live/Walk. No separate UI settings/API/debug control unless the first visual test proves one necessary.

## Windows validation gate

1. `flutter analyze --no-pub`; focused mesh/outer tests; `flutter test --no-pub test/`; example analyzer/tests. `git diff --check` and code diff review.
2. Windows debug `flutter run -d windows --enable-flutter-gpu` using the user's existing real Slim PNG, compare matched camera angles before/after.
3. With outer off: check right-top head edge; with outer on: check all head face intersections and both arm top/bottom edges, across front/oblique camera positions and Live/Idle.
4. Check Classic/Slim, head/skin 2D unaffected, cape, camera orbit/zoom, texture reload, and disposal. Test release build **and direct EXE interactive visual** prior to LIVE_VALIDATED claim.
5. If seams remain, do not silently increase shell inflation or change `depthLayer`/alpha mode. Review artifact geometry and plan separate targeted depth/alpha follow-up within this user-approved checkpoint, with another visual check.

## Out of scope / risk

No `mtn_launcher_app` changes, R7 animation changes, new dependencies, SDK upgrade, global UV atlas edits, shader overhaul or publication. Small inward UV nudge may not fix a screen-space rasterization gap; acceptance is based on actual Windows GPU output. Four previously noted generated Windows/lockfile local user edits are not touched. PR remains Draft until live visual result and acceptance.

## 2026-10-25 — Real Windows GPU feedback: sampling improvement, distant head artifact remains

- User checked out the feature branch and ran root `flutter analyze --no-pub` **PASS**, `flutter test --no-pub test/` **67/67 PASS**, example analyzer **PASS**, Windows debug `flutter run -d windows --enable-flutter-gpu` build/launch **PASS**, Impeller (OpenGLES) confirmed. The normal `flutter_scene` 24-bit reversed-depth note appeared; `Lost connection to device` after closing is not evidence of an application crash.
- PR #9 feature-head `52634ea302e2adbd9bb28b5f25c7164927d61f90` completed all four Windows CI checks **SUCCESS**. The user's local changed files at this stage are `example/.metadata` and `example/pubspec.lock`; neither belongs in the feature.
- Visual verdict: fine line on right arm remains barely visible, but head / outer head lines become *more* noticeable when zooming out. UV inset improves one part of the symptom but does **not** resolve the issue or prove the original hypothesis was the complete cause.
- New possible cause: anti-aliasing or final scene compositing at small on-screen character sizes. `flutter_scene` can use MSAA or FXAA depending on GPU support, and `Scene.filterQuality` controls final output scaling. Neither is changed by default.
- **Stage B opt-in diagnostic only**, in `mtn_minecraft_skin_viewer_3d.dart`: `MTN_SKIN_SEAM_DISABLE_AA=true` forces `AntiAliasingMode.none`; `MTN_SKIN_SEAM_NEAREST_COMPOSITE=true` forces `FilterQuality.none`. Both must be invoked with `--dart-define`, can be tested independently and together, and have zero effect on regular builds. This is not yet a committed production fix to alpha or depth.
- Next user Windows GPU A/B at matched camera angles / zoom distances, with outer on/off:
  1. Unmodified baseline: `flutter run -d windows --enable-flutter-gpu`.
  2. AA off: `flutter run -d windows --enable-flutter-gpu --dart-define=MTN_SKIN_SEAM_DISABLE_AA=true`.
  3. Final canvas sampling nearest: `flutter run -d windows --enable-flutter-gpu --dart-define=MTN_SKIN_SEAM_NEAREST_COMPOSITE=true`.
  4. Both toggles can be tried together if either test is inconclusive.
- Interpret carefully: if AA-off removes head lines but adds staircase edges, tune antialiasing rather than depth. If composite nearest helps at distances, focus output downscale. If neither changes behavior, investigate partially transparent outer shell sorting (blended material) or adjacent cube-face rasterization/depth, without blindly inflating geometry. Do not claim that a compile-time diagnostic resolves the artifact.
- Current exact-head CI must rerun after stage B change. PR remains Draft pending GPU visual evidence. Release EXE interactive visual smoke not yet observed for R7-F1.


## 2026-10-25 — A/B root-cause isolation: AA-related hairlines

- **User Windows A/B:** setting `MTN_SKIN_SEAM_NEAREST_COMPOSITE=true` leaves fine head lines visible; setting `MTN_SKIN_SEAM_DISABLE_AA=true` removes the lines. This strongly isolates the artifact to the active anti-aliasing stage (rather than proving physical outer shell depth/z-fighting), especially when zoomed out. This does not yet identify whether auto picked MSAA or FXAA on that specific device.
- `flutter_scene` 0.24.3 supports `AntiAliasingMode.smaa`; its documentation says SMAA preserves texture details more than FXAA at a higher postprocess cost. Final comparison added as opt-in `--dart-define=MTN_SKIN_SEAM_SMAA=true`; explicit no-AA has priority if both are set. The production default remains unchanged during diagnostic comparisons.
- Next decision: test SMAA at the same camera distance and outer-layer setting. If no seams and pleasing edge quality, consider SMAA despite three postprocess passes; if seams persist or cost is unnecessary, make `AntiAliasingMode.none` the viewer-only default to respect Minecraft pixel-art, preserving current UV inset. No global renderer, controller or upstream SDK setting should be changed without a measured reason.
- Release smoke, exact latest-head CI and final A/B choice remain pending. PR #9 stays Draft; no merge yet.


## 2026-10-25 — Final A/B decision: select SMAA for viewer only

- After user confirmed that `MTN_SKIN_SEAM_NEAREST_COMPOSITE` did not help and `MTN_SKIN_SEAM_DISABLE_AA` removed the seams, the user tested `MTN_SKIN_SEAM_SMAA=true` and explicitly reported `🥳 şahane görünüyor`. Treat this as **SMAA trial visually accepted** on Windows. The specific user comment did not independently report final default build/release behavior or GPU memory.
- Production 3D scene now sets `AntiAliasingMode.smaa` at scene creation with no caller setting or dart defines. Remove all R7-F1 temporary anti-aliasing/nearest-composite diagnostic flags so shipped behavior matches the successful SMAA experiment. R2 canonical UVs and the prior GPU-only sub-texel inset are unchanged. All cape/layer depth/material, Live/Walk/Idle and 2D widgets are unchanged.
- Expected additional SMAA postprocessing expense remains an **unmeasured performance tradeoff**. Root analyzer, 67 existing tests and example analyzer passed in the *previous* UV-inset branch; exact current-head CI and no-define Windows debug/release checks remain **PENDING**.
- Merge/closure: do not equate successful earlier A/B render with final-head release visual smoke. Draft PR #9 is open until applicable verification and user/authorized gate. No generated/lockfile changes are included.
