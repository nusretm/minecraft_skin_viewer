import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart';

Future<Uint8List> _fixturePng(Uint8List rgba, int width, int height) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer, width: width, height: height, pixelFormat: ui.PixelFormat.rgba8888);
  final codec = await descriptor.instantiateCodec();
  final image = (await codec.getNextFrame()).image;
  try {
    final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
    if (encoded == null) throw StateError('Fixture PNG encode failed');
    return Uint8List.fromList(
      encoded.buffer.asUint8List(encoded.offsetInBytes, encoded.lengthInBytes));
  } finally {
    image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
  }
}

void _fill(
  Uint8List rgba, int atlasWidth, MtnMinecraftSkinUvRect r,
  int red, int green, int blue, int alpha,
) {
  for (var y = r.y; y < r.y + r.height; y++) {
    for (var x = r.x; x < r.x + r.width; x++) {
      final i = (y * atlasWidth + x) * 4;
      rgba[i] = red;
      rgba[i + 1] = green;
      rgba[i + 2] = blue;
      rgba[i + 3] = alpha;
    }
  }
}

Future<MtnMinecraftSkinTexture> _skin(
  MtnMinecraftSkinModelType model, {
  bool legacy = false,
  bool alternate = false,
}) async {
  const atlasWidth = 64;
  final raw = Uint8List(atlasWidth * (legacy ? 32 : 64) * 4);
  final layout = MtnMinecraftSkinUvLayout(model);
  for (final part in MtnMinecraftSkinBodyPart.values) {
    if (legacy && (part == MtnMinecraftSkinBodyPart.leftArm ||
        part == MtnMinecraftSkinBodyPart.leftLeg)) continue;
    for (final face in [MtnMinecraftSkinFace.front, MtnMinecraftSkinFace.back]) {
      final index = part.index;
      // Red channel encodes identity of each body part; green = rear view.
      _fill(raw, atlasWidth, layout.face(part, face), alternate ? 180 : index * 32 + 20,
          face == MtnMinecraftSkinFace.front ? 0 : 180, 0, 255);
      if (!legacy) {
        // Outer layer: only the leftmost column opaque blue. Leave rest
        // transparent to ensure that base skin is visible behind it.
        final r = layout.face(part, face, layer: MtnMinecraftSkinLayer.outer);
        _fill(raw, atlasWidth,
            MtnMinecraftSkinUvRect(r.x, r.y, 1, r.height), 0, 0, 255, 255);
      }
    }
  }
  return MtnMinecraftSkinTexture.fromPng(
    await _fixturePng(raw, atlasWidth, legacy ? 32 : 64), modelType: model);
}

Future<MtnMinecraftCapeTexture> _cape() async {
  final raw = Uint8List(64 * 32 * 4);
  const layout = MtnMinecraftCapeUvLayout();
  _fill(raw, 64, layout.face(MtnMinecraftSkinFace.front), 200, 20, 20, 255);
  _fill(raw, 64, layout.face(MtnMinecraftSkinFace.back), 20, 200, 20, 255);
  return MtnMinecraftCapeTexture.fromPng(await _fixturePng(raw, 64, 32));
}

const _boundaryKey = ValueKey('preview-boundary');

Future<Uint8List> _capture(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey));
  final image = await boundary.toImage(pixelRatio: 1);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) throw StateError('Pixel capture failed');
    return Uint8List.fromList(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
  } finally {
    image.dispose();
  }
}

(int, int, int, int) _pixel(Uint8List bytes, int width, int x, int y) {
  final i = (y * width + x) * 4;
  return (bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]);
}

Future<void> _show(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(key: _boundaryKey, child: child),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('head front/back and outer-layer toggle read R2 face rectangles',
      (tester) async {
    final skin = await _skin(MtnMinecraftSkinModelType.classic);
    await _show(tester, MtnMinecraftSkinHead(
      texture: skin, size: 8, showOuterLayer: false));
    final front = await _capture(tester);
    expect(_pixel(front, 8, 0, 0), (20, 0, 0, 255));

    await _show(tester, MtnMinecraftSkinHead(
      texture: skin, size: 8, showOuterLayer: true));
    final overlay = await _capture(tester);
    expect(_pixel(overlay, 8, 0, 0), (0, 0, 255, 255));
    expect(_pixel(overlay, 8, 1, 0), (20, 0, 0, 255));

    await _show(tester, MtnMinecraftSkinHead(
      texture: skin, size: 8, view: MtnMinecraftSkinView.back,
      showOuterLayer: false));
    final back = await _capture(tester);
    expect(_pixel(back, 8, 0, 0), (20, 180, 0, 255));
  });

  testWidgets('Classic full body has correct front and rear limb ordering',
      (tester) async {
    final skin = await _skin(MtnMinecraftSkinModelType.classic);
    await _show(tester, MtnMinecraftSkinPreview(
      texture: skin, height: 32, showOuterLayer: false));
    final front = await _capture(tester);
    expect(_pixel(front, 16, 0, 9), (84, 0, 0, 255));   // rightArm index 2
    expect(_pixel(front, 16, 12, 9), (116, 0, 0, 255)); // leftArm index 3
    expect(_pixel(front, 16, 4, 9), (52, 0, 0, 255));   // body index 1
    expect(_pixel(front, 16, 4, 21), (148, 0, 0, 255)); // rightLeg index 4
    expect(_pixel(front, 16, 8, 21), (180, 0, 0, 255)); // leftLeg index 5

    await _show(tester, MtnMinecraftSkinPreview(
      texture: skin, height: 32, view: MtnMinecraftSkinView.back,
      showOuterLayer: false));
    final back = await _capture(tester);
    expect(_pixel(back, 16, 0, 9), (116, 180, 0, 255)); // leftArm
    expect(_pixel(back, 16, 12, 9), (84, 180, 0, 255)); // rightArm
    expect(_pixel(back, 16, 4, 21), (180, 180, 0, 255)); // leftLeg
  });

  testWidgets('Slim arms preserve 3px width and transparent outer pixels',
      (tester) async {
    final slim = await _skin(MtnMinecraftSkinModelType.slim);
    await _show(tester, MtnMinecraftSkinPreview(
      texture: slim, height: 32, showOuterLayer: true));
    final bytes = await _capture(tester);
    // x=0 is intentionally outside the 3px right arm: 1..3
    expect(_pixel(bytes, 16, 0, 9).$4, 0);
    expect(_pixel(bytes, 16, 1, 9), (0, 0, 255, 255)); // sleeve
    expect(_pixel(bytes, 16, 2, 9), (84, 0, 0, 255)); // base
    expect(_pixel(bytes, 16, 12, 9), (0, 0, 255, 255));
    expect(_pixel(bytes, 16, 15, 9).$4, 0);
  });

  testWidgets('legacy 64x32 skin projects mirrored left arm and leg',
      (tester) async {
    final skin = await _skin(MtnMinecraftSkinModelType.classic, legacy: true);
    expect(skin.isLegacy, isTrue);
    await _show(tester, MtnMinecraftSkinPreview(
      texture: skin, height: 32, showOuterLayer: false));
    final bytes = await _capture(tester);
    expect(_pixel(bytes, 16, 0, 9).$1, 84);
    expect(_pixel(bytes, 16, 12, 9).$1, 84);
    expect(_pixel(bytes, 16, 4, 21).$1, 148);
    expect(_pixel(bytes, 16, 8, 21).$1, 148);
  });

  testWidgets('cape preview switches between outer/back and inner/front',
      (tester) async {
    final cape = await _cape();
    await _show(tester, MtnMinecraftCapePreview(texture: cape, height: 16));
    final back = await _capture(tester);
    expect(_pixel(back, 10, 0, 0), (20, 200, 20, 255));

    await _show(tester, MtnMinecraftCapePreview(
      texture: cape, height: 16, view: MtnMinecraftSkinView.front));
    final front = await _capture(tester);
    expect(_pixel(front, 10, 0, 0), (200, 20, 20, 255));
  });

  testWidgets('head remains nearest-neighbor sharp at sizes 32, 64, 128, 256',
      (tester) async {
    final skin = await _skin(MtnMinecraftSkinModelType.classic);
    for (final size in [32.0, 64.0, 128.0, 256.0]) {
      await _show(tester, MtnMinecraftSkinHead(
        texture: skin, size: size, showOuterLayer: true));
      final pixels = await _capture(tester);
      final factor = size.toInt() ~/ 8;
      expect(_pixel(pixels, size.toInt(), 0, 0), (0, 0, 255, 255));
      expect(_pixel(pixels, size.toInt(), factor - 1, factor - 1), (0, 0, 255, 255));
      expect(_pixel(pixels, size.toInt(), factor, 0), (20, 0, 0, 255));
      expect(_pixel(pixels, size.toInt(), factor * 2 - 1, 0), (20, 0, 0, 255));
    }
  });

  testWidgets('changing texture invalidates image, toggles do not, and unmount is safe',
      (tester) async {
    final first = await _skin(MtnMinecraftSkinModelType.classic);
    final second = await _skin(MtnMinecraftSkinModelType.classic, alternate: true);
    await _show(tester, MtnMinecraftSkinHead(
      texture: first, size: 8, showOuterLayer: false));
    expect(_pixel(await _capture(tester), 8, 1, 0), (20, 0, 0, 255));
    await _show(tester, MtnMinecraftSkinHead(
      texture: second, size: 8, showOuterLayer: false));
    expect(_pixel(await _capture(tester), 8, 1, 0), (180, 0, 0, 255));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
