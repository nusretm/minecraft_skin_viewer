import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scene/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// R4-A synthetic six-face atlas UV smoke only. No outer mesh, cape, pivots,
/// animations or production widget contract is implied by this example.
class MtnMinecraftR4AMeshGallery extends StatefulWidget {
  const MtnMinecraftR4AMeshGallery({super.key});

  @override
  State<MtnMinecraftR4AMeshGallery> createState() => _MtnMinecraftR4AMeshGalleryState();
}

class _MtnMinecraftR4AMeshGalleryState extends State<MtnMinecraftR4AMeshGallery> {
  Scene? _scene;
  Object? _error;
  bool _ready = false;
  int _generation = 0;

  MtnMinecraftSkinModelType _model = MtnMinecraftSkinModelType.classic;
  double _yaw = -math.pi / 3;
  double _pitch = 0.15;
  double _distance = 3.7;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _changeModel(MtnMinecraftSkinModelType model) {
    if (_model == model) return;
    _generation++;
    _scene?.dispose();
    _scene = null;
    setState(() {
      _model = model;
      _ready = false;
      _error = null;
    });
    _initialize();
  }

  Future<void> _initialize() async {
    final generation = ++_generation;
    Scene? created;
    try {
      await Scene.initializeStaticResources();
      if (!mounted || generation != _generation) return;

      final png = await _syntheticFacePng(_model);
      final skin = await MtnMinecraftSkinTexture.fromPng(png, modelType: _model);
      if (!mounted || generation != _generation) return;

      created = Scene();
      final atlas = Texture2D.fromPixels(
        skin.rgba,
        MtnMinecraftSkinTexture.width,
        MtnMinecraftSkinTexture.height,
        sampling: const TextureSampling(
          mipmaps: false,
          minFilter: gpu.MinMagFilter.nearest,
          magFilter: gpu.MinMagFilter.nearest,
          maxAnisotropy: 1,
        ),
      );

      for (final part in MtnMinecraftSkinBodyPart.values) {
        final cpu = MtnMinecraftSkinBoxMesh.forBodyPart(part, skin.modelType);
        final center = MtnMinecraftSkinBoxMesh.centerFor(part, skin.modelType);
        final material = UnlitMaterial(colorTexture: atlas)
          ..baseColorFactor = vm.Vector4(1, 1, 1, 1);
        final node = Node(
          name: part.name,
          mesh: Mesh(
            MeshGeometry.fromArrays(
              positions: cpu.positions,
              normals: cpu.normals,
              texCoords: cpu.texCoords,
              indices: cpu.indices,
            ),
            material,
          ),
        )..position = vm.Vector3(center.x, center.y, center.z);
        created.add(node);
      }

      if (!mounted || generation != _generation) return;
      _scene = created;
      created = null; // widget now owns this scene
      setState(() => _ready = true);
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = error);
      }
    } finally {
      created?.dispose();
    }
  }

  Future<Uint8List> _syntheticFacePng(MtnMinecraftSkinModelType model) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final layout = MtnMinecraftSkinUvLayout(model);

    // Every used base face is uniquely identifiable. Mark the top-left,
    // top-right and bottom-left corners so UV mirroring is visible during
    // orbit. No original/copyrighted Minecraft asset is distributed.
    for (final part in MtnMinecraftSkinBodyPart.values) {
      for (final face in MtnMinecraftSkinFace.values) {
        final rect = layout.face(part, face);
        final color = ui.Color.fromARGB(
          255,
          55 + 31 * part.index,
          30 + 28 * face.index,
          20 + ((41 * part.index + 17 * face.index) % 225),
        );
        canvas.drawRect(
          ui.Rect.fromLTWH(
            rect.x.toDouble(), rect.y.toDouble(),
            rect.width.toDouble(), rect.height.toDouble(),
          ),
          ui.Paint()..color = color,
        );
        canvas.drawRect(
          ui.Rect.fromLTWH(rect.x.toDouble(), rect.y.toDouble(), 1, 1),
          ui.Paint()..color = const ui.Color(0xFFFFFFFF),
        );
        canvas.drawRect(
          ui.Rect.fromLTWH((rect.x + rect.width - 1).toDouble(),
            rect.y.toDouble(), 1, 1),
          ui.Paint()..color = const ui.Color(0xFFEE3333),
        );
        canvas.drawRect(
          ui.Rect.fromLTWH(
            rect.x.toDouble(), (rect.y + rect.height - 1).toDouble(), 1, 1),
          ui.Paint()..color = const ui.Color(0xFF3366FF),
        );
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(64, 64);
    picture.dispose();
    try {
      final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
      if (encoded == null) throw StateError('R4-A synthetic atlas PNG failed');
      return Uint8List.fromList(
        encoded.buffer.asUint8List(encoded.offsetInBytes, encoded.lengthInBytes));
    } finally {
      image.dispose();
    }
  }

  PerspectiveCamera _camera(Duration elapsed) {
    return PerspectiveCamera(
      position: vm.Vector3(
        _distance * math.sin(_yaw) * math.cos(_pitch),
        1 + _distance * math.sin(_pitch),
        _distance * math.cos(_yaw) * math.cos(_pitch),
      ),
      target: vm.Vector3(0, 1, 0),
    );
  }

  @override
  void dispose() {
    _generation++;
    _scene?.dispose();
    _scene = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('R4-A — 3D Atlas UV Check')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<MtnMinecraftSkinModelType>(
                  segments: const [
                    ButtonSegment(value: MtnMinecraftSkinModelType.classic,
                      label: Text('Classic')),
                    ButtonSegment(value: MtnMinecraftSkinModelType.slim,
                      label: Text('Slim')),
                  ],
                  selected: {_model},
                  onSelectionChanged: (selected) => _changeModel(selected.first),
                ),
                const Text('Drag: orbit · Mouse wheel: zoom · Colored corners: UV direction'),
              ],
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFF252B39),
              child: Center(
                child: _error != null
                    ? SelectableText('R4-A mesh error: $_error',
                        style: const TextStyle(color: Colors.redAccent))
                    : !_ready
                        ? const CircularProgressIndicator()
                        : Listener(
                            onPointerSignal: (event) {
                              if (event is PointerScrollEvent) {
                                setState(() {
                                  _distance = (_distance +
                                      event.scrollDelta.dy * 0.003).clamp(2.1, 7.0);
                                });
                              }
                            },
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) => setState(() {
                                _yaw -= details.delta.dx * 0.012;
                                _pitch = (_pitch + details.delta.dy * 0.008)
                                    .clamp(-1.1, 1.1);
                              }),
                              child: SizedBox.expand(child: SceneView(
                                _scene!, cameraBuilder: _camera)),
                            ),
                          ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('R4-A only: BASE skin faces and neutral pose. '
                'Outer layers, cape, joints, animation and public 3D widget come in R4-B/C/D.'),
          ),
        ],
      ),
    );
  }
}
