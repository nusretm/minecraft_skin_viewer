# Current target — R1 renderer foundation

Date: 2026-10-22
Repository: https://github.com/nusretm/minecraft_skin_viewer
Base: `main`
Working branch: `feature/r1-renderer-foundation`

## Actual repository state

- `main` initialized with README; this branch was created for first checkpoint work.
- R1 engineering rules, architecture, and work scope documented.
- Flutter package source, example app, GPU renderer and assets: **NOT YET IMPLEMENTED**.
- Windows debug/release builds, analyze, tests and live smoke: **NOT RUN**.
- Flutter SDK is unavailable in the ChatGPT tooling environment; Windows validation requires the user's Windows Flutter development environment.

## Approved scope

- Package goal: 2D skin/cape previews and interactive 3D character, independent from player accounts/network.
- Immediate work: R1 renderer feasibility only, per `R1_RENDERER_FOUNDATION.md`.
- Keep `flutter_scene` initially isolated in example, track its pre-1.0 API changes.
- Do not merge PR without explicit user acceptance/approval.

## Next action

On the user's Windows Flutter environment, clone/check out `feature/r1-renderer-foundation`, initialize Flutter package and Windows example app, follow `R1_RENDERER_FOUNDATION.md`, run debug/release GPU smoke, then update this file with actual evidence and submit draft PR.
