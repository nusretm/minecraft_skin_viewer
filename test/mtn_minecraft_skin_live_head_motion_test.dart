import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mtn_minecraft_skin_viewer/src/mtn_minecraft_skin_live_head_motion.dart';

class _FixedRandom implements math.Random {
  _FixedRandom(this.direction);
  final int direction;
  @override
  bool nextBool() => true;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => direction % max;
}

void main() {
  group('R7 Live head glances', () {
    for (var direction = 0; direction < 4; direction++) {
      test('direction $direction waits, turns, holds and returns to front', () {
        final motion = MtnMinecraftSkinLiveHeadMotion(
            random: _FixedRandom(direction));
        final neutral = motion.anglesAt(1.9);
        expect(neutral.yaw, 0);
        expect(neutral.pitch, 0);

        // Fixed random: wait=2 s, turn=0.4 s, hold=1 s, return=0.4 s.
        final turning = motion.anglesAt(2.2);
        final hold = motion.anglesAt(2.5);
        final returning = motion.anglesAt(3.6);
        final returned = motion.anglesAt(3.8);

        final angle = direction < 2 ? hold.yaw : hold.pitch;
        final startAngle = direction < 2 ? turning.yaw : turning.pitch;
        final endAngle = direction < 2 ? returning.yaw : returning.pitch;
        expect(angle.abs(), greaterThan(0.13));
        expect(angle.abs(), lessThanOrEqualTo(25 * math.pi / 180));
        expect(startAngle, closeTo(angle / 2, 1e-10));
        expect(endAngle, closeTo(angle / 2, 1e-10));
        expect(returned.yaw, closeTo(0, 1e-10));
        expect(returned.pitch, closeTo(0, 1e-10));

        if (direction < 2) {
          expect(hold.pitch, 0);
          expect(angle.isNegative, direction == 0);
        } else {
          expect(hold.yaw, 0);
          expect(angle.isNegative, direction == 2);
        }

        motion.reset();
        final repeated = motion.anglesAt(2.5);
        expect(repeated.yaw, hold.yaw);
        expect(repeated.pitch, hold.pitch);
      });
    }

    test('seeded schedule advances across many glances without drift', () {
      final motion = MtnMinecraftSkinLiveHeadMotion(random: math.Random(42));
      var yawSeen = false;
      var pitchSeen = false;
      for (var i = 0; i < 3000; i++) {
        final angles = motion.anglesAt(i * 0.1);
        expect(angles.yaw.abs(), lessThanOrEqualTo(25 * math.pi / 180));
        expect(angles.pitch.abs(), lessThanOrEqualTo(16 * math.pi / 180));
        expect(angles.yaw == 0 || angles.pitch == 0, isTrue);
        yawSeen |= angles.yaw != 0;
        pitchSeen |= angles.pitch != 0;
      }
      expect(yawSeen, isTrue);
      expect(pitchSeen, isTrue);
      expect(() => motion.anglesAt(double.nan), throwsArgumentError);
      expect(() => motion.anglesAt(-1), throwsArgumentError);
    });
  });
}
