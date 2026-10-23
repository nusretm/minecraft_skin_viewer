import 'dart:typed_data';
import 'dart:ui' as ui;

import 'mtn_minecraft_skin_uv.dart';

/// Normalized Java Edition skin atlas. Accessors never expose mutable storage.
///
/// PNG bytes are decoded only after a strict 64x64 / 64x32 IHDR preflight.
/// Modern skins use heuristic Classic/Slim inference unless [modelType] is
/// explicitly supplied to [fromPng]. Legacy 64x32 defaults to Classic.
/// Legacy right-side limb artwork is mirrored per face into a 64x64 atlas.
class MtnMinecraftSkinTexture {
  MtnMinecraftSkinTexture._(
    this.modelType,
    this.isLegacy,
    Uint8List pixels,
  ) : _pixels = pixels;

  static const int width = 64;
  static const int height = 64;

  final MtnMinecraftSkinModelType modelType;
  final bool isLegacy;
  final Uint8List _pixels;

  Uint8List get rgba => Uint8List.fromList(_pixels);

  /// Color packed as 0xRRGGBBAA; keeps pixel assertions renderer-independent.
  int rgbaAt(int x, int y) => _rgbaAt(_pixels, width, height, x, y);

  static Future<MtnMinecraftSkinTexture> fromPng(
    Uint8List png, {
    MtnMinecraftSkinModelType? modelType,
  }) async {
    final header = _MtnMinecraftPng.decodeHeader(png);
    if (header.width != 64 || (header.height != 64 && header.height != 32)) {
      throw FormatException('Java skin must be a 64x64 or 64x32 PNG.');
    }

    final source = await _MtnMinecraftPng.decodePixels(png, header);
    final legacy = header.height == 32;
    // Inspect the original decoded RGBA before base-face alpha normalization.
    // Legacy 64x32 skins use Classic geometry; explicit selection always wins.
    final resolvedModelType = modelType ?? (legacy
        ? MtnMinecraftSkinModelType.classic
        : _inferSkinModelType(source));
    final output = Uint8List(width * height * 4);
    output.setRange(0, source.length, source);
    if (legacy) {
      // Left leg and left arm do not exist in old atlases; they are mirrored
      // from the right limb, with left/right SIDE faces interchanged.
      const copies = <(int, int, int, int, int, int)>[
        (4, 16, 4, 4, 20, 48),   // leg top
        (8, 16, 4, 4, 24, 48),   // leg bottom
        (0, 20, 4, 12, 24, 52),  // leg outer / left side
        (4, 20, 4, 12, 20, 52),  // leg front
        (8, 20, 4, 12, 16, 52),  // leg inner / right side
        (12, 20, 4, 12, 28, 52), // leg back
        (44, 16, 4, 4, 36, 48),  // arm top
        (48, 16, 4, 4, 40, 48),  // arm bottom
        (40, 20, 4, 12, 40, 52), // arm outer / left side
        (44, 20, 4, 12, 36, 52), // arm front
        (48, 20, 4, 12, 32, 52), // arm inner / right side
        (52, 20, 4, 12, 44, 52), // arm back
      ];
      for (final region in copies) {
        _mirrorRegion(
          source, output,
          region.$1, region.$2, region.$3, region.$4, region.$5, region.$6,
        );
      }

      // Pre-1.8 fully opaque files often carry a solid unused hat background.
      // Only clear that legacy hat when the *entire* original is opaque.
      // Modern outer layers may intentionally be fully opaque and are kept.
      var fullyOpaque = true;
      for (var i = 3; i < source.length; i += 4) {
        if (source[i] != 255) {
          fullyOpaque = false;
          break;
        }
      }
      if (fullyOpaque) {
        final uv = const MtnMinecraftSkinUvLayout(MtnMinecraftSkinModelType.classic);
        for (final face in MtnMinecraftSkinFace.values) {
          final rect = uv.face(
            MtnMinecraftSkinBodyPart.head, face,
            layer: MtnMinecraftSkinLayer.outer,
          );
          for (var y = rect.y; y < rect.y + rect.height; y++) {
            for (var x = rect.x; x < rect.x + rect.width; x++) {
              output[(y * width + x) * 4 + 3] = 0;
            }
          }
        }
      }
    }

    // Minecraft base faces are opaque, but overlays retain alpha. Do not
    // affect unused atlas cells. Detection already used the original pixels.
    final uv = MtnMinecraftSkinUvLayout(resolvedModelType);
    for (final part in MtnMinecraftSkinBodyPart.values) {
      for (final face in MtnMinecraftSkinFace.values) {
        final rect = uv.face(part, face);
        for (var y = rect.y; y < rect.y + rect.height; y++) {
          for (var x = rect.x; x < rect.x + rect.width; x++) {
            output[(y * width + x) * 4 + 3] = 255;
          }
        }
      }
    }
    return MtnMinecraftSkinTexture._(resolvedModelType, legacy, output);
  }
}

// Adapted from bs-community/skinview-utils inferModelType() (MIT license).
// https://github.com/bs-community/skinview-utils/blob/master/src/process.ts
// See docs/third_party/SKINVIEW_UTILS_LICENSE.md for its copyright notice.
// Slim arm UVs leave four regions unused by the 3-pixel-wide arm geometry.
const _slimUnusedRegions = <(int, int, int, int)>[
  (50, 16, 2, 4), (54, 20, 2, 12),
  (42, 48, 2, 4), (46, 52, 2, 12),
];

MtnMinecraftSkinModelType _inferSkinModelType(Uint8List pixels) {
  for (final region in _slimUnusedRegions) {
    if (_regionHasTransparency(pixels, region)) {
      return MtnMinecraftSkinModelType.slim;
    }
  }

  // Some exporters fill every unused Slim arm cell with opaque black/white.
  for (final color in const [0, 255]) {
    if (_slimUnusedRegions.every((region) => _regionIsOpaqueColor(pixels, region, color))) {
      return MtnMinecraftSkinModelType.slim;
    }
  }

  return MtnMinecraftSkinModelType.classic;
}

bool _regionHasTransparency(Uint8List pixels, (int, int, int, int) region) {
  final (x, y, width, height) = region;
  for (var row = y; row < y + height; row++) {
    for (var col = x; col < x + width; col++) {
      if (pixels[(row * 64 + col) * 4 + 3] != 255) return true;
    }
  }
  return false;
}

bool _regionIsOpaqueColor(Uint8List pixels, (int, int, int, int) region, int color) {
  final (x, y, width, height) = region;
  for (var row = y; row < y + height; row++) {
    for (var col = x; col < x + width; col++) {
      final offset = (row * 64 + col) * 4;
      if (pixels[offset] != color || pixels[offset + 1] != color ||
          pixels[offset + 2] != color || pixels[offset + 3] != 255) return false;
    }
  }
  return true;
}

/// Strict Java 64x32 cape texture. Renderer-specific cape mesh is later work.
class MtnMinecraftCapeTexture {
  MtnMinecraftCapeTexture._(this._pixels);

  static const int width = 64;
  static const int height = 32;
  final Uint8List _pixels;

  Uint8List get rgba => Uint8List.fromList(_pixels);
  int rgbaAt(int x, int y) => _rgbaAt(_pixels, width, height, x, y);

  static Future<MtnMinecraftCapeTexture> fromPng(Uint8List png) async {
    final header = _MtnMinecraftPng.decodeHeader(png);
    if (header.width != width || header.height != height) {
      throw FormatException('Java cape must be a 64x32 PNG.');
    }
    return MtnMinecraftCapeTexture._(await _MtnMinecraftPng.decodePixels(png, header));
  }
}

int _rgbaAt(Uint8List pixels, int width, int height, int x, int y) {
  if (x < 0 || x >= width || y < 0 || y >= height) {
    throw RangeError('Pixel ($x,$y) is outside the $width x $height atlas.');
  }
  final i = (y * width + x) * 4;
  return (pixels[i] << 24) | (pixels[i + 1] << 16) |
      (pixels[i + 2] << 8) | pixels[i + 3];
}

void _mirrorRegion(
  Uint8List source,
  Uint8List destination,
  int sx, int sy, int w, int h, int dx, int dy,
) {
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final from = ((sy + y) * 64 + sx + x) * 4;
      final to = ((dy + y) * 64 + dx + w - 1 - x) * 4;
      destination.setRange(to, to + 4, source, from);
    }
  }
}

typedef _MtnPngHeader = ({int width, int height});

class _MtnMinecraftPng {
  static const _signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  static const _maxInputBytes = 4 * 1024 * 1024;

  static _MtnPngHeader decodeHeader(Uint8List bytes) {
    if (bytes.length < 33 || bytes.length > _maxInputBytes) {
      throw FormatException('Invalid or oversized PNG.');
    }
    for (var i = 0; i < _signature.length; i++) {
      if (bytes[i] != _signature[i]) throw FormatException('Expected PNG signature.');
    }
    final header = ByteData.sublistView(bytes);
    if (header.getUint32(8, Endian.big) != 13 ||
        bytes[12] != 73 || bytes[13] != 72 ||
        bytes[14] != 68 || bytes[15] != 82) {
      throw FormatException('Missing PNG IHDR.');
    }
    return (
      width: header.getUint32(16, Endian.big),
      height: header.getUint32(20, Endian.big),
    );
  }

  static Future<Uint8List> decodePixels(Uint8List png, _MtnPngHeader expected) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      image = frame.image;
      if (image.width != expected.width || image.height != expected.height) {
        throw FormatException('Decoded image size differs from PNG IHDR.');
      }
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
      if (pixels == null || pixels.lengthInBytes != image.width * image.height * 4) {
        throw FormatException('Could not decode PNG to RGBA8888.');
      }
      return Uint8List.fromList(pixels.buffer.asUint8List(
        pixels.offsetInBytes, pixels.lengthInBytes));
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Invalid PNG data: $error');
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }
}
