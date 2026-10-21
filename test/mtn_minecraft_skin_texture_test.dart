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
      expect(skin.rgbaAt(8, 8), 0x0A141EFF);
      expect(skin.rgbaAt(40, 8), 0x46505A7B);
      expect(skin.rgbaAt(20, 36), 0x0B162158);
      expect(skin.rgbaAt(63, 63), 0x0506072A);
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
      invalidContent[35] ^= 0xff; // corrupt the encoded PNG IDAT payload
      expect(
        MtnMinecraftSkinTexture.fromPng(
          invalidContent, modelType: MtnMinecraftSkinModelType.classic),
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
      expect(cape.rgbaAt(1, 1), 0x0A141E7F);
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
