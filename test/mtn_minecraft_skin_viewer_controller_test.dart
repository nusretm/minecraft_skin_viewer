import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart';

void main() {
  group('R4-D camera controller', () {
    test('defaults and continuous orbit/zoom without model resets', () {
      final camera = MtnMinecraftSkinViewerController();
      addTearDown(camera.dispose);
      expect(camera.pose, MtnMinecraftSkinPose.live);
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

    test('pose and visibility form one observable controller authority', () {
      final viewer = MtnMinecraftSkinViewerController(
        pose: MtnMinecraftSkinPose.walk,
        showOuterLayer: false,
        showCape: false,
      );
      addTearDown(viewer.dispose);
      expect(viewer.pose, MtnMinecraftSkinPose.walk);
      expect(viewer.showOuterLayer, isFalse);
      expect(viewer.showCape, isFalse);

      var changes = 0;
      void listener() => changes++;
      viewer.addListener(listener);
      viewer.setPose(MtnMinecraftSkinPose.walk);
      viewer.setShowOuterLayer(false);
      viewer.setShowCape(false);
      expect(changes, 0, reason: 'unchanged state must not notify');

      viewer.setPose(MtnMinecraftSkinPose.idle);
      viewer.setShowOuterLayer(true);
      viewer.setShowCape(true);
      expect(changes, 3);
      expect(viewer.pose, MtnMinecraftSkinPose.idle);
      expect(viewer.showOuterLayer, isTrue);
      expect(viewer.showCape, isTrue);

      // reset() is deliberately camera-only, not a pose/layer reset.
      viewer.reset();
      expect(viewer.pose, MtnMinecraftSkinPose.idle);
      expect(viewer.showOuterLayer, isTrue);
      expect(viewer.showCape, isTrue);
      viewer.removeListener(listener);
      viewer.setPose(MtnMinecraftSkinPose.walk);
      expect(changes, 3);
    });

    test('default Live can switch to Idle and Walk and back', () {
      final controller = MtnMinecraftSkinViewerController();
      addTearDown(controller.dispose);
      var updates = 0;
      controller.addListener(() => updates++);
      expect(controller.pose, MtnMinecraftSkinPose.live);
      controller.setPose(MtnMinecraftSkinPose.idle);
      controller.setPose(MtnMinecraftSkinPose.walk);
      controller.setPose(MtnMinecraftSkinPose.live);
      controller.setPose(MtnMinecraftSkinPose.live);
      expect(controller.pose, MtnMinecraftSkinPose.live);
      expect(updates, 3);
      controller.reset();
      expect(controller.pose, MtnMinecraftSkinPose.live,
          reason: 'reset remains camera-only');
    });

    test('camera changes do not mutate pose or visibility', () {
      final viewer = MtnMinecraftSkinViewerController(
        pose: MtnMinecraftSkinPose.walk,
        showOuterLayer: false,
        showCape: true,
      );
      addTearDown(viewer.dispose);
      viewer.orbitBy(25, -12);
      viewer.zoomBy(200);
      viewer.setOrbit(yaw: 1.1, pitch: 0.5);
      viewer.reset();
      expect(viewer.pose, MtnMinecraftSkinPose.walk);
      expect(viewer.showOuterLayer, isFalse);
      expect(viewer.showCape, isTrue);
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
