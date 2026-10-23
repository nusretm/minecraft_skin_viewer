import 'dart:math' as math;
import 'dart:typed_data';

import 'mtn_minecraft_skin_uv.dart';

/// A simple Minecraft Java cape: 10 wide, 16 tall and 1 model pixel thick.
///
/// Mesh coordinates are centered on the cape fabric. Scene placement and
/// hinge motion are the responsibility of the viewer, not the texture atlas.
class MtnMinecraftCapeBoxMesh {
  MtnMinecraftCapeBoxMesh._(
    this.positions,
    this.normals,
    this.texCoords,
    this.indices,
  );

  /// Caller-owned mesh arrays: this builder never retains or reuses them.
  final Float32List positions;
  final Float32List normals;
  final Float32List texCoords;
  final List<int> indices;

  static const double modelPixel = 1 / 16;
  static const double width = 10 * modelPixel;
  static const double height = 16 * modelPixel;
  static const double depth = modelPixel;

  factory MtnMinecraftCapeBoxMesh.build() {
    const halfX = width / 2;
    const halfY = height / 2;
    const halfZ = depth / 2;
    const faceOrder = <MtnMinecraftSkinFace>[
      MtnMinecraftSkinFace.back,
      MtnMinecraftSkinFace.right,
      MtnMinecraftSkinFace.front,
      MtnMinecraftSkinFace.left,
      MtnMinecraftSkinFace.top,
      MtnMinecraftSkinFace.bottom,
    ];
    final corners = <List<double>>[
      [-halfX, -halfY, -halfZ],
      [halfX, -halfY, -halfZ],
      [halfX, halfY, -halfZ],
      [-halfX, halfY, -halfZ],
      [-halfX, -halfY, halfZ],
      [halfX, -halfY, halfZ],
      [halfX, halfY, halfZ],
      [-halfX, halfY, halfZ],
    ];
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

    const uv = MtnMinecraftCapeUvLayout();
    final positions = Float32List(72);
    final normals = Float32List(72);
    final texCoords = Float32List(48);
    final indices = <int>[];
    for (var faceIndex = 0; faceIndex < faceOrder.length; faceIndex++) {
      final face = faceOrder[faceIndex];
      final vertices = vertexCorners[face]!;
      final normal = faceNormals[face]!;
      // The cape's decorated atlas 'front' is its outward-facing fabric
      // surface, which points toward -Z (the character's back) in our
      // character coordinate system. The atlas 'back' is the inner side,
      // pointing +Z toward the torso. Swap only these two source faces;
      // preserve geometry normals, winding, side UVs and hinge rotation.
      final atlasFace = switch (face) {
        MtnMinecraftSkinFace.back => MtnMinecraftSkinFace.front,
        MtnMinecraftSkinFace.front => MtnMinecraftSkinFace.back,
        _ => face,
      };
      final cornersUv = uv.face(atlasFace).normalizedCorners(
        MtnMinecraftCapeUvLayout.atlasWidth,
        MtnMinecraftCapeUvLayout.atlasHeight,
      );
      for (var corner = 0; corner < 4; corner++) {
        final index = faceIndex * 4 + corner;
        positions.setRange(index * 3, index * 3 + 3, corners[vertices[corner]]);
        normals.setRange(index * 3, index * 3 + 3, normal);
        // The outward (-Z) quad has reversed horizontal winding relative
        // to the Java cape atlas's decorated surface. After mapping the
        // correct source face, flip U within *that face only* to preserve
        // the left/right design seen on the original cape preview.
        // Leave V, the inner face and all thin-edge faces unchanged.
        final uvCorner = face == MtnMinecraftSkinFace.back
            ? switch (corner) { 0 => 1, 1 => 0, 2 => 3, _ => 2 }
            : corner;
        texCoords[index * 2] = cornersUv[uvCorner].x;
        texCoords[index * 2 + 1] = cornersUv[uvCorner].y;
      }
      final first = faceIndex * 4;
      indices.addAll([
        first, first + 3, first + 1,
        first + 3, first + 2, first + 1,
      ]);
    }
    return MtnMinecraftCapeBoxMesh._(
      positions, normals, texCoords, List<int>.unmodifiable(indices));
  }
}

/// Basic pose modes, deliberately without skeletal skinning or cloth physics.
enum MtnMinecraftSkinPose { idle, walk, live }

/// Local-axis pose rotations in radians for neck, shoulders, hips and cape.
/// Live adds shoulder outward/inward motion and head yaw/pitch without
/// changing the skeleton, skin atlas, or the existing Idle/Walk behavior.
class MtnMinecraftSkinPoseFrame {
  const MtnMinecraftSkinPoseFrame({
    required this.rightArmX,
    required this.leftArmX,
    required this.rightLegX,
    required this.leftLegX,
    required this.capeX,
    this.rightArmZ = 0,
    this.leftArmZ = 0,
    this.headYaw = 0,
    this.headPitch = 0,
  });

  final double rightArmX;
  final double leftArmX;
  final double rightArmZ;
  final double leftArmZ;
  final double rightLegX;
  final double leftLegX;
  final double capeX;
  final double headYaw;
  final double headPitch;

  factory MtnMinecraftSkinPoseFrame.at(
    MtnMinecraftSkinPose pose, {
    double seconds = 0,
    double liveHeadYaw = 0,
    double liveHeadPitch = 0,
  }) {
    if (!seconds.isFinite || !liveHeadYaw.isFinite || !liveHeadPitch.isFinite) {
      throw ArgumentError.value(seconds, 'seconds / liveHeadYaw / liveHeadPitch',
          'Pose inputs must be finite');
    }

    if (pose == MtnMinecraftSkinPose.idle) {
      return const MtnMinecraftSkinPoseFrame(
        rightArmX: 0, leftArmX: 0, rightLegX: 0, leftLegX: 0,
        capeX: 0.18);
    }

    if (pose == MtnMinecraftSkinPose.live) {
      // Half the cycle opens the shoulders (inhale), the second closes them
      // (exhale). The hands never cross into the torso.
      final breathPhase = seconds * 2 * math.pi / 3.8;
      final breath = (1 - math.cos(breathPhase)) / 2;
      final spread = 0.035 + breath * 0.085; // approximately 2–7 degrees.
      return MtnMinecraftSkinPoseFrame(
        rightArmX: 0, leftArmX: 0,
        rightArmZ: -spread, leftArmZ: spread,
        rightLegX: 0, leftLegX: 0,
        capeX: 0.18,
        headYaw: liveHeadYaw, headPitch: liveHeadPitch,
      );
    }

    // A relaxed walk cadence; limb swing amplitude remains unchanged.
    final phase = seconds * 2 * math.pi * 0.90;
    final swing = math.sin(phase) * 0.48;
    return MtnMinecraftSkinPoseFrame(
      rightArmX: swing,
      leftArmX: -swing,
      rightLegX: -swing,
      leftLegX: swing,
      capeX: 0.18 + (0.12 * (1 - math.cos(phase * 2))) / 2,
    );
  }
}

/// Standing-pose joint origin in world coordinates, with soles at y=0.
///
/// Meshes remain centered at their usual part center, but the GPU adapter
/// attaches each to a parent pivot so rotations happen at joints.
class MtnMinecraftSkinPivot {
  const MtnMinecraftSkinPivot._();

  static ({double x, double y, double z}) forPart(
    MtnMinecraftSkinBodyPart part,
    MtnMinecraftSkinModelType modelType,
  ) {
    final armWidth = MtnMinecraftSkinUvLayout(modelType)
        .dimensions(MtnMinecraftSkinBodyPart.rightArm).width;
    return switch (part) {
      MtnMinecraftSkinBodyPart.head => (x: 0, y: 1.5, z: 0),
      MtnMinecraftSkinBodyPart.body => (x: 0, y: 1.5, z: 0),
      MtnMinecraftSkinBodyPart.rightArm =>
        (x: -(4 + armWidth / 2) / 16, y: 1.5, z: 0),
      MtnMinecraftSkinBodyPart.leftArm =>
        (x: (4 + armWidth / 2) / 16, y: 1.5, z: 0),
      MtnMinecraftSkinBodyPart.rightLeg => (x: -0.125, y: 0.75, z: 0),
      MtnMinecraftSkinBodyPart.leftLeg => (x: 0.125, y: 0.75, z: 0),
    };
  }

  /// Cape hangs down from behind the back/shoulder line.
  static const ({double x, double y, double z}) cape =
      (x: 0, y: 1.5, z: -0.19);
}
