# R1 Windows renderer smoke example

This application is a **procedural, untextured feasibility prototype**, not a completed Minecraft skin viewer. The six cuboids use Classic Steve proportions (scaled to 1/16 world units). An optional translucent head shell tests alpha blending. Drag to orbit, mouse wheel to zoom.

## Prerequisites

- Flutter stable **3.47.1+** for Windows GPU release opt-in.
- Windows desktop Flutter development tools available; check `flutter doctor -v`.
- Run these commands from repository root in PowerShell:

```powershell
cd D:\development\cross-platform\minecraft_skin_viewer
flutter --version
flutter doctor -v
flutter pub get
cd example
flutter create . --platforms=windows
flutter pub get
```

Ensure the generated `example/windows/runner/main.cpp` contains:

```cpp
flutter::DartProject project(L"data");
project.set_enable_flutter_gpu(true);
```

The setting above is **not optional for release**. Debug builds with `--enable-flutter-gpu` can work without it; packaged Windows release builds cannot. Re-running `flutter create` does not guarantee that your local runner includes the setting. CI inserts the setting in its own temporary runner, which does not update your machine.

Run `flutter test --no-pub test/widget_test.dart` for GPU-free control checks. A standard `flutter test` runner cannot instantiate `Scene()`; visual GPU checks belong to a real Windows application.

Then run from `example/`:

```powershell
flutter analyze
flutter test --no-pub test/widget_test.dart
flutter run -d windows --enable-flutter-gpu
flutter build windows --release
.\build\windows\x64\runner\Release\mtn_minecraft_skin_viewer_example.exe
```

The exe filename is generated from the example project name and may differ; inspect the actual output. Launch the release EXE directly: a successful build does **not** prove GPU rendering.

## Open R1 tests

- Check both debug and release cuboids, orbit and zoom.
- Toggle head overlay and examine depth/transparency.
- Repeat mount/unmount or restart while watching resource use.
- Add synthetic pixel texture and verify nearest-neighbor filtering (not implemented yet).
- Record exact Flutter/GPU driver/platform versions and findings in `docs/continuity/CURRENT_TARGET.md`.

## Notes

- This first asset-free test uses `CuboidGeometry` and does not need `dart run flutter_scene:init`. The command becomes relevant when adopting the build-hook texture/model asset pipeline.
- `flutter_scene` is intentionally a dependency of `example/` rather than the root package while R1 is evaluated.
- Do not merge the prototype until Windows smoke and explicit user merge approval.
