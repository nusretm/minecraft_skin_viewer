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
