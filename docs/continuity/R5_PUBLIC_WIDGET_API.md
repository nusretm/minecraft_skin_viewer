# R5 — Public Widget API Finalization (Approved Scope)

Date: 2026-10-22
Repository: nusretm/minecraft_skin_viewer
Base: main at f21d3dd382a8b80d4f64a9a1827bc8fe83b90c09
Feature: feature/r5-public-widget-controller-api
State: APPROVED — R5-A/B/C implemented on Draft PR #5, CI and actual Windows GPU/2D visual validation PENDING, unmerged.

## User requirement
No launcher integration here. Expose independent reusable widgets to be composed in mtn_launcher_app in a *separate project*, with already decoded textures supplied from the host:
1. MtnMinecraftSkinViewer — 3D skin/cape with a controller able to drive Idle/Walk, layer/cape toggles and camera.
2. MtnMinecraftSkinPreview — 2D body.
3. MtnMinecraftSkinHead — 2D avatar.

MtnMinecraftCapePreview remains an existing public export but is not one of the three required widgets.

## R5-A — Controller authority (IMPLEMENTED; Windows acceptance pending)
- MtnMinecraftSkinViewerController owns pose, showOuterLayer, showCape and orbit/zoom state.
- Constructor defaults: pose=idle, outer=true, cape=true. Methods setPose, setShowOuterLayer, setShowCape; notify only for changes. Camera reset is camera-only.
- No duplicated pose/layer/cape arguments on MtnMinecraftSkinViewer; no duplicate example UI state.
- Walk ticker starts/stops on pose changes. A camera change must not restart Walk. Visibility toggles never recreate GPU meshes/textures; texture/cape object swaps do.
- Lifecycle: listener unsubscribe and correct caller-owned vs internally owned controller disposal; controller replacement while mounted; rapid changes during async scene init; Idle redraw remains demand-driven.
- Gates: root + example Flutter analyzer, controller tests, full regression, GitHub Windows CI, real Windows GPU debug/release with Idle↔Walk and cape/outer toggles.

## R5-B — 2D API and regression (IMPLEMENTED; Windows acceptance pending)
- Verify MtnMinecraftSkinPreview and MtnMinecraftSkinHead using supplied MtnMinecraftSkinTexture and optional outer layer/front-back/size-height props. No controller for 2D.
- Test Classic/Slim explicit model, legacy 64x32, skin texture replacement, alpha/nearest behavior, resize and dispose. Keep existing MtnMinecraftCapePreview functional.
- Demonstrate all three widgets together in an example without any accounts, network or launcher dependency.
- Gates: focused widget/PNG tests and Windows visual smoke.

## R5-C — Documentation and package readiness (IMPLEMENTED; validation pending)
- Public API exports and usage examples, controller ownership/lifecycle, GPU opt-in and minimum Flutter version, error/loading contract, changelog/version policy and reproducible Windows validation instructions.
- Verify dependency resolution with current project Flutter SDK, required GPU backend and 2D functionality; do not upgrade Flutter automatically.
- Only a Git-pinned dependency ready for later launcher integration; pub.dev publishing, signed release workflow, online skin downloads, caching and all launcher code are explicitly OUT OF SCOPE.
- Gates: clean `flutter analyze --no-pub`, full `flutter test --no-pub test/`, example tests, Windows debug/release GPU smoke, `git diff --check`, clean feature checkout, CI and user acceptance before squash merge.

## Risk/deferred
The R4 post-stress CPU process Private memory fell from 768.6 MB to 515.3 MB after 60 seconds Idle, but direct GPU dedicated/shared memory was not sampled. Do not claim zero GPU leaks. Retain the 20× stress harness to recheck controller-switch transitions and frame pacing, avoid broad refactors and unnecessary new dependencies.

## Source-of-truth
Existing docs/WORKING_RULES.md; docs/continuity/CURRENT_TARGET.md most recent entries; PR in this feature; Windows user results. Do not rewrite R4 historical evidence.

## Implementation evidence and acceptance still needed

- R5-A feature commit `02a3610` and controller tests `993578f`: single authority for 3D pose, layers, cape and camera, reactive UI updates; no GPU uploads for controller state changes. R4-D gallery toggles through controller and controls listen for changes.
- R5-B `325f7ca` 2D body regression and `5f7f24f` R4-D gallery side-by-side 2D/3D rendering from the same decoded texture. Head/body code itself unchanged.
- R5-C `4b1f3cc` pre-stable package `0.1.0-dev.2` and CHANGELOG. No pub.dev release, new dependency or automatic SDK upgrade.
- Draft PR #5 includes all changes. Windows full CI, real example head/body and GPU 3D user screenshot with pose/layer/cape controls, actual debug/release and stable camera+texture swap, and release 20× stress recheck are not yet supplied. Do not mark CLOSED or merge based solely on code commits.
