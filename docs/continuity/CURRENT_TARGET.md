# Current target — R1 renderer foundation

Date: 2026-10-22
Repository: https://github.com/nusretm/minecraft_skin_viewer
Base branch: `main`
Feature branch: `feature/r1-renderer-foundation`

## Implemented in feature branch (unvalidated)

- Initial Flutter package metadata and library entrypoint `mtn_minecraft_skin_viewer`.
- `example/` app with a `flutter_scene 0.24.3` prototype (six cuboids in Classic proportions).
- Pointer drag orbit, mouse-wheel zoom and alpha-blended translucent head overlay toggle.
- Windows GitHub Actions workflow to analyze root/example and compile a release build after enabling GPU in generated runner.
- Repository rules, architecture, and checkpoint plan.

## Validation status

- **IMPLEMENTED (PARTIAL) / NOT VALIDATED**. Flutter and Dart SDK are unavailable to the assistant runtime; analyze, test and Windows binary build were not run locally.
- GitHub Actions workflow is configured but result is pending/not yet inspected.
- User's Windows debug and **direct executable release GPU rendering** are not validated.
- Texture UV mapping, nearest-neighbor filter smoke, error/dispose behavior over repeated mount/unmount remain to validate or implement.
- The root package currently exposes **no production widget API**; `flutter_scene` dependency is isolated in `example/`.

## Approved scope

- Independent package for Minecraft Java Edition 2D skin/cape previews and interactive 3D player model.
- R1 first: Windows GPU renderer feasibility, not full skin/cape UV mapping.
- Follow `R1_RENDERER_FOUNDATION.md`. Do not claim other platforms work without live evidence.
- Feature PR must not merge without explicit user approval.

## Next action

1. Inspect Windows GitHub Actions result, fix real build/analyze failures within R1.
2. On user's Windows Flutter 3.47.1+ environment, generate example runner and set GPU opt-in (see `example/README.md`).
3. Run debug/release visual smoke; test overlay toggle and repeated mount/unmount.
4. Add synthetic pixel texture + nearest-filter test, document its result.
5. Update this file with exact validation evidence and offer draft PR for user review.
