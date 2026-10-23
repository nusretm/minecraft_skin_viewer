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
      // The cape's decorated atlas front belongs on the outward-facing
      // character-back (-Z) surface. Inner fabric (+Z) gets atlas back.
      final atlasFace = switch (faces[f]) {
        MtnMinecraftSkinFace.back => MtnMinecraftSkinFace.front,
        MtnMinecraftSkinFace.front => MtnMinecraftSkinFace.back,
        _ => faces[f],
      };
      final uv = layout.face(atlasFace).normalizedCorners(64, 32);
      for (var i = 0; i < 4; i++) {
        final at = (f * 4 + i) * 2;
        final sourceCorner = faces[f] == MtnMinecraftSkinFace.back
            ? switch (i) { 0 => 1, 1 => 0, 2 => 3, _ => 2 }
            : i;
        expect(mesh.texCoords[at], uv[sourceCorner].x,
            reason: 'cape ${faces[f].name} UV corner $i horizontal');
        expect(mesh.texCoords[at + 1], uv[sourceCorner].y,
            reason: 'cape ${faces[f].name} UV corner $i vertical');
      }
    }
  });

  test('cape rear -Z outward fabric has decorated face, not inner atlas UV', () {
    const layout = MtnMinecraftCapeUvLayout();
    final mesh = MtnMinecraftCapeBoxMesh.build();

    // Mesh face indices: back (-Z) = 0, front (+Z) = 2.
    final exterior = layout.face(MtnMinecraftSkinFace.front)
        .normalizedCorners(64, 32);
    final interior = layout.face(MtnMinecraftSkinFace.back)
        .normalizedCorners(64, 32);
    expect(exterior.first.x, isNot(interior.first.x));

    for (var corner = 0; corner < 4; corner++) {
      final backIndex = corner * 2;
      final frontIndex = (2 * 4 + corner) * 2;
      expect(mesh.normals[corner * 3 + 2], -1);
      expect(mesh.normals[(2 * 4 + corner) * 3 + 2], 1);
      final mirroredCorner = switch (corner) {
        0 => 1, 1 => 0, 2 => 3, _ => 2,
      };
      expect(mesh.texCoords[backIndex], exterior[mirroredCorner].x);
      expect(mesh.texCoords[backIndex + 1], exterior[mirroredCorner].y);
      expect(mesh.texCoords[frontIndex], interior[corner].x);
      expect(mesh.texCoords[frontIndex + 1], interior[corner].y);
    }
  });

  test('outward cape mirror flips only U: vertical orientation is unchanged', () {
    const layout = MtnMinecraftCapeUvLayout();
    final source = layout.face(MtnMinecraftSkinFace.front)
        .normalizedCorners(64, 32);
    final texCoords = MtnMinecraftCapeBoxMesh.build().texCoords;
    // -Z face first four vertices are top-left, top-right, bottom-right,
    // bottom-left as viewed from behind the player.
    expect(texCoords[0], source[1].x);
    expect(texCoords[1], source[0].y);
    expect(texCoords[2], source[0].x);
    expect(texCoords[3], source[1].y);
    expect(texCoords[4], source[3].x);
    expect(texCoords[5], source[2].y);
    expect(texCoords[6], source[2].x);
    expect(texCoords[7], source[3].y);
    // No horizontal flip is permitted on the inward (+Z) atlas face.
    final inner = layout.face(MtnMinecraftSkinFace.back)
        .normalizedCorners(64, 32);
    for (var i = 0; i < 4; i++) {
      final at = (2 * 4 + i) * 2;
      expect(texCoords[at], inner[i].x);
      expect(texCoords[at + 1], inner[i].y);
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

  test('Live inhales outward, exhales inward and preserves Idle/Walk axes', () {
    final inhaleStart = MtnMinecraftSkinPoseFrame.at(
        MtnMinecraftSkinPose.live, seconds: 0);
    final inhalePeak = MtnMinecraftSkinPoseFrame.at(
        MtnMinecraftSkinPose.live, seconds: 1.9);
    final exhaleEnd = MtnMinecraftSkinPoseFrame.at(
        MtnMinecraftSkinPose.live, seconds: 3.8);
    expect(inhaleStart.rightArmZ, lessThan(0));
    expect(inhaleStart.leftArmZ, -inhaleStart.rightArmZ);
    expect(inhalePeak.rightArmZ, lessThan(inhaleStart.rightArmZ));
    expect(inhalePeak.leftArmZ, greaterThan(inhaleStart.leftArmZ));
    expect(inhalePeak.rightArmZ.abs(), lessThanOrEqualTo(0.12));
    expect(exhaleEnd.rightArmZ, closeTo(inhaleStart.rightArmZ, 1e-12));
    expect(exhaleEnd.leftArmZ, closeTo(inhaleStart.leftArmZ, 1e-12));
    expect(inhalePeak.rightArmX, 0);
    expect(inhalePeak.leftArmX, 0);
    expect(inhalePeak.rightLegX, 0);
    expect(inhalePeak.leftLegX, 0);

    final lookingUp = MtnMinecraftSkinPoseFrame.at(
        MtnMinecraftSkinPose.live, seconds: 1,
        liveHeadYaw: 0, liveHeadPitch: -0.2);
    expect(lookingUp.headYaw, 0);
    expect(lookingUp.headPitch, -0.2);
    for (final mode in [MtnMinecraftSkinPose.idle, MtnMinecraftSkinPose.walk]) {
      final frame = MtnMinecraftSkinPoseFrame.at(mode, seconds: 1,
          liveHeadYaw: 0.3, liveHeadPitch: 0.2);
      expect(frame.rightArmZ, 0);
      expect(frame.leftArmZ, 0);
      expect(frame.headYaw, 0);
      expect(frame.headPitch, 0);
    }
    expect(() => MtnMinecraftSkinPoseFrame.at(
        MtnMinecraftSkinPose.live, seconds: double.nan), throwsArgumentError);
    expect(() => MtnMinecraftSkinPoseFrame.at(
        MtnMinecraftSkinPose.live, liveHeadYaw: double.infinity), throwsArgumentError);
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
