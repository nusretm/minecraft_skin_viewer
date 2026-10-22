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

  group('R4-A renderer-neutral Minecraft cuboid', () {
    for (final modelType in MtnMinecraftSkinModelType.values) {
      test('all body parts and face UVs: ' + modelType.name, () {
        final layout = MtnMinecraftSkinUvLayout(modelType);
        for (final part in MtnMinecraftSkinBodyPart.values) {
          final mesh = MtnMinecraftSkinBoxMesh.forBodyPart(part, modelType);
          expect(mesh.part, part);
          expect(mesh.modelType, modelType);
          expect(mesh.positions.length, 72);
          expect(mesh.normals.length, 72);
          expect(mesh.texCoords.length, 48);
          expect(mesh.indices.length, 36);
          final uv = mesh.texCoords;
          for (var f = 0; f < faces.length; f++) {
            final corners = layout.face(part, faces[f]).normalizedCorners(64, 64);
            for (var v = 0; v < 4; v++) {
              final index = (f * 4 + v) * 2;
              expect(uv[index], corners[v].x);
              expect(uv[index + 1], corners[v].y);
            }
          }
        }
      });

      test('outward normals and triangle winding: ' + modelType.name, () {
        for (final part in MtnMinecraftSkinBodyPart.values) {
          final mesh = MtnMinecraftSkinBoxMesh.forBodyPart(part, modelType);
          final p = mesh.positions;
          final n = mesh.normals;
          final ix = mesh.indices;
          for (var face = 0; face < 6; face++) {
            final base = face * 4;
            final normal = <double>[n[base * 3], n[base * 3 + 1], n[base * 3 + 2]];
            expect(normal.map((v) => v * v).reduce((a, b) => a + b), 1);
            for (var v = 0; v < 4; v++) {
              final i = (base + v) * 3;
              expect(p[i] * normal[0] + p[i+1] * normal[1] + p[i+2] * normal[2],
                  greaterThan(0));
              expect([n[i], n[i+1], n[i+2]], normal);
            }
            for (var tri = 0; tri < 2; tri++) {
              final a = ix[face * 6 + tri * 3];
              final b = ix[face * 6 + tri * 3 + 1];
              final c = ix[face * 6 + tri * 3 + 2];
              expect([a, b, c].every((i) => i >= face * 4 && i < face * 4 + 4),
                  isTrue);
              final ab = [p[b*3]-p[a*3], p[b*3+1]-p[a*3+1], p[b*3+2]-p[a*3+2]];
              final ac = [p[c*3]-p[a*3], p[c*3+1]-p[a*3+1], p[c*3+2]-p[a*3+2]];
              final cross = [
                ab[1]*ac[2]-ab[2]*ac[1],
                ab[2]*ac[0]-ab[0]*ac[2],
                ab[0]*ac[1]-ab[1]*ac[0],
              ];
              expect(cross[0]*normal[0]+cross[1]*normal[1]+cross[2]*normal[2],
                  greaterThan(0), reason: part.name + ' / ' + faces[face].name);
            }
          }
        }
      });

      test('Minecraft scale and standing placement: ' + modelType.name, () {
        final layout = MtnMinecraftSkinUvLayout(modelType);
        for (final part in MtnMinecraftSkinBodyPart.values) {
          final mesh = MtnMinecraftSkinBoxMesh.forBodyPart(part, modelType);
          final d = layout.dimensions(part);
          final p = mesh.positions;
          final xs = <double>[], ys = <double>[], zs = <double>[];
          for (var i = 0; i < p.length; i += 3) {
            xs.add(p[i]); ys.add(p[i+1]); zs.add(p[i+2]);
          }
          expect(xs.reduce(math.max)-xs.reduce(math.min), closeTo(d.width / 16, 1e-8));
          expect(ys.reduce(math.max)-ys.reduce(math.min), closeTo(d.height / 16, 1e-8));
          expect(zs.reduce(math.max)-zs.reduce(math.min), closeTo(d.depth / 16, 1e-8));
          final center = MtnMinecraftSkinBoxMesh.centerFor(part, modelType);
          if (part == MtnMinecraftSkinBodyPart.head) {
            expect(center.y + d.height / 32, 2);
          }
          if (part == MtnMinecraftSkinBodyPart.rightLeg ||
              part == MtnMinecraftSkinBodyPart.leftLeg) {
            expect(center.y - d.height / 32, 0);
          }
        }
      });
    }

    test('Classic/Slim arm is exactly 1 model pixel narrower', () {
      final c = MtnMinecraftSkinBoxMesh.forBodyPart(
        MtnMinecraftSkinBodyPart.rightArm, MtnMinecraftSkinModelType.classic);
      final s = MtnMinecraftSkinBoxMesh.forBodyPart(
        MtnMinecraftSkinBodyPart.rightArm, MtnMinecraftSkinModelType.slim);
      expect((c.positions[3] - c.positions[0]).abs() -
             (s.positions[3] - s.positions[0]).abs(), closeTo(1/16, 1e-8));
      final cc = MtnMinecraftSkinBoxMesh.centerFor(
        MtnMinecraftSkinBodyPart.rightArm, MtnMinecraftSkinModelType.classic);
      final ss = MtnMinecraftSkinBoxMesh.centerFor(
        MtnMinecraftSkinBodyPart.rightArm, MtnMinecraftSkinModelType.slim);
      expect(ss.x - cc.x, closeTo(0.5 / 16, 1e-8));
    });

    test('vertex snapshots cannot modify original mesh', () {
      final mesh = MtnMinecraftSkinBoxMesh.forBodyPart(
        MtnMinecraftSkinBodyPart.head, MtnMinecraftSkinModelType.classic);
      final before = mesh.positions[0];
      final copy = mesh.positions;
      copy[0] = 456;
      expect(mesh.positions[0], before);
      final uBefore = mesh.texCoords[0];
      final uv = mesh.texCoords;
      uv[0] = 234;
      expect(mesh.texCoords[0], uBefore);
      expect(() => mesh.indices[0] = 999, throwsUnsupportedError);
    });
  });
}
