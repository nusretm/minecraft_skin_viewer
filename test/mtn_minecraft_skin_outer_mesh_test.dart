import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart';

(double, double) _bounds(List<double> positions, int axis) {
  final values = <double>[];
  for (var i = axis; i < positions.length; i += 3) {
    values.add(positions[i]);
  }
  return (values.reduce(math.min), values.reduce(math.max));
}

void main() {
  const faceOrder = <MtnMinecraftSkinFace>[
    MtnMinecraftSkinFace.back,
    MtnMinecraftSkinFace.right,
    MtnMinecraftSkinFace.front,
    MtnMinecraftSkinFace.left,
    MtnMinecraftSkinFace.top,
    MtnMinecraftSkinFace.bottom,
  ];

  group('R4-B Java skin outer shell meshes', () {
    for (final model in MtnMinecraftSkinModelType.values) {
      test('all parts use R2 outer UV faces: ' + model.name, () {
        final layout = MtnMinecraftSkinUvLayout(model);
        for (final part in MtnMinecraftSkinBodyPart.values) {
          final base = MtnMinecraftSkinBoxMesh.forBodyPart(part, model);
          final outer = MtnMinecraftSkinBoxMesh.forBodyPart(
            part, model, layer: MtnMinecraftSkinLayer.outer);
          expect(base.layer, MtnMinecraftSkinLayer.base);
          expect(outer.layer, MtnMinecraftSkinLayer.outer);
          expect(outer.positions.length, 72);
          expect(outer.normals.length, 72);
          expect(outer.texCoords.length, 48);
          expect(outer.indices.length, 36);
          for (var i = 0; i < faceOrder.length; i++) {
            final face = faceOrder[i];
            final expected = layout.face(part, face,
                layer: MtnMinecraftSkinLayer.outer).normalizedCorners(64, 64);
            final uvs = outer.texCoords;
            for (var corner = 0; corner < 4; corner++) {
              final offset = (i * 4 + corner) * 2;
              expect(uvs[offset], expected[corner].x,
                  reason: model.name + '/' + part.name + '/' + face.name + ' U');
              expect(uvs[offset + 1], expected[corner].y,
                  reason: model.name + '/' + part.name + '/' + face.name + ' V');
            }
          }
        }
      });

      test('safe outer-face UVs do not alter shell geometry: ' + model.name, () {
        for (final part in MtnMinecraftSkinBodyPart.values) {
          final outer = MtnMinecraftSkinBoxMesh.forBodyPart(
            part, model, layer: MtnMinecraftSkinLayer.outer);
          final beforePositions = outer.positions;
          final beforeNormals = outer.normals;
          final beforeIndices = outer.indices;
          final beforeUvs = outer.texCoords;
          final safeUvs = outer.texCoordsWithInset();
          expect(safeUvs.length, beforeUvs.length);
          expect(outer.positions, orderedEquals(beforePositions));
          expect(outer.normals, orderedEquals(beforeNormals));
          expect(outer.indices, orderedEquals(beforeIndices));
          expect(outer.texCoords, orderedEquals(beforeUvs));
          expect(safeUvs, isNot(orderedEquals(beforeUvs)),
              reason: '3D upload should opt into the inset UVs');
        }
      });

      test('all outer surfaces sit outside base mesh: ' + model.name, () {
        for (final part in MtnMinecraftSkinBodyPart.values) {
          final base = MtnMinecraftSkinBoxMesh.forBodyPart(part, model);
          final outer = MtnMinecraftSkinBoxMesh.forBodyPart(
            part, model, layer: MtnMinecraftSkinLayer.outer);
          final inflation = part == MtnMinecraftSkinBodyPart.head ? 0.5 : 0.25;
          for (var axis = 0; axis < 3; axis++) {
            final (bMin, bMax) = _bounds(base.positions, axis);
            final (oMin, oMax) = _bounds(outer.positions, axis);
            expect(bMin - oMin, closeTo(inflation / 16, 1e-8));
            expect(oMax - bMax, closeTo(inflation / 16, 1e-8));
          }
          expect(outer.normals, orderedEquals(base.normals));
          expect(outer.indices, orderedEquals(base.indices));
        }
      });

      test('outer faces preserve outward triangle winding: ' + model.name, () {
        for (final part in MtnMinecraftSkinBodyPart.values) {
          final outer = MtnMinecraftSkinBoxMesh.forBodyPart(
            part, model, layer: MtnMinecraftSkinLayer.outer);
          final p = outer.positions, n = outer.normals, indices = outer.indices;
          for (var f = 0; f < 6; f++) {
            for (var t = 0; t < 2; t++) {
              final i = f * 6 + t * 3;
              final a = indices[i], b = indices[i + 1], c = indices[i + 2];
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
              final v = f * 4 * 3;
              final dot = cross[0] * n[v] + cross[1] * n[v + 1] + cross[2] * n[v + 2];
              expect(dot, greaterThan(0),
                  reason: model.name + '/' + part.name + ': face ' +
                      f.toString() + ' triangle ' + t.toString());
            }
          }
        }
      });
    }
  });
}
