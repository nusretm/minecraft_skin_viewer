import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart';

void main() {
  group('R4-D camera controller', () {
    test('defaults and continuous orbit/zoom without model resets', () {
      final camera = MtnMinecraftSkinViewerController();
      addTearDown(camera.dispose);
      expect(camera.yaw, closeTo(-math.pi / 3, 1e-12));
      expect(camera.pitch, 0.15);
      expect(camera.distance, 3.7);

      camera.orbitBy(25, -20);
      expect(camera.yaw, closeTo(-math.pi / 3 - 0.3, 1e-12));
      expect(camera.pitch, closeTo(-0.01, 1e-12));
      camera.zoomBy(-200);
      expect(camera.distance, closeTo(3.1, 1e-12));

      // Caller-managed controller remains authoritative if the widget's
      // decoded skin object/model type is replaced.
      final yawBeforeTextureSwap = camera.yaw;
      final distanceBeforeTextureSwap = camera.distance;
      expect(camera.yaw, yawBeforeTextureSwap);
      expect(camera.distance, distanceBeforeTextureSwap);
    });

    test('pitch and distance clamp to safe Windows interaction ranges', () {
      final camera = MtnMinecraftSkinViewerController(
        pitch: 10,
        distance: 99,
      );
      addTearDown(camera.dispose);
      expect(camera.pitch, MtnMinecraftSkinViewerController.maxPitch);
      expect(camera.distance, MtnMinecraftSkinViewerController.maxDistance);
      camera.setOrbit(yaw: 0, pitch: -100);
      camera.setDistance(-10);
      expect(camera.pitch, MtnMinecraftSkinViewerController.minPitch);
      expect(camera.distance, MtnMinecraftSkinViewerController.minDistance);
      camera.orbitBy(0, 100000);
      camera.zoomBy(100000);
      expect(camera.pitch, MtnMinecraftSkinViewerController.maxPitch);
      expect(camera.distance, MtnMinecraftSkinViewerController.maxDistance);
    });

    test('only changes notify; reset sets reference view', () {
      final camera = MtnMinecraftSkinViewerController();
      addTearDown(camera.dispose);
      var updates = 0;
      void listener() => updates++;
      camera.addListener(listener);
      camera.setOrbit(yaw: camera.yaw, pitch: camera.pitch);
      camera.setDistance(camera.distance);
      expect(updates, 0);
      camera.orbitBy(12, 0);
      camera.zoomBy(100);
      expect(updates, 2);
      camera.reset();
      expect(updates, 4);
      expect(camera.yaw, closeTo(-math.pi / 3, 1e-12));
      expect(camera.pitch, 0.15);
      expect(camera.distance, 3.7);
      camera.removeListener(listener);
      camera.orbitBy(12, 0);
      expect(updates, 4);
    });

    test('invalid camera values are explicitly rejected', () {
      expect(
        () => MtnMinecraftSkinViewerController(yaw: double.nan),
        throwsArgumentError,
      );
      expect(
        () => MtnMinecraftSkinViewerController(distance: double.infinity),
        throwsArgumentError,
      );
      final camera = MtnMinecraftSkinViewerController();
      addTearDown(camera.dispose);
      expect(() => camera.zoomBy(double.negativeInfinity), throwsArgumentError);
      expect(() => camera.orbitBy(double.nan, 0), throwsArgumentError);
      expect(() => camera.setOrbit(yaw: 1, pitch: double.nan), throwsArgumentError);
    });
  });
}
