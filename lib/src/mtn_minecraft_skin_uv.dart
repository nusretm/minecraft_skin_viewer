import 'dart:math' show Point;

/// Java Edition player arm geometry. PNG dimensions never determine this value.
enum MtnMinecraftSkinModelType { classic, slim }

enum MtnMinecraftSkinBodyPart {
  head,
  body,
  rightArm,
  leftArm,
  rightLeg,
  leftLeg,
}

enum MtnMinecraftSkinLayer { base, outer }

/// Spatial faces, not an implicit vertex/index-buffer ordering.
enum MtnMinecraftSkinFace { right, left, top, bottom, front, back }

/// One pixel-space face in a top-left-origin texture atlas.
///
/// [flipVertically] describes a face-local image orientation, not a Flutter
/// Canvas transform. Consumers must adapt their own mesh vertex order.
class MtnMinecraftSkinUvRect {
  const MtnMinecraftSkinUvRect(
    this.x,
    this.y,
    this.width,
    this.height, {
    this.flipVertically = false,
  });

  final int x;
  final int y;
  final int width;
  final int height;
  final bool flipVertically;

  /// Pixel corresponding to a local face coordinate (left to right, top down).
  Point<int> pixelAt(int column, int row) {
    if (column < 0 || column >= width || row < 0 || row >= height) {
      throw RangeError('Pixel ($column,$row) is outside a $width x $height face.');
    }
    return Point(x + column, y + (flipVertically ? height - 1 - row : row));
  }

  /// UV corners ordered face-local top-left, top-right, bottom-right, bottom-left.
  ///
  /// Coordinates are normalized with a top-left image origin. GPU adapters
  /// with bottom-left UV origins must invert V at their boundary.
  List<Point<double>> normalizedCorners(int atlasWidth, int atlasHeight) {
    if (atlasWidth <= 0 || atlasHeight <= 0) {
      throw ArgumentError('Atlas dimensions must be positive.');
    }
    final left = x / atlasWidth;
    final right = (x + width) / atlasWidth;
    final top = y / atlasHeight;
    final bottom = (y + height) / atlasHeight;
    return List.unmodifiable([
      Point(left, flipVertically ? bottom : top),
      Point(right, flipVertically ? bottom : top),
      Point(right, flipVertically ? top : bottom),
      Point(left, flipVertically ? top : bottom),
    ]);
  }
}

/// Minecraft box-net layout, with each face explicitly addressable.
///
/// [u]/[v] are the top-left of the box UV net, width/height/depth are
/// Minecraft pixels. This is independent of flutter_scene / Flutter GPU.
MtnMinecraftSkinUvRect mtnMinecraftBoxFace(
  int u,
  int v,
  int width,
  int height,
  int depth,
  MtnMinecraftSkinFace face,
) {
  if (width <= 0 || height <= 0 || depth <= 0) {
    throw ArgumentError('Box dimensions must be positive.');
  }
  return switch (face) {
    MtnMinecraftSkinFace.top => MtnMinecraftSkinUvRect(u + depth, v, width, depth),
    MtnMinecraftSkinFace.bottom => MtnMinecraftSkinUvRect(
        u + depth + width, v, width, depth, flipVertically: true),
    MtnMinecraftSkinFace.left => MtnMinecraftSkinUvRect(u, v + depth, depth, height),
    MtnMinecraftSkinFace.front => MtnMinecraftSkinUvRect(u + depth, v + depth, width, height),
    MtnMinecraftSkinFace.right => MtnMinecraftSkinUvRect(
        u + depth + width, v + depth, depth, height),
    MtnMinecraftSkinFace.back => MtnMinecraftSkinUvRect(
        u + 2 * depth + width, v + depth, width, height),
  };
}

/// Authoritative modern 64x64 skin-face coordinates for 2D and 3D consumers.
///
/// A 64x32 legacy skin must first be normalized to 64x64; both formats then
/// use this identical layout. The outer layer has the same dimensions as its
/// corresponding base part, while the renderer may enlarge the outer mesh.
class MtnMinecraftSkinUvLayout {
  const MtnMinecraftSkinUvLayout(this.modelType);

  final MtnMinecraftSkinModelType modelType;
  static const int atlasWidth = 64;
  static const int atlasHeight = 64;

  ({int width, int height, int depth}) dimensions(MtnMinecraftSkinBodyPart part) {
    return switch (part) {
      MtnMinecraftSkinBodyPart.head => (width: 8, height: 8, depth: 8),
      MtnMinecraftSkinBodyPart.body => (width: 8, height: 12, depth: 4),
      MtnMinecraftSkinBodyPart.rightArm ||
      MtnMinecraftSkinBodyPart.leftArm =>
        (width: modelType == MtnMinecraftSkinModelType.slim ? 3 : 4,
         height: 12, depth: 4),
      MtnMinecraftSkinBodyPart.rightLeg ||
      MtnMinecraftSkinBodyPart.leftLeg =>
        (width: 4, height: 12, depth: 4),
    };
  }

  MtnMinecraftSkinUvRect face(
    MtnMinecraftSkinBodyPart part,
    MtnMinecraftSkinFace face, {
    MtnMinecraftSkinLayer layer = MtnMinecraftSkinLayer.base,
  }) {
    final origin = switch ((part, layer)) {
      (MtnMinecraftSkinBodyPart.head, MtnMinecraftSkinLayer.base) => (0, 0),
      (MtnMinecraftSkinBodyPart.head, MtnMinecraftSkinLayer.outer) => (32, 0),
      (MtnMinecraftSkinBodyPart.body, MtnMinecraftSkinLayer.base) => (16, 16),
      (MtnMinecraftSkinBodyPart.body, MtnMinecraftSkinLayer.outer) => (16, 32),
      (MtnMinecraftSkinBodyPart.rightArm, MtnMinecraftSkinLayer.base) => (40, 16),
      (MtnMinecraftSkinBodyPart.rightArm, MtnMinecraftSkinLayer.outer) => (40, 32),
      (MtnMinecraftSkinBodyPart.leftArm, MtnMinecraftSkinLayer.base) => (32, 48),
      (MtnMinecraftSkinBodyPart.leftArm, MtnMinecraftSkinLayer.outer) => (48, 48),
      (MtnMinecraftSkinBodyPart.rightLeg, MtnMinecraftSkinLayer.base) => (0, 16),
      (MtnMinecraftSkinBodyPart.rightLeg, MtnMinecraftSkinLayer.outer) => (0, 32),
      (MtnMinecraftSkinBodyPart.leftLeg, MtnMinecraftSkinLayer.base) => (16, 48),
      (MtnMinecraftSkinBodyPart.leftLeg, MtnMinecraftSkinLayer.outer) => (0, 48),
    };
    final d = dimensions(part);
    return mtnMinecraftBoxFace(origin.$1, origin.$2, d.width, d.height, d.depth, face);
  }
}

/// Java 64x32 cape UV net (10x16 fabric with a one-pixel-thick edge).
class MtnMinecraftCapeUvLayout {
  const MtnMinecraftCapeUvLayout();

  static const int atlasWidth = 64;
  static const int atlasHeight = 32;

  MtnMinecraftSkinUvRect face(MtnMinecraftSkinFace face) =>
      mtnMinecraftBoxFace(0, 0, 10, 16, 1, face);
}
