import 'dart:math' show Point;

import 'package:flutter_test/flutter_test.dart';
import 'package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart';

void main() {
  group('Minecraft Java UV layout', () {
    test('exact head, torso, left/right limbs and layer origins', () {
      const layout = MtnMinecraftSkinUvLayout(MtnMinecraftSkinModelType.classic);
      final checks = <(MtnMinecraftSkinBodyPart, MtnMinecraftSkinLayer, int, int)>[
        (MtnMinecraftSkinBodyPart.head, MtnMinecraftSkinLayer.base, 0, 0),
        (MtnMinecraftSkinBodyPart.head, MtnMinecraftSkinLayer.outer, 32, 0),
        (MtnMinecraftSkinBodyPart.body, MtnMinecraftSkinLayer.base, 16, 16),
        (MtnMinecraftSkinBodyPart.body, MtnMinecraftSkinLayer.outer, 16, 32),
        (MtnMinecraftSkinBodyPart.rightArm, MtnMinecraftSkinLayer.base, 40, 16),
        (MtnMinecraftSkinBodyPart.rightArm, MtnMinecraftSkinLayer.outer, 40, 32),
        (MtnMinecraftSkinBodyPart.leftArm, MtnMinecraftSkinLayer.base, 32, 48),
        (MtnMinecraftSkinBodyPart.leftArm, MtnMinecraftSkinLayer.outer, 48, 48),
        (MtnMinecraftSkinBodyPart.rightLeg, MtnMinecraftSkinLayer.base, 0, 16),
        (MtnMinecraftSkinBodyPart.rightLeg, MtnMinecraftSkinLayer.outer, 0, 32),
        (MtnMinecraftSkinBodyPart.leftLeg, MtnMinecraftSkinLayer.base, 16, 48),
        (MtnMinecraftSkinBodyPart.leftLeg, MtnMinecraftSkinLayer.outer, 0, 48),
      ];
      for (final row in checks) {
        final dim = layout.dimensions(row.$1);
        final top = layout.face(row.$1, MtnMinecraftSkinFace.top, layer: row.$2);
        expect(top.x, row.$3 + dim.depth, reason: '$row');
        expect(top.y, row.$4, reason: '$row');
        expect(top.width, dim.width);
        expect(top.height, dim.depth);
      }
    });

    test('six face rectangles follow correct Minecraft box-net offsets', () {
      final f = MtnMinecraftSkinFace.values;
      final actual = {for (final face in f) face: mtnMinecraftBoxFace(16, 16, 8, 12, 4, face)};
      final expected = <MtnMinecraftSkinFace, (int, int, int, int)>{
        MtnMinecraftSkinFace.top: (20, 16, 8, 4),
        MtnMinecraftSkinFace.bottom: (28, 16, 8, 4),
        MtnMinecraftSkinFace.left: (16, 20, 4, 12),
        MtnMinecraftSkinFace.front: (20, 20, 8, 12),
        MtnMinecraftSkinFace.right: (28, 20, 4, 12),
        MtnMinecraftSkinFace.back: (32, 20, 8, 12),
      };
      for (final face in f) {
        final r = actual[face]!;
        final e = expected[face]!;
        expect((r.x, r.y, r.width, r.height), e);
      }
      expect(actual[MtnMinecraftSkinFace.bottom]!.flipVertically, isTrue);
      expect(actual[MtnMinecraftSkinFace.top]!.flipVertically, isFalse);
      expect(actual[MtnMinecraftSkinFace.bottom]!.pixelAt(0, 0), const Point(28, 19));
      expect(actual[MtnMinecraftSkinFace.bottom]!.pixelAt(7, 3), const Point(35, 16));
    });

    test('slim arms are 3 pixels wide, 4 deep, and do not overlap', () {
      const slim = MtnMinecraftSkinUvLayout(MtnMinecraftSkinModelType.slim);
      const classic = MtnMinecraftSkinUvLayout(MtnMinecraftSkinModelType.classic);
      for (final part in [
        MtnMinecraftSkinBodyPart.leftArm, MtnMinecraftSkinBodyPart.rightArm,
      ]) {
        expect(slim.dimensions(part).width, 3);
        expect(classic.dimensions(part).width, 4);
        for (final layer in MtnMinecraftSkinLayer.values) {
          final front = slim.face(part, MtnMinecraftSkinFace.front, layer: layer);
          final side = slim.face(part, MtnMinecraftSkinFace.left, layer: layer);
          final back = slim.face(part, MtnMinecraftSkinFace.back, layer: layer);
          expect(front.width, 3);
          expect(side.width, 4);
          expect(back.width, 3);
          expect(front.height, 12);
        }
      }
      final rightFront = slim.face(MtnMinecraftSkinBodyPart.rightArm, MtnMinecraftSkinFace.front);
      expect((rightFront.x, rightFront.y), (44, 20));
      final leftFront = slim.face(MtnMinecraftSkinBodyPart.leftArm, MtnMinecraftSkinFace.front);
      expect((leftFront.x, leftFront.y), (36, 52));
    });

    test('all base/outer rectangles fit 64x64 for both models', () {
      for (final model in MtnMinecraftSkinModelType.values) {
        final layout = MtnMinecraftSkinUvLayout(model);
        for (final part in MtnMinecraftSkinBodyPart.values) {
          for (final layer in MtnMinecraftSkinLayer.values) {
            for (final face in MtnMinecraftSkinFace.values) {
              final r = layout.face(part, face, layer: layer);
              expect(r.x >= 0 && r.y >= 0, isTrue);
              expect(r.width > 0 && r.height > 0, isTrue);
              expect(r.x + r.width <= 64 && r.y + r.height <= 64, isTrue,
                  reason: '$model/$part/$layer/$face');
              final corners = r.normalizedCorners(64, 64);
              expect(corners.length, 4);
              for (final pt in corners) {
                expect(pt.x >= 0 && pt.x <= 1 && pt.y >= 0 && pt.y <= 1, isTrue);
              }
            }
          }
        }
      }
    });

    test('cape is a 10x16x1 net in a 64x32 atlas', () {
      const cape = MtnMinecraftCapeUvLayout();
      final front = cape.face(MtnMinecraftSkinFace.front);
      final back = cape.face(MtnMinecraftSkinFace.back);
      expect((front.x, front.y, front.width, front.height), (1, 1, 10, 16));
      expect((back.x, back.y, back.width, back.height), (12, 1, 10, 16));
      for (final face in MtnMinecraftSkinFace.values) {
        final rect = cape.face(face);
        expect(rect.x + rect.width <= 64 && rect.y + rect.height <= 32, isTrue);
      }
    });

    test('face corners are independent from GPU image-origin convention', () {
      final r = mtnMinecraftBoxFace(0, 0, 8, 8, 8, MtnMinecraftSkinFace.bottom);
      expect(r.normalizedCorners(64, 64),
          [const Point<double>(0.25, 0.125), const Point<double>(0.375, 0.125),
           const Point<double>(0.375, 0), const Point<double>(0.25, 0)]);
      expect(() => r.pixelAt(8, 0), throwsRangeError);
      expect(() => r.normalizedCorners(0, 64), throwsArgumentError);
      expect(() => mtnMinecraftBoxFace(0, 0, 0, 8, 8, MtnMinecraftSkinFace.top),
          throwsArgumentError);
    });
  });
}
