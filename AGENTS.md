# Minecraft Skin Viewer — Agent Instructions

Read `docs/WORKING_RULES.md` and `docs/continuity/CURRENT_TARGET.md` before planning, editing, reviewing, or merging any work. These files are authoritative for this repository. Check relevant checkpoint documents before changing code.

Repository: `nusretm/minecraft_skin_viewer`. Flutter package: `mtn_minecraft_skin_viewer`. Scope: offline rendering of Minecraft Java skin/cape textures in 2D and interactive 3D. Windows desktop is the first live validation target; design should not prevent other Flutter platforms.

**Approval:** Analyze and propose without code changes by default. Implement only the scope explicitly approved by the user. A feature branch, passing tests, or an open PR never constitutes approval to merge. Do not merge without explicit user approval.

Favor render-backend-independent texture, geometry and pose concepts. Avoid coupling the package to Minecraft account authentication, token handling, launcher service, network APIs, or persistence. Do not add dependencies without a clear reason and user-approved scope.

Naming: abstract classes end in `Abs`, nonabstract shared base classes in `Base`; concrete family specializations retain the family prefix. Avoid unnecessary abstraction. Pure Dart code must not be run through `dart format` automatically.

Work in small meaningful checkpoints, preserve unrelated changes, run focused validation and report **actual** evidence. Windows debug/release smoke is mandatory before declaring the GPU-backed R1 renderer live-validated. No Flutter SDK in an automation host means tests are **NOT RUN**, not passed. Update continuity in the same work.
