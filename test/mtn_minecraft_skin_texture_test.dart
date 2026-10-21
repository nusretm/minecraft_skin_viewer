import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart';

void pixel(Uint8List pixels, int x, int y, int red, int green, int blue, int alpha) {
  final i = (y * 64 + x) * 4;
  pixels[i] = red;
  pixels[i + 1] = green;
  pixels[i + 2] = blue;
  pixels[i + 3] = alpha;
}

Future<Uint8List> pngFromRgba(Uint8List rgba, int width, int height) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: width,
    height: height,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  final image = (await codec.getNextFrame()).image;
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('Failed to encode synthetic PNG fixture.');
    return Uint8List.fromList(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  } finally {
    image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R2 Java skin PNG texture', () {
    test('modern base alpha is opaque; outer alpha and unused cells remain intact', () async {
      final raw = Uint8List(64 * 64 * 4);
      pixel(raw, 8, 8, 10, 20, 30, 0);    // head front, base
      pixel(raw, 40, 8, 70, 80, 90, 123); // head front, outer
      pixel(raw, 20, 36, 11, 22, 33, 88); // body jacket front
      pixel(raw, 63, 63, 5, 6, 7, 42);   // unused
      final png = await pngFromRgba(raw, 64, 64);
      final skin = await MtnMinecraftSkinTexture.fromPng(
        png, modelType: MtnMinecraftSkinModelType.classic);
      expect(skin.isLegacy, isFalse);
      expect(skin.rgbaAt(8, 8) & 0xff, 255); // RGB under alpha=0 is codec-dependent
      expect(skin.rgbaAt(40, 8) & 0xff, 123);
      expect(skin.rgbaAt(20, 36) & 0xff, 88);
      expect(skin.rgbaAt(63, 63) & 0xff, 42);
      final copy = skin.rgba;
      final old = skin.rgbaAt(8, 8);
      copy[(8 * 64 + 8) * 4] = 255;
      expect(skin.rgbaAt(8, 8), old);
    });

    test('modern fully opaque hat is not silently discarded', () async {
      final raw = Uint8List(64 * 64 * 4);
      for (var i = 3; i < raw.length; i += 4) raw[i] = 255;
      pixel(raw, 40, 8, 111, 112, 113, 255);
      final skin = await MtnMinecraftSkinTexture.fromPng(
        await pngFromRgba(raw, 64, 64),
        modelType: MtnMinecraftSkinModelType.slim);
      expect(skin.rgbaAt(40, 8), 0x6F7071FF);
    });

    test('legacy per-face leg and arm flips, and fills lower half', () async {
      final raw = Uint8List(64 * 32 * 4);
      pixel(raw, 4, 20, 71, 0, 0, 255);   // front right leg, first column
      pixel(raw, 7, 20, 92, 0, 0, 255);   // front right leg, last column
      pixel(raw, 0, 20, 42, 0, 0, 255);   // outer right leg
      pixel(raw, 44, 20, 11, 0, 0, 255);  // front right arm, first
      pixel(raw, 47, 20, 33, 0, 0, 255);  // front right arm, last
      pixel(raw, 12, 20, 18, 0, 0, 255);  // leg back
      final skin = await MtnMinecraftSkinTexture.fromPng(
        await pngFromRgba(raw, 64, 32),
        modelType: MtnMinecraftSkinModelType.classic,
      );
      expect(skin.isLegacy, isTrue);
      expect(skin.rgba.length, 64 * 64 * 4);
      expect(skin.rgbaAt(23, 52) >>> 24, 71);
      expect(skin.rgbaAt(20, 52) >>> 24, 92);
      expect(skin.rgbaAt(27, 52) >>> 24, 42);
      expect(skin.rgbaAt(39, 52) >>> 24, 11);
      expect(skin.rgbaAt(36, 52) >>> 24, 33);
      expect(skin.rgbaAt(31, 52) >>> 24, 18);
      expect(skin.rgbaAt(39, 52) & 0xff, 255); // base face made opaque
      expect(skin.rgbaAt(40, 32), 0); // right arm overlay absent
    });

    test('all 12 legacy face copies mirror pixel order independently', () async {
      final raw = Uint8List(64 * 32 * 4);
      const regions = <(int, int, int, int, int, int)>[
        (4, 16, 4, 4, 20, 48),
        (8, 16, 4, 4, 24, 48),
        (0, 20, 4, 12, 24, 52),
        (4, 20, 4, 12, 20, 52),
        (8, 20, 4, 12, 16, 52),
        (12, 20, 4, 12, 28, 52),
        (44, 16, 4, 4, 36, 48),
        (48, 16, 4, 4, 40, 48),
        (40, 20, 4, 12, 40, 52),
        (44, 20, 4, 12, 36, 52),
        (48, 20, 4, 12, 32, 52),
        (52, 20, 4, 12, 44, 52),
      ];
      for (var n = 0; n < regions.length; n++) {
        final r = regions[n];
        pixel(raw, r.$1, r.$2, 10 + n, 0, 0, 255);
        pixel(raw, r.$1 + r.$3 - 1, r.$2, 100 + n, 0, 0, 255);
      }
      final skin = await MtnMinecraftSkinTexture.fromPng(
        await pngFromRgba(raw, 64, 32),
        modelType: MtnMinecraftSkinModelType.classic,
      );
      for (var n = 0; n < regions.length; n++) {
        final r = regions[n];
        expect(skin.rgbaAt(r.$5 + r.$3 - 1, r.$6) >>> 24, 10 + n,
            reason: 'mirrored first source pixel of region $n');
        expect(skin.rgbaAt(r.$5, r.$6) >>> 24, 100 + n,
            reason: 'mirrored final source pixel of region $n');
      }
    });

    test('legacy fully opaque background clears obsolete hat layer', () async {
      final raw = Uint8List(64 * 32 * 4);
      for (var i = 3; i < raw.length; i += 4) raw[i] = 255;
      pixel(raw, 40, 8, 25, 60, 90, 255);
      final skin = await MtnMinecraftSkinTexture.fromPng(
        await pngFromRgba(raw, 64, 32),
        modelType: MtnMinecraftSkinModelType.classic,
      );
      expect(skin.rgbaAt(40, 8) & 0xff, 0);
      expect(skin.rgbaAt(8, 8) & 0xff, 255);
    });

    test('invalid PNG, dimensions and truncated input fail safely', () async {
      expect(
        MtnMinecraftSkinTexture.fromPng(
          Uint8List(50), modelType: MtnMinecraftSkinModelType.classic),
        throwsFormatException,
      );
      final invalidSize = await pngFromRgba(Uint8List(32 * 32 * 4), 32, 32);
      expect(
        MtnMinecraftSkinTexture.fromPng(
          invalidSize, modelType: MtnMinecraftSkinModelType.slim),
        throwsFormatException,
      );
      final invalidContent = await pngFromRgba(Uint8List(64 * 64 * 4), 64, 64);
      final truncated = Uint8List.sublistView(invalidContent, 0, 40);
      expect(
        MtnMinecraftSkinTexture.fromPng(
          truncated, modelType: MtnMinecraftSkinModelType.classic),
        throwsFormatException,
      );
    });

    test('out of bounds rgbaAt throws', () async {
      final skin = await MtnMinecraftSkinTexture.fromPng(
        await pngFromRgba(Uint8List(64 * 64 * 4), 64, 64),
        modelType: MtnMinecraftSkinModelType.classic);
      expect(() => skin.rgbaAt(64, 0), throwsRangeError);
      expect(() => skin.rgbaAt(0, -1), throwsRangeError);
    });
  });

  group('R2 Java cape PNG texture', () {
    test('preserves alpha and exposes independent pixel copy', () async {
      final raw = Uint8List(64 * 32 * 4);
      pixel(raw, 1, 1, 10, 20, 30, 127);
      final cape = await MtnMinecraftCapeTexture.fromPng(await pngFromRgba(raw, 64, 32));
      expect(cape.rgbaAt(1, 1) & 0xff, 127);
      cape.rgba[0] = 230;
      expect(cape.rgbaAt(0, 0), 0);
      expect(() => cape.rgbaAt(64, 0), throwsRangeError);
    });

    test('rejects non-64x32 cape', () async {
      final bad = await pngFromRgba(Uint8List(64 * 64 * 4), 64, 64);
      expect(MtnMinecraftCapeTexture.fromPng(bad), throwsFormatException);
    });
  });
}
