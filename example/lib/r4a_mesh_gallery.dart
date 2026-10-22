import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scene/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// R4-A/B Windows skin mesh UV smoke. Synthetic atlas and optional local PNG.
/// No cape, joint pivots, animation or production viewer is provided here.
class MtnMinecraftR4AMeshGallery extends StatefulWidget {
  const MtnMinecraftR4AMeshGallery({super.key});

  @override
  State<MtnMinecraftR4AMeshGallery> createState() => _MtnMinecraftR4AMeshGalleryState();
}

class _MtnMinecraftR4AMeshGalleryState extends State<MtnMinecraftR4AMeshGallery> {
  // Local-only test convenience. This file is NOT committed or distributed.
  static const _defaultSkinPath =
      r'D:\development\cross-platform\9fede215f7cb6884.png';

  Scene? _scene;
  Object? _error;
  bool _ready = false;
  int _generation = 0;
  int _fileRequest = 0;
  bool _loadingFile = false;
  bool _showOuterLayers = true;
  Uint8List? _localPng;
  final TextEditingController _skinPathController = TextEditingController();
  Map<MtnMinecraftSkinBodyPart, Node> _outerNodes = {};

  MtnMinecraftSkinModelType _model = MtnMinecraftSkinModelType.classic;
  double _yaw = -math.pi / 3;
  double _pitch = 0.15;
  double _distance = 3.7;

  @override
  void initState() {
    super.initState();
    _skinPathController.text = _defaultSkinPath;
    _initializeDefaultSkin();
  }

  Future<void> _initializeDefaultSkin() async {
    // CI and other computers do not have this personal path. Use the
    // generated UV atlas there without requiring an external test asset.
    try {
      final file = io.File(_defaultSkinPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        await MtnMinecraftSkinTexture.fromPng(
          bytes, modelType: MtnMinecraftSkinModelType.slim);
        if (!mounted) return;
        _model = MtnMinecraftSkinModelType.slim;
        _localPng = bytes;
      }
    } catch (_) {
      // Missing/unreadable/invalid local fixture -> generated synthetic atlas.
    }
    if (!mounted) return;
    _initialize();
  }

  void _changeModel(MtnMinecraftSkinModelType model) {
    if (_model == model) return;
    _model = model;
    _rebuild();
  }

  /// Retains the user's orbit, zoom and overlay choice across model changes.
  /// Geometry and GPU atlas are recreated, but camera state is not reset.
  void _rebuild() {
    _generation++;
    _scene?.dispose();
    _scene = null;
    _outerNodes = {};
    setState(() {
      _ready = false;
      _error = null;
    });
    _initialize();
  }

  void _toggleOuterLayers(bool enabled) {
    for (final node in _outerNodes.values) {
      node.visible = enabled;
    }
    setState(() => _showOuterLayers = enabled);
  }

  Future<void> _loadLocalSkin() async {
    final request = ++_fileRequest;
    final path = _skinPathController.text.trim();
    if (path.isEmpty) return;
    setState(() => _loadingFile = true);
    try {
      final bytes = await io.File(path).readAsBytes();
      if (!mounted || request != _fileRequest) return;
      // The existing R2 decoder rejects invalid PNG dimensions/signatures.
      // Do not assume Classic/Slim from PNG dimensions: UI selection owns it.
      _localPng = bytes;
      _rebuild();
    } catch (error) {
      if (!mounted || request != _fileRequest) return;
      setState(() => _error = error);
    } finally {
      if (mounted && request == _fileRequest) {
        setState(() => _loadingFile = false);
      }
    }
  }

  void _useSynthetic() {
    _fileRequest++;
    _localPng = null;
    _rebuild();
    setState(() => _loadingFile = false);
  }

  Future<void> _initialize() async {
    final generation = ++_generation;
    final selectedModel = _model;
    final sourceBytes = _localPng;
    Scene? created;
    try {
      await Scene.initializeStaticResources();
      if (!mounted || generation != _generation) return;

      final png = sourceBytes ?? await _syntheticFacePng(selectedModel);
      final skin = await MtnMinecraftSkinTexture.fromPng(
        png, modelType: selectedModel);
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

      final outerNodes = <MtnMinecraftSkinBodyPart, Node>{};
      for (final layer in MtnMinecraftSkinLayer.values) {
        for (final part in MtnMinecraftSkinBodyPart.values) {
          final cpu = MtnMinecraftSkinBoxMesh.forBodyPart(
            part, skin.modelType, layer: layer);
          final center = MtnMinecraftSkinBoxMesh.centerFor(part, skin.modelType);
          final outer = layer == MtnMinecraftSkinLayer.outer;
          final material = UnlitMaterial(colorTexture: atlas)
            ..baseColorFactor = vm.Vector4(1, 1, 1, 1)
            ..alphaMode = outer ? AlphaMode.blend : AlphaMode.opaque
            // Minecraft's independently inflated jacket, sleeves and pants
            // overlap on coplanar front/back faces at touching joints.
            // flutter_scene 0.24.3 explicitly supports depthLayer as a
            // distance-independent deterministic tiebreak for these faces.
            // Keep the base at 0 and outer shells at 1/2 so nearby shells
            // do not fight while their UVs, shape and transparency stay intact.
            ..depthLayer = outer
                ? switch (part) {
                    MtnMinecraftSkinBodyPart.rightArm ||
                    MtnMinecraftSkinBodyPart.leftArm ||
                    MtnMinecraftSkinBodyPart.leftLeg => 2,
                    _ => 1,
                  }
                : 0;
          final node = Node(
            name: '${part.name}/${layer.name}',
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
          if (outer) {
            node.visible = _showOuterLayers;
            // The alpha-blended pass draws after the opaque base mesh.
            // Blend ordering between multiple transparent outer shells still
            // requires Windows GPU inspection from several camera angles.
            node.renderOrder = 1;
            outerNodes[part] = node;
          }
          created.add(node);
        }
      }

      if (!mounted || generation != _generation) return;
      _scene = created;
      _outerNodes = outerNodes;
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

    // Distinct, partially translucent shell patches prove that outer mesh
    // UVs do not sample the base skin and that transparent cells reveal it.
    for (final part in MtnMinecraftSkinBodyPart.values) {
      for (final face in MtnMinecraftSkinFace.values) {
        final rect = layout.face(part, face, layer: MtnMinecraftSkinLayer.outer);
        canvas.drawRect(
          ui.Rect.fromLTWH(rect.x.toDouble(), rect.y.toDouble(),
            1, rect.height.toDouble()),
          ui.Paint()..color = const ui.Color(0xBFFFCE33),
        );
        canvas.drawRect(
          ui.Rect.fromLTWH((rect.x + rect.width - 1).toDouble(),
            rect.y.toDouble(), 1, 1),
          ui.Paint()..color = const ui.Color(0xFF22FF88),
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
    _fileRequest++;
    _scene?.dispose();
    _scene = null;
    _outerNodes = {};
    _skinPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('R4-A/B — 3D Skin & Outer Layers')),
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
                FilterChip(
                  label: const Text('Outer layers'),
                  selected: _showOuterLayers,
                  onSelected: _toggleOuterLayers,
                ),
                Text(_localPng == null ? 'Synthetic UV atlas' : 'Local skin PNG'),
                const Text('Drag: orbit · Mouse wheel: zoom'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 380,
                  child: TextField(
                    controller: _skinPathController,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      labelText: 'Local Minecraft skin PNG path',
                      hintText: r'C:\path\to\skin.png',
                    ),
                    onSubmitted: (_) => _loadLocalSkin(),
                  ),
                ),
                ElevatedButton(
                  onPressed: _loadingFile ? null : _loadLocalSkin,
                  child: const Text('Load PNG'),
                ),
                OutlinedButton(
                  onPressed: _useSynthetic,
                  child: const Text('Use UV test atlas'),
                ),
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
            child: Text('R4-A/B: all base + expanded outer faces; optional local PNG, no networking. '
                'Cape, pivots, poses and public 3D widget remain R4-C/D.'),
          ),
        ],
      ),
    );
  }
}
