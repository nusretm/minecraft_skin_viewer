import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart';

void main() {
  const faces = <MtnMinecraftSkinFace>[
    MtnMinecraftSkinFace.back,
    MtnMinecraftSkinFace.right,
    MtnMinecraftSkinFace.front,
    MtnMinecraftSkinFace.left,
    MtnMinecraftSkinFace.top,
    MtnMinecraftSkinFace.bottom,
  ];

  test('cape has exactly 24 vertices and uses R2 64x32 UV on six faces', () {
    final mesh = MtnMinecraftCapeBoxMesh.build();
    expect(mesh.positions.length, 72);
    expect(mesh.normals.length, 72);
    expect(mesh.texCoords.length, 48);
    expect(mesh.indices.length, 36);

    const layout = MtnMinecraftCapeUvLayout();
    for (var f = 0; f < faces.length; f++) {
      final uv = layout.face(faces[f]).normalizedCorners(64, 32);
      for (var i = 0; i < 4; i++) {
        final at = (f * 4 + i) * 2;
        expect(mesh.texCoords[at], uv[i].x);
        expect(mesh.texCoords[at + 1], uv[i].y);
      }
    }
  });

  test('cape triangles have outward normal and exact physical dimensions', () {
    final mesh = MtnMinecraftCapeBoxMesh.build();
    final p = mesh.positions, n = mesh.normals, index = mesh.indices;
    final extents = <double>[];
    for (var axis = 0; axis < 3; axis++) {
      final numbers = <double>[
        for (var i = axis; i < p.length; i += 3) p[i],
      ];
      extents.add(numbers.reduce(math.max) - numbers.reduce(math.min));
    }
    expect(extents, [10 / 16, 16 / 16, 1 / 16]);

    for (var f = 0; f < 6; f++) {
      for (var t = 0; t < 2; t++) {
        final i = f * 6 + t * 3;
        final a = index[i], b = index[i + 1], c = index[i + 2];
        final ab = [
          p[b * 3] - p[a * 3],
          p[b * 3 + 1] - p[a * 3 + 1],
          p[b * 3 + 2] - p[a * 3 + 2],
        ];
        final ac = [
          p[c * 3] - p[a * 3],
          p[c * 3 + 1] - p[a * 3 + 1],
          p[c * 3 + 2] - p[a * 3 + 2],
        ];
        final cross = [
          ab[1] * ac[2] - ab[2] * ac[1],
          ab[2] * ac[0] - ab[0] * ac[2],
          ab[0] * ac[1] - ab[1] * ac[0],
        ];
        final at = f * 4 * 3;
        expect(cross[0] * n[at] + cross[1] * n[at + 1] +
            cross[2] * n[at + 2], greaterThan(0));
      }
    }
  });

  test('idle pose is stable and walking limbs counter-swing', () {
    final neutral = MtnMinecraftSkinPoseFrame.at(MtnMinecraftSkinPose.idle);
    final idleLater = MtnMinecraftSkinPoseFrame.at(
      MtnMinecraftSkinPose.idle, seconds: 324);
    expect(neutral.rightArmX, 0);
    expect(neutral.leftArmX, 0);
    expect(neutral.rightLegX, 0);
    expect(neutral.leftLegX, 0);
    expect(neutral.capeX, greaterThan(0));
    expect(idleLater.capeX, neutral.capeX);

    for (final seconds in [0.1, 0.27, 0.66, 1.25, 7.0]) {
      final walk = MtnMinecraftSkinPoseFrame.at(
        MtnMinecraftSkinPose.walk, seconds: seconds);
      expect(walk.rightArmX, closeTo(-walk.leftArmX, 1e-10));
      expect(walk.rightArmX, closeTo(-walk.rightLegX, 1e-10));
      expect(walk.rightArmX, closeTo(walk.leftLegX, 1e-10));
      expect(walk.rightArmX.abs(), lessThanOrEqualTo(0.48));
      expect(walk.capeX, inInclusiveRange(0.18, 0.30));
    }
    expect(() => MtnMinecraftSkinPoseFrame.at(
      MtnMinecraftSkinPose.walk, seconds: double.nan), throwsArgumentError);
  });

  test('Classic/Slim shoulder pivots keep the correct part centers', () {
    for (final model in MtnMinecraftSkinModelType.values) {
      for (final part in MtnMinecraftSkinBodyPart.values) {
        final pivot = MtnMinecraftSkinPivot.forPart(part, model);
        final center = MtnMinecraftSkinBoxMesh.centerFor(part, model);
        if (part == MtnMinecraftSkinBodyPart.head) {
          expect(center.y - pivot.y, 0.25);
        } else {
          expect(center.y - pivot.y, -0.375);
        }
        expect(pivot.x, center.x);
        expect(pivot.z, center.z);
      }
      final width = MtnMinecraftSkinUvLayout(model)
          .dimensions(MtnMinecraftSkinBodyPart.rightArm).width;
      final right = MtnMinecraftSkinPivot.forPart(
        MtnMinecraftSkinBodyPart.rightArm, model);
      final left = MtnMinecraftSkinPivot.forPart(
        MtnMinecraftSkinBodyPart.leftArm, model);
      expect(left.x, -right.x);
      expect(left.x.abs(), (4 + width / 2) / 16);
    }
    expect(MtnMinecraftSkinPivot.cape.y, 1.5);
    expect(MtnMinecraftSkinPivot.cape.z, lessThan(-0.125));
  });
}
