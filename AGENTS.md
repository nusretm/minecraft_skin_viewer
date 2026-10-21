# Minecraft Skin Viewer — Agent Instructions

**Repository:** `nusretm/minecraft_skin_viewer`
**Package:** `mtn_minecraft_skin_viewer`
**Authoritative policy:** `docs/WORKING_RULES.md`
**Active handoff:** `docs/continuity/CURRENT_TARGET.md`

Before doing **anything** in this repository:

1. Read `docs/WORKING_RULES.md` in full.
2. Read the newest entry in `docs/continuity/CURRENT_TARGET.md`.
3. Read `docs/continuity/ARCHITECTURE.md` and the specific active checkpoint document (currently `R2_TEXTURE_UV_FOUNDATION.md`); read `PLANNED_*.md` only when relevant.
4. Verify branch, HEAD, worktree status and existing PR/CI state before proposing changes. Continuity is a handoff, not proof that source, tests or CI succeeded.

## Approval and integration gate

- Do not implement, refactor, introduce dependencies or change a second repository without **explicit user approval for that scope**. A plan, request for review or green test is not such approval.
- Single integration path: **feature branch → Draft PR → Windows analysis/tests/actual UI smoke → user acceptance + explicit merge approval → squash merge → verify main → continuity closure and local branch cleanup**.
- After a checkpoint is accepted and merge-approved, complete its merge and verify current `main` before starting unrelated implementation. Do not accumulate conflicting PRs or silently merge.
- Protect local/uncommitted user data. No force push, broad deletion, or unrelated changes without approval.

## Architecture and code hygiene

- One independent Flutter/Dart rendering package. Use common texture/atlas, geometry and pose concepts so 2D and 3D renderers share authoritative data; isolate backend-specific GPU code.
- This repository does **not** own `minecraft_accounts` authentication, `mtn_launcher_app` application shell, `mtn_launcher` orchestration, or `minecraft_tools` domain services. Inspect proven upstream contracts before integration; do not duplicate them.
- Use `Abs` for abstract class names, `Base` for concrete shared bases, and preserve the class-family prefix for specializations. Keep domain behavior out of widgets and avoid speculative infrastructure.
- Windows desktop first. A successful build or CI analysis does not prove a working GPU scene, Minecraft UV mapping, transparency, or lifecycle safety. Require actual Windows debug and release-executable smoke evidence for R1 `LIVE_VALIDATED`.
- Do not automatically run `dart format` on pure Dart code. Do not automatically run `flutter upgrade` or alter developer toolchains; the user controls upgrades.
- Update `CURRENT_TARGET.md` **in the same checkpoint** with factual dates, branch/PR/commit references, checks passed/failed/not run, unresolved issues, deferred work and next action. Never turn a proposed feature into an implemented claim.

These rules adapt the project-wide workflow of `nusretm/mtn_launcher_app/docs/WORKING_RULES.md` to this independent renderer. That repository's `main` had no `AGENTS.md` at adaptation time; this file is a concise companion to the authoritative working rules, not an exact copy.
