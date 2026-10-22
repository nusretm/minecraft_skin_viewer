import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_scene/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

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
/// [controller] owns only camera orbit/zoom and is caller-owned when supplied.
/// Skin, cape, pose and visibility are unambiguous widget input state.
/// A texture object change rebuilds a scene; pose/visibility do not.
class MtnMinecraftSkinViewer extends StatefulWidget {
  const MtnMinecraftSkinViewer({
    super.key,
    required this.texture,
    this.cape,
    this.controller,
    this.pose = MtnMinecraftSkinPose.idle,
    this.showOuterLayer = true,
    this.showCape = true,
    this.enableInteraction = true,
    this.onReady,
    this.onError,
  });

  final MtnMinecraftSkinTexture texture;
  final MtnMinecraftCapeTexture? cape;
  final MtnMinecraftSkinViewerController? controller;
  final MtnMinecraftSkinPose pose;
  final bool showOuterLayer;
  final bool showCape;
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
  late final Ticker _ticker;
  final Map<MtnMinecraftSkinBodyPart, Node> _joints = {};
  final Map<MtnMinecraftSkinBodyPart, Node> _outers = {};
  Node? _capeHinge;

  @override
  void initState() {
    super.initState();
    _ownsCamera = widget.controller == null;
    _camera = widget.controller ?? MtnMinecraftSkinViewerController();
    _camera.addListener(_refreshCamera);
    _ticker = createTicker(_tick);
    _syncTicker();
    _createScene();
  }

  void _refreshCamera() {
    if (mounted) setState(() {});
  }

  void _syncTicker() {
    if (widget.pose == MtnMinecraftSkinPose.walk) {
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    if (!mounted || !_ready || widget.pose != MtnMinecraftSkinPose.walk) return;
    _applyPose(MtnMinecraftSkinPoseFrame.at(
      widget.pose, seconds: elapsed.inMicroseconds / 1000000,
    ));
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant MtnMinecraftSkinViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      _camera.removeListener(_refreshCamera);
      if (_ownsCamera) _camera.dispose();
      _ownsCamera = widget.controller == null;
      _camera = widget.controller ?? MtnMinecraftSkinViewerController();
      _camera.addListener(_refreshCamera);
    }
    if (!identical(widget.texture, oldWidget.texture) ||
        !identical(widget.cape, oldWidget.cape)) {
      _createScene();
      return;
    }
    if (widget.showOuterLayer != oldWidget.showOuterLayer) {
      for (final node in _outers.values) {
        node.visible = widget.showOuterLayer;
      }
    }
    if (widget.showCape != oldWidget.showCape && _capeHinge != null) {
      _capeHinge!.visible = widget.showCape;
    }
    if (widget.pose != oldWidget.pose) {
      _syncTicker();
      _applyPose(MtnMinecraftSkinPoseFrame.at(widget.pose));
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
              texCoords: box.texCoords,
              indices: box.indices,
            ), material),
          )..position = vm.Vector3(
              center.x - pivot.x, center.y - pivot.y, center.z - pivot.z,
            );
          if (outer) {
            node.visible = widget.showOuterLayer;
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
          ..visible = widget.showCape;
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
      _applyPose(MtnMinecraftSkinPoseFrame.at(widget.pose));
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
    final angles = <MtnMinecraftSkinBodyPart, double>{
      MtnMinecraftSkinBodyPart.rightArm: frame.rightArmX,
      MtnMinecraftSkinBodyPart.leftArm: frame.leftArmX,
      MtnMinecraftSkinBodyPart.rightLeg: frame.rightLegX,
      MtnMinecraftSkinBodyPart.leftLeg: frame.leftLegX,
    };
    for (final entry in angles.entries) {
      _joints[entry.key]?.rotation = vm.Quaternion.axisAngle(
        vm.Vector3(1, 0, 0), entry.value);
    }
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
    _camera.removeListener(_refreshCamera);
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
