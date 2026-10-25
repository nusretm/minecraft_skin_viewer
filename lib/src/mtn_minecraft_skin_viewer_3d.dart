import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_scene/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'mtn_minecraft_skin_live_head_motion.dart';
import 'mtn_minecraft_skin_mesh.dart';
import 'mtn_minecraft_skin_pose_cape.dart';
import 'mtn_minecraft_skin_texture.dart';
import 'mtn_minecraft_skin_uv.dart';
import 'mtn_minecraft_skin_viewer_controller.dart';

/// Interactive Windows-first 3D Minecraft Java character.
///
/// The R2 skin texture (and optional cape) are already decoded; this widget
/// does not access local files or network APIs. GPU texture upload uses
/// straight RGBA and nearest-neighbor sampling. Place it in a bounded area.
/// Windows applications must enable Flutter GPU.
///
/// [controller] is the only authority for camera, pose and layer visibility;
/// it remains caller-owned when supplied and is widget-owned otherwise.
/// Skin/cape textures and interaction enablement are widget inputs.
/// A texture object change rebuilds the scene; controller changes never do.
class MtnMinecraftSkinViewer extends StatefulWidget {
  const MtnMinecraftSkinViewer({
    super.key,
    required this.texture,
    this.cape,
    this.controller,
    this.enableInteraction = true,
    this.onReady,
    this.onError,
  });

  final MtnMinecraftSkinTexture texture;
  final MtnMinecraftCapeTexture? cape;
  final MtnMinecraftSkinViewerController? controller;
  final bool enableInteraction;
  final VoidCallback? onReady;
  final ValueChanged<Object>? onError;

  @override
  State<MtnMinecraftSkinViewer> createState() => _MtnMinecraftSkinViewerState();
}

class _MtnMinecraftSkinViewerState extends State<MtnMinecraftSkinViewer>
    with SingleTickerProviderStateMixin {
  Scene? _scene;
  Object? _error;
  bool _ready = false;
  int _generation = 0;

  late MtnMinecraftSkinViewerController _camera;
  late bool _ownsCamera;
  late MtnMinecraftSkinPose _lastPose;
  late MtnMinecraftSkinPoseFrame _lastFrame;
  late final Ticker _ticker;
  final MtnMinecraftSkinLiveHeadMotion _liveHead = MtnMinecraftSkinLiveHeadMotion();
  Duration _lastTickElapsed = Duration.zero;
  Duration _poseStartElapsed = Duration.zero;
  final Map<MtnMinecraftSkinBodyPart, Node> _joints = {};
  final Map<MtnMinecraftSkinBodyPart, Node> _outers = {};
  Node? _capeHinge;

  @override
  void initState() {
    super.initState();
    _ownsCamera = widget.controller == null;
    _camera = widget.controller ?? MtnMinecraftSkinViewerController();
    _lastPose = _camera.pose;
    _lastFrame = MtnMinecraftSkinPoseFrame.at(_lastPose);
    _camera.addListener(_refreshController);
    _ticker = createTicker(_tick);
    _syncTicker();
    _createScene();
  }

  void _refreshController() {
    if (!mounted) return;
    // Pose transitions reset Live's head schedule and both arm axes.
    // Camera/layer updates never restart an active Live/Walk animation.
    if (_camera.pose != _lastPose) {
      _lastPose = _camera.pose;
      _poseStartElapsed = _lastTickElapsed;
      _liveHead.reset();
      _syncTicker();
      _applyPose(MtnMinecraftSkinPoseFrame.at(_camera.pose));
    }
    for (final node in _outers.values) {
      node.visible = _camera.showOuterLayer;
    }
    if (_capeHinge != null) {
      _capeHinge!.visible = _camera.showCape;
    }
    setState(() {});
  }

  void _syncTicker() {
    if (_camera.pose != MtnMinecraftSkinPose.idle) {
      if (!_ticker.isActive) {
        _lastTickElapsed = Duration.zero;
        _poseStartElapsed = Duration.zero;
        _ticker.start();
      }
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    if (!mounted) return;
    _lastTickElapsed = elapsed;
    if (!_ready || _camera.pose == MtnMinecraftSkinPose.idle) return;

    final seconds = math.max(0.0,
        (elapsed - _poseStartElapsed).inMicroseconds / 1000000);
    if (_camera.pose == MtnMinecraftSkinPose.live) {
      final look = _liveHead.anglesAt(seconds);
      _applyPose(MtnMinecraftSkinPoseFrame.at(
        _camera.pose, seconds: seconds,
        liveHeadYaw: look.yaw, liveHeadPitch: look.pitch,
      ));
    } else {
      _applyPose(MtnMinecraftSkinPoseFrame.at(_camera.pose, seconds: seconds));
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant MtnMinecraftSkinViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      _camera.removeListener(_refreshController);
      if (_ownsCamera) _camera.dispose();
      _ownsCamera = widget.controller == null;
      _camera = widget.controller ?? MtnMinecraftSkinViewerController();
      _lastPose = _camera.pose;
      _poseStartElapsed = _lastTickElapsed;
      _liveHead.reset();
      _camera.addListener(_refreshController);
      _syncTicker();
      _applyPose(MtnMinecraftSkinPoseFrame.at(_camera.pose));
      for (final node in _outers.values) {
        node.visible = _camera.showOuterLayer;
      }
      if (_capeHinge != null) {
        _capeHinge!.visible = _camera.showCape;
      }
    }
    if (!identical(widget.texture, oldWidget.texture) ||
        !identical(widget.cape, oldWidget.cape)) {
      _createScene();
    }
  }

  void _clearScene() {
    _scene?.dispose();
    _scene = null;
    _joints.clear();
    _outers.clear();
    _capeHinge = null;
    _ready = false;
  }

  Future<void> _createScene() async {
    final generation = ++_generation;
    _clearScene();
    _error = null;
    final skin = widget.texture;
    final cape = widget.cape;
    Scene? pending;
    try {
      await Scene.initializeStaticResources();
      if (!mounted || generation != _generation) return;
      pending = Scene();
      // R7-F1 temporary GPU seam diagnostics (opt-in via --dart-define).
      // User A/B: disabling AA removes head seams, but nearest compositing
      // alone does not. SMAA is a final comparison against the jagged-edge
      // tradeoff of no AA; a no-AA flag takes precedence if both are set.
      if (const bool.fromEnvironment('MTN_SKIN_SEAM_DISABLE_AA')) {
        pending.antiAliasingMode = AntiAliasingMode.none;
      } else if (const bool.fromEnvironment('MTN_SKIN_SEAM_SMAA')) {
        pending.antiAliasingMode = AntiAliasingMode.smaa;
      }
      if (const bool.fromEnvironment('MTN_SKIN_SEAM_NEAREST_COMPOSITE')) {
        pending.filterQuality = FilterQuality.none;
      }
      final skinAtlas = Texture2D.fromPixels(
        skin.rgba, MtnMinecraftSkinTexture.width, MtnMinecraftSkinTexture.height,
        sampling: const TextureSampling(
          mipmaps: false,
          minFilter: gpu.MinMagFilter.nearest,
          magFilter: gpu.MinMagFilter.nearest,
          maxAnisotropy: 1,
        ),
      );

      final joints = <MtnMinecraftSkinBodyPart, Node>{};
      final outers = <MtnMinecraftSkinBodyPart, Node>{};
      for (final layer in MtnMinecraftSkinLayer.values) {
        for (final part in MtnMinecraftSkinBodyPart.values) {
          final box = MtnMinecraftSkinBoxMesh.forBodyPart(
            part, skin.modelType, layer: layer);
          final center = MtnMinecraftSkinBoxMesh.centerFor(part, skin.modelType);
          final pivot = MtnMinecraftSkinPivot.forPart(part, skin.modelType);
          var joint = joints[part];
          if (joint == null) {
            joint = Node(name: part.name)
              ..position = vm.Vector3(pivot.x, pivot.y, pivot.z);
            pending.add(joint);
            joints[part] = joint;
          }
          final outer = layer == MtnMinecraftSkinLayer.outer;
          final material = UnlitMaterial(colorTexture: skinAtlas)
            ..baseColorFactor = vm.Vector4(1, 1, 1, 1)
            ..alphaMode = outer ? AlphaMode.blend : AlphaMode.opaque
            ..depthLayer = outer
                ? switch (part) {
                    MtnMinecraftSkinBodyPart.rightLeg => 3,
                    MtnMinecraftSkinBodyPart.rightArm ||
                    MtnMinecraftSkinBodyPart.leftArm ||
                    MtnMinecraftSkinBodyPart.leftLeg => 2,
                    _ => 1,
                  }
                : 0;
          final node = Node(
            name: [part.name, layer.name].join('/'),
            mesh: Mesh(MeshGeometry.fromArrays(
              positions: box.positions,
              normals: box.normals,
              // Sample *inside* each atlas face to avoid hairline seams at
              // shared UV borders. Canonical face UVs remain unchanged.
              texCoords: box.texCoordsWithInset(),
              indices: box.indices,
            ), material),
          )..position = vm.Vector3(
              center.x - pivot.x, center.y - pivot.y, center.z - pivot.z,
            );
          if (outer) {
            node.visible = _camera.showOuterLayer;
            node.renderOrder = 1;
            outers[part] = node;
          }
          joint.add(node);
        }
      }

      Node? hinge;
      if (cape != null) {
        final capeAtlas = Texture2D.fromPixels(
          cape.rgba, MtnMinecraftCapeTexture.width, MtnMinecraftCapeTexture.height,
          sampling: const TextureSampling(
            mipmaps: false,
            minFilter: gpu.MinMagFilter.nearest,
            magFilter: gpu.MinMagFilter.nearest,
            maxAnisotropy: 1,
          ),
        );
        final capeMesh = MtnMinecraftCapeBoxMesh.build();
        final capeMaterial = UnlitMaterial(colorTexture: capeAtlas)
          ..baseColorFactor = vm.Vector4(1, 1, 1, 1)
          ..alphaMode = AlphaMode.blend;
        hinge = Node(name: 'cape/hinge')
          ..position = vm.Vector3(
            MtnMinecraftSkinPivot.cape.x,
            MtnMinecraftSkinPivot.cape.y,
            MtnMinecraftSkinPivot.cape.z,
          )
          ..visible = _camera.showCape;
        hinge.add(Node(
          name: 'cape/fabric',
          mesh: Mesh(MeshGeometry.fromArrays(
            positions: capeMesh.positions,
            normals: capeMesh.normals,
            texCoords: capeMesh.texCoords,
            indices: capeMesh.indices,
          ), capeMaterial),
        )
          ..position = vm.Vector3(0, -0.5, -0.03125)
          ..renderOrder = 2);
        pending.add(hinge);
      }

      if (!mounted || generation != _generation) return;
      _scene = pending;
      pending = null; // This state now owns and later disposes the scene.
      _joints.addAll(joints);
      _outers.addAll(outers);
      _capeHinge = hinge;
      _applyPose(_lastFrame);
      _ready = true;
      setState(() {});
      widget.onReady?.call();
    } catch (error) {
      if (mounted && generation == _generation) {
        _error = error;
        setState(() {});
        widget.onError?.call(error);
      }
    } finally {
      // Disposes an asynchronous request superseded by a newer texture.
      pending?.dispose();
    }
  }

  void _applyPose(MtnMinecraftSkinPoseFrame frame) {
    _lastFrame = frame;
    final xAngles = <MtnMinecraftSkinBodyPart, double>{
      MtnMinecraftSkinBodyPart.rightArm: frame.rightArmX,
      MtnMinecraftSkinBodyPart.leftArm: frame.leftArmX,
      MtnMinecraftSkinBodyPart.rightLeg: frame.rightLegX,
      MtnMinecraftSkinBodyPart.leftLeg: frame.leftLegX,
    };
    for (final entry in xAngles.entries) {
      final z = switch (entry.key) {
        MtnMinecraftSkinBodyPart.rightArm => frame.rightArmZ,
        MtnMinecraftSkinBodyPart.leftArm => frame.leftArmZ,
        _ => 0.0,
      };
      _joints[entry.key]?.rotation =
          vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), entry.value) *
          vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), z);
    }
    // The head pivots at the neck and has two independent glance axes.
    _joints[MtnMinecraftSkinBodyPart.head]?.rotation =
        vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), frame.headYaw) *
        vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), frame.headPitch);
    _capeHinge?.rotation = vm.Quaternion.axisAngle(
      vm.Vector3(1, 0, 0), frame.capeX);
  }

  PerspectiveCamera _buildCamera(Duration elapsed) => PerspectiveCamera(
    position: vm.Vector3(
      _camera.distance * math.sin(_camera.yaw) * math.cos(_camera.pitch),
      1 + _camera.distance * math.sin(_camera.pitch),
      _camera.distance * math.cos(_camera.yaw) * math.cos(_camera.pitch),
    ),
    target: vm.Vector3(0, 1, 0),
  );

  @override
  void dispose() {
    _generation++;
    _ticker.dispose();
    _camera.removeListener(_refreshController);
    if (_ownsCamera) _camera.dispose();
    _clearScene();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error.toString(), textAlign: TextAlign.center));
    }
    if (!_ready || _scene == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // The viewer itself already requests a rebuild on camera changes and
    // on each Walk pose frame. A second SceneView ticker would continuously
    // redraw even an unchanged Idle character, generating avoidable GPU
    // work and transient allocations. SceneView explicitly supports a static
    // (non-autoTick) scene that repaints when its parent rebuilds.
    Widget content = SceneView(
      _scene!,
      cameraBuilder: _buildCamera,
      autoTick: false,
    );
    if (widget.enableInteraction) {
      content = Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            _camera.zoomBy(event.scrollDelta.dy);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) =>
              _camera.orbitBy(details.delta.dx, details.delta.dy),
          child: content,
        ),
      );
    }
    return SizedBox.expand(child: content);
  }
}
