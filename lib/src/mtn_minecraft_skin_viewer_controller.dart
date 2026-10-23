import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'mtn_minecraft_skin_pose_cape.dart';

/// Interactive 3D viewer state: camera, pose and layer visibility.
///
/// The attached viewer listens to this controller directly. The controller
/// is the *only* owner of pose and presentation state; decoded skin/cape
/// textures and the optional input-gesture toggle remain widget inputs.
/// If passed to a viewer, the caller retains ownership and must dispose it.
/// When omitted, the viewer creates and disposes its own controller.
class MtnMinecraftSkinViewerController extends ChangeNotifier {
  MtnMinecraftSkinViewerController({
    double yaw = -math.pi / 3,
    double pitch = 0.15,
    double distance = 3.7,
    MtnMinecraftSkinPose pose = MtnMinecraftSkinPose.live,
    bool showOuterLayer = true,
    bool showCape = true,
  }) : _pose = pose,
       _showOuterLayer = showOuterLayer,
       _showCape = showCape,
       _yaw = _finite(yaw, 'yaw'),
       _pitch = _finite(pitch, 'pitch').clamp(minPitch, maxPitch),
       _distance = _finite(distance, 'distance').clamp(minDistance, maxDistance);

  static const double minPitch = -1.1;
  static const double maxPitch = 1.1;
  static const double minDistance = 2.1;
  static const double maxDistance = 7.0;

  double _yaw;
  double _pitch;
  double _distance;
  MtnMinecraftSkinPose _pose;
  bool _showOuterLayer;
  bool _showCape;

  MtnMinecraftSkinPose get pose => _pose;
  bool get showOuterLayer => _showOuterLayer;
  bool get showCape => _showCape;

  void setPose(MtnMinecraftSkinPose value) {
    if (_pose == value) return;
    _pose = value;
    notifyListeners();
  }

  void setShowOuterLayer(bool value) {
    if (_showOuterLayer == value) return;
    _showOuterLayer = value;
    notifyListeners();
  }

  void setShowCape(bool value) {
    if (_showCape == value) return;
    _showCape = value;
    notifyListeners();
  }

  double get yaw => _yaw;
  double get pitch => _pitch;
  double get distance => _distance;

  static double _finite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'Must be finite');
    }
    return value;
  }

  void setOrbit({required double yaw, required double pitch}) {
    final nextYaw = _finite(yaw, 'yaw');
    final nextPitch = _finite(pitch, 'pitch').clamp(minPitch, maxPitch);
    if (_yaw == nextYaw && _pitch == nextPitch) return;
    _yaw = nextYaw;
    _pitch = nextPitch;
    notifyListeners();
  }

  /// Mouse drag delta in logical pixels, matching the Windows gallery.
  void orbitBy(double dx, double dy) {
    setOrbit(
      yaw: _yaw - _finite(dx, 'dx') * 0.012,
      pitch: _pitch + _finite(dy, 'dy') * 0.008,
    );
  }

  void setDistance(double distance) {
    final nextDistance = _finite(distance, 'distance')
        .clamp(minDistance, maxDistance);
    if (_distance == nextDistance) return;
    _distance = nextDistance;
    notifyListeners();
  }

  /// Scroll-wheel delta in logical pixels, positive moves away.
  void zoomBy(double scrollDy) {
    setDistance(_distance + _finite(scrollDy, 'scrollDy') * 0.003);
  }

  void reset() {
    setOrbit(yaw: -math.pi / 3, pitch: 0.15);
    setDistance(3.7);
  }
}
