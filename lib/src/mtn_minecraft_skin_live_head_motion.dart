import 'dart:math' as math;

/// A scheduler for occasional head glances during Live mode.
///
/// It is driven only by the viewer's existing frame clock: no independent
/// timer, notifier, GPU resource or asynchronous callback is created.
/// [reset] starts a new Live session, with a neutral head at time zero.
/// Random injection makes the scheduler deterministic in focused tests.
class MtnMinecraftSkinLiveHeadMotion {
  MtnMinecraftSkinLiveHeadMotion({math.Random? random})
      : _random = random ?? math.Random() {
    reset();
  }

  static const double turnSeconds = 0.4;

  final math.Random _random;
  double _cycleStart = 0;
  double _waitSeconds = 0;
  double _holdSeconds = 0;
  double _targetYaw = 0;
  double _targetPitch = 0;

  void reset() {
    _cycleStart = 0;
    _planNext();
  }

  void _planNext() {
    _waitSeconds = 2 + 3 * _random.nextDouble();
    _holdSeconds = 1 + 3 * _random.nextDouble();
    final direction = _random.nextInt(4);
    // Yaw: a subtle 12–25 degree side glance.
    // Pitch: an even gentler 8–16 degree up/down glance.
    final amplitude = (direction < 2
        ? 12 + 13 * _random.nextDouble()
        : 8 + 8 * _random.nextDouble()) * math.pi / 180;
    _targetYaw = switch (direction) {
      0 => -amplitude, // character right
      1 => amplitude,  // character left
      _ => 0.0,
    };
    _targetPitch = switch (direction) {
      2 => -amplitude, // look upward
      3 => amplitude,  // look downward
      _ => 0.0,
    };
  }

  double get _cycleLength => _waitSeconds + 2 * turnSeconds + _holdSeconds;

  /// Yaw about the head's Y axis and pitch about its local X axis (radians).
  /// Delays and holds vary, but every glance returns smoothly to neutral.
  ({double yaw, double pitch}) anglesAt(double seconds) {
    if (!seconds.isFinite || seconds < 0) {
      throw ArgumentError.value(seconds, 'seconds', 'Must be finite and nonnegative');
    }
    // Normal frame timestamps increase monotonically. Skip complete cycles
    // only when a frame was delayed (e.g. minimized application).
    while (seconds >= _cycleStart + _cycleLength) {
      _cycleStart += _cycleLength;
      _planNext();
    }
    final position = seconds - _cycleStart;
    final turnStart = _waitSeconds;
    final holdStart = turnStart + turnSeconds;
    final returnStart = holdStart + _holdSeconds;
    double weight;
    if (position < turnStart) {
      weight = 0;
    } else if (position < holdStart) {
      weight = _ease((position - turnStart) / turnSeconds);
    } else if (position < returnStart) {
      weight = 1;
    } else {
      weight = 1 - _ease((position - returnStart) / turnSeconds);
    }
    return (yaw: _targetYaw * weight, pitch: _targetPitch * weight);
  }

  static double _ease(double t) => t * t * (3 - 2 * t);
}
