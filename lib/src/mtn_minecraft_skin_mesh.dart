import 'dart:typed_data';

import 'mtn_minecraft_skin_uv.dart';

/// Renderer-neutral Minecraft Java player cuboid, with 24 independent
/// vertices (four per face) and 12 outward-facing triangles.
///
/// Geometry is centered at the origin and measured in world units where one
/// Minecraft model pixel is 1/16 unit. Call [centerFor] for the neutral
/// standing-pose placement. GPU backends own the mesh upload and lifespan.
///
/// Coordinates: +Y up, +Z front (facing the viewer), +X to the model's left.
/// Texture UV coordinates have a top-left image origin like R2 and glTF.
class MtnMinecraftSkinBoxMesh {
  MtnMinecraftSkinBoxMesh._(
    this.part,
    this.modelType,
    this.layer,
    Float32List positions,
    Float32List normals,
    Float32List texCoords,
    List<int> indices,
  ) : _positions = positions,
      _normals = normals,
      _texCoords = texCoords,
      _indices = List<int>.unmodifiable(indices);

  final MtnMinecraftSkinBodyPart part;
  final MtnMinecraftSkinModelType modelType;
  final MtnMinecraftSkinLayer layer;

  final Float32List _positions;
  final Float32List _normals;
  final Float32List _texCoords;
  final List<int> _indices;

  /// Defensive snapshots: callers cannot corrupt a second renderer upload.
  Float32List get positions => Float32List.fromList(_positions);
  Float32List get normals => Float32List.fromList(_normals);
  Float32List get texCoords => Float32List.fromList(_texCoords);
  List<int> get indices => _indices;

  static const double modelPixel = 1 / 16;

  /// Builds a cuboid for either R2 skin layer, including all six atlas faces.
  ///
  /// Outer mesh faces are independently inflated by half a model pixel for
  /// hats and one quarter model pixel for jacket/sleeves/trousers. UV regions
  /// still have the *base* face dimensions, so the pixels stretch over the
  /// slightly larger shell without bleeding into adjacent atlas cells.
  factory MtnMinecraftSkinBoxMesh.forBodyPart(
    MtnMinecraftSkinBodyPart part,
    MtnMinecraftSkinModelType modelType, {
    MtnMinecraftSkinLayer layer = MtnMinecraftSkinLayer.base,
  }) {
    final layout = MtnMinecraftSkinUvLayout(modelType);
    final dimensions = layout.dimensions(part);
    final inflation = layer == MtnMinecraftSkinLayer.outer
        ? (part == MtnMinecraftSkinBodyPart.head ? 0.5 : 0.25)
        : 0.0;
    final halfX = (dimensions.width / 2 + inflation) * modelPixel;
    final halfY = (dimensions.height / 2 + inflation) * modelPixel;
    final halfZ = (dimensions.depth / 2 + inflation) * modelPixel;

    // Vertex order for each face: face-local top-left, top-right,
    // bottom-right, bottom-left as viewed from outside the cuboid.
    // The R2 normalizedCorners order maps 1:1 to these vertices.
    const faceOrder = <MtnMinecraftSkinFace>[
      MtnMinecraftSkinFace.back,
      MtnMinecraftSkinFace.right,
      MtnMinecraftSkinFace.front,
      MtnMinecraftSkinFace.left,
      MtnMinecraftSkinFace.top,
      MtnMinecraftSkinFace.bottom,
    ];
    final positions = Float32List(24 * 3);
    final normals = Float32List(24 * 3);
    final texCoords = Float32List(24 * 2);
    final indices = <int>[];

    final corners = <List<double>>[
      [-halfX, -halfY, -halfZ], // 0
      [halfX, -halfY, -halfZ],  // 1
      [halfX, halfY, -halfZ],   // 2
      [-halfX, halfY, -halfZ],  // 3
      [-halfX, -halfY, halfZ],  // 4
      [halfX, -halfY, halfZ],   // 5
      [halfX, halfY, halfZ],    // 6
      [-halfX, halfY, halfZ],   // 7
    ];
    // Each quad is TL, TR, BR, BL, from the outside looking toward center.
    // This intentionally differs from the generic CuboidGeometry vertex
    // order: the mapping avoids accidental top/back/side UV mirroring.
    const vertexCorners = <MtnMinecraftSkinFace, List<int>>{
      MtnMinecraftSkinFace.back: [2, 3, 0, 1],
      MtnMinecraftSkinFace.right: [6, 2, 1, 5],
      MtnMinecraftSkinFace.front: [7, 6, 5, 4],
      MtnMinecraftSkinFace.left: [3, 7, 4, 0],
      MtnMinecraftSkinFace.top: [3, 2, 6, 7],
      MtnMinecraftSkinFace.bottom: [4, 5, 1, 0],
    };
    const faceNormals = <MtnMinecraftSkinFace, List<double>>{
      MtnMinecraftSkinFace.back: [0, 0, -1],
      MtnMinecraftSkinFace.right: [1, 0, 0],
      MtnMinecraftSkinFace.front: [0, 0, 1],
      MtnMinecraftSkinFace.left: [-1, 0, 0],
      MtnMinecraftSkinFace.top: [0, 1, 0],
      MtnMinecraftSkinFace.bottom: [0, -1, 0],
    };

    for (var faceIndex = 0; faceIndex < faceOrder.length; faceIndex++) {
      final face = faceOrder[faceIndex];
      final four = vertexCorners[face]!;
      final normal = faceNormals[face]!;
      final uv = layout.face(part, face, layer: layer).normalizedCorners(
        MtnMinecraftSkinUvLayout.atlasWidth,
        MtnMinecraftSkinUvLayout.atlasHeight,
      );
      for (var corner = 0; corner < 4; corner++) {
        final index = faceIndex * 4 + corner;
        positions.setRange(index * 3, index * 3 + 3, corners[four[corner]]);
        normals.setRange(index * 3, index * 3 + 3, normal);
        texCoords[index * 2] = uv[corner].x;
        texCoords[index * 2 + 1] = uv[corner].y;
      }
      final vertex = faceIndex * 4;
      // Counterclockwise outward triangles matching flutter_scene's
      // buildCuboidArrays convention, verified using cross-product tests.
      indices.addAll([
        vertex, vertex + 3, vertex + 1,
        vertex + 3, vertex + 2, vertex + 1,
      ]);
    }

    return MtnMinecraftSkinBoxMesh._(
      part, modelType, layer, positions, normals, texCoords, indices);
  }

  /// Default standing model centers, with soles at y=0 and head top at y=2.
  ///
  /// R4-C will replace these static offsets with shoulder/hip pivot hierarchy
  /// and pose transforms; no additional source of truth for atlas/part size.
  static ({double x, double y, double z}) centerFor(
    MtnMinecraftSkinBodyPart part,
    MtnMinecraftSkinModelType modelType,
  ) {
    final armWidth = MtnMinecraftSkinUvLayout(modelType)
        .dimensions(MtnMinecraftSkinBodyPart.rightArm).width.toDouble();
    return switch (part) {
      MtnMinecraftSkinBodyPart.head => (x: 0, y: 1.75, z: 0),
      MtnMinecraftSkinBodyPart.body => (x: 0, y: 1.125, z: 0),
      MtnMinecraftSkinBodyPart.rightArm =>
        (x: -(4 + armWidth / 2) * modelPixel, y: 1.125, z: 0),
      MtnMinecraftSkinBodyPart.leftArm =>
        (x: (4 + armWidth / 2) * modelPixel, y: 1.125, z: 0),
      MtnMinecraftSkinBodyPart.rightLeg => (x: -0.125, y: 0.375, z: 0),
      MtnMinecraftSkinBodyPart.leftLeg => (x: 0.125, y: 0.375, z: 0),
    };
  }
}
