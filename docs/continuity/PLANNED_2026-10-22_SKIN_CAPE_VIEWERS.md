# Planned — Shared 2D & 3D Minecraft Skin/Cape Viewer

**Date:** 2026-10-22
**Repository:** `nusretm/minecraft_skin_viewer`
**Status:** R1/R2/R3 CLOSED / MERGED; R4–R5 PROPOSED / NOT APPROVED.
**Dependencies:** R1, R2 and R3 squash-merged. R4/R5 need separate feature approval.

## Goal

Build an independent Flutter package for modern and legacy Minecraft Java skins, head/body 2D previews, cape previews, and interactive 3D full-character rendering; consume provided PNG bytes without owning accounts, token flows, profile lookups, or network caching.

## Ownership and boundaries

- Common texture decode and validated atlas/UV mapping authority independent from all widgets and GPU backends.
- 64x64 modern, 64x32 legacy skin atlas; Classic 4-pixel / Slim 3-pixel arms selected from explicit model metadata, not inferred from PNG dimensions.
- Java cape layout support with input validation. Do not assume arbitrary HD/Bedrock formats or cape physics are first-release capabilities.
- 2D Flutter-based rendering and 3D backend reuse the same face/UV data.
- Public widget/controller API names are provisional; avoid locking API before real Windows smoke.
- `minecraft_accounts` may produce already-authorized profile skins; Skin Viewer only renders supplied textures.

## Proposed milestones — not approvals

| Stage | Proposed deliverable | Gate |
| --- | --- | --- |
| R2 | Decode/validate skin/cape PNG; actual atlas/UV mapping for modern/legacy, Classic/Slim and overlays; targeted fixture checks | R2 completed and merged in PR #2 |
| R3 | Flutter `CustomPainter` head, 2D body and cape widgets; front/back views, layer visibility, nearest sampling | R3 accepted on Windows and merged in PR #3 |
| R4 | Actual textured 3D character and cape, orbit/zoom controller, reasonable idle/walk/pose motions | Requires documented GPU backend decision and real release smoke |
| R5 | Windows launcher embedding example, performance and lifecycle/rebuild review, package API/publication readiness | Requires integration boundary review and separate acceptance |

## Non-goals unless explicitly approved

- Login/auth, Mojang/Microsoft/Ely.by network calls, third-party API caching, account selection/storage.
- Bedrock geometry, complex HD skins, cape cloth simulation, broad platform support claims.
- Independent fork or duplicate of upstream launcher/account services.

## Acceptance discipline

- Each milestone should state scope/non-goals, owner, test fixtures, Windows live output, dependency/ABI risk, cleanup and public API consequences.
- Maintain a single active review/merge path; no implementation simply because this document exists.
- Keep latest factual project handoff in `CURRENT_TARGET.md`. Move long rationale/evidence to this plan or dedicated checkpoint docs rather than inflating the handoff.
