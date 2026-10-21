import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene/gpu.dart' as gpu;
import 'package:vector_math/vector_math.dart' as vm;

import 'r3_gallery.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MtnMinecraftRendererSmokeHost(),
  ));
}

/// R1-only mount/unmount harness for manual GPU lifecycle verification.
///
/// A frame without SceneView separates disposal from creation of the next
/// scene. Ordinary flutter_test remains GPU-free.
class MtnMinecraftRendererSmokeHost extends StatefulWidget {
  const MtnMinecraftRendererSmokeHost({super.key});

  @override
  State<MtnMinecraftRendererSmokeHost> createState() => _MtnMinecraftRendererSmokeHostState();
}

class _MtnMinecraftRendererSmokeHostState extends State<MtnMinecraftRendererSmokeHost> {
  int _generation = 0;
  bool _viewerVisible = true;

  void _recreateViewer() {
    if (!_viewerVisible) return;
    setState(() => _viewerVisible = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _generation++;
        _viewerVisible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_viewerVisible)
          MtnMinecraftRendererPrototype(key: ValueKey(_generation)),
        Positioned(
          top: 105,
          right: 16,
          child: ElevatedButton.icon(
            onPressed: _viewerVisible ? _recreateViewer : null,
            icon: const Icon(Icons.refresh),
            label: const Text('Recreate viewer'),
          ),
        ),
      ],
    );
  }
}

/// R1-only procedural character geometry. This is not a public package API.
///
/// The cuboids prove the renderer, interactions and an alpha-blended overlay.
/// A synthetic 8x8 PNG checks nearest-neighbor filtering on the head only.
/// A real Minecraft texture/UV atlas is intentionally deferred until R2.
class MtnMinecraftRendererPrototype extends StatefulWidget {
  const MtnMinecraftRendererPrototype({super.key});

  @override
  State<MtnMinecraftRendererPrototype> createState() => _MtnMinecraftRendererPrototypeState();
}

class _MtnMinecraftRendererPrototypeState extends State<MtnMinecraftRendererPrototype> {
  Scene? _scene;
  Node? _headOverlay;

  bool _ready = false;
  bool _showOverlay = true;
  Object? _initializationError;

  double _yaw = -math.pi / 3;
  double _pitch = 0.15;
  double _distance = 3.7;

  @override
  void initState() {
    super.initState();
    _initializeScene();
  }

  Future<void> _initializeScene() async {
    try {
      await Scene.initializeStaticResources();
      if (!mounted) return;
      // Create GPU resources inside the guarded async initializer. A release
      // runner without Flutter GPU opt-in must show an error, not a blank window.
      _scene = Scene();

      final png = await _generateCheckerPng();
      if (!mounted) return;
      final checker = await Texture2D.fromEncodedBytes(
        png,
        sampling: const TextureSampling(
          mipmaps: false,
          minFilter: gpu.MinMagFilter.nearest,
          magFilter: gpu.MinMagFilter.nearest,
          maxAnisotropy: 1,
        ),
      );
      if (!mounted) return;

      _addPart(
        size: vm.Vector3(0.5, 0.5, 0.5),
        position: vm.Vector3(0, 1.75, 0),
        color: vm.Vector4(1, 1, 1, 1),
        texture: checker,
      );
      _addPart(
        size: vm.Vector3(0.5, 0.75, 0.25),
        position: vm.Vector3(0, 1.125, 0),
        color: vm.Vector4(0.17, 0.65, 0.68, 1),
      );
      _addPart(
        size: vm.Vector3(0.25, 0.75, 0.25),
        position: vm.Vector3(-0.375, 1.125, 0),
        color: vm.Vector4(0.70, 0.46, 0.33, 1),
      );
      _addPart(
        size: vm.Vector3(0.25, 0.75, 0.25),
        position: vm.Vector3(0.375, 1.125, 0),
        color: vm.Vector4(0.70, 0.46, 0.33, 1),
      );
      _addPart(
        size: vm.Vector3(0.25, 0.75, 0.25),
        position: vm.Vector3(-0.125, 0.375, 0),
        color: vm.Vector4(0.13, 0.19, 0.45, 1),
      );
      _addPart(
        size: vm.Vector3(0.25, 0.75, 0.25),
        position: vm.Vector3(0.125, 0.375, 0),
        color: vm.Vector4(0.13, 0.19, 0.45, 1),
      );

      // The larger head shell exercises translucency and surface ordering.
      final overlayMaterial = UnlitMaterial()
        ..baseColorFactor = vm.Vector4(0.95, 0.80, 0.55, 0.40)
        ..alphaMode = AlphaMode.blend;
      _headOverlay = Node(
        mesh: Mesh(
          CuboidGeometry(vm.Vector3(0.5625, 0.5625, 0.5625)),
          overlayMaterial,
        ),
      )..position = vm.Vector3(0, 1.75, 0);
      if (_showOverlay) _scene!.add(_headOverlay!);
      setState(() => _ready = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _initializationError = error);
    }
  }

  /// Creates an 8x8 PNG in memory; no player skin, external files, or network.
  Future<Uint8List> _generateCheckerPng() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        paint.color = (x + y).isEven
            ? const ui.Color(0xFFFFDD00)
            : const ui.Color(0xFFAA22EE);
        canvas.drawRect(
          ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
          paint,
        );
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(8, 8);
    picture.dispose();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Failed to encode the R1 checker PNG.');
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  void _addPart({
    required vm.Vector3 size,
    required vm.Vector3 position,
    required vm.Vector4 color,
    TextureSource? texture,
  }) {
    final material = UnlitMaterial()..baseColorFactor = color;
    if (texture != null) material.baseColorTexture = texture;
    final node = Node(mesh: Mesh(CuboidGeometry(size), material))..position = position;
    _scene!.add(node);
  }

  void _orbit(DragUpdateDetails details) {
    setState(() {
      _yaw -= details.delta.dx * 0.012;
      _pitch = (_pitch + details.delta.dy * 0.008).clamp(-1.1, 1.1);
    });
  }

  void _zoom(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    setState(() {
      _distance = (_distance + event.scrollDelta.dy * 0.003).clamp(2.1, 7.0);
    });
  }

  void _toggleOverlay(bool value) {
    final overlay = _headOverlay;
    if (overlay == null || value == _showOverlay) return;
    if (value) {
      _scene!.add(overlay);
    } else {
      _scene!.remove(overlay);
    }
    setState(() => _showOverlay = value);
  }

  PerspectiveCamera _camera(Duration elapsed) {
    final x = _distance * math.sin(_yaw) * math.cos(_pitch);
    final y = 1 + _distance * math.sin(_pitch);
    final z = _distance * math.cos(_yaw) * math.cos(_pitch);
    return PerspectiveCamera(
      position: vm.Vector3(x, y, z),
      target: vm.Vector3(0, 1, 0),
    );
  }

  @override
  void dispose() {
    _scene?.dispose();
    _scene = null;
    _headOverlay = null;
    // Texture2D exposes no explicit dispose method; the released scene owns
    // the material reference. Check memory behavior with the manual harness.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minecraft Skin Viewer — R1 renderer test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: 'R3 2D gallery',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MtnMinecraftR3Gallery(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: const Color(0xFF252B39),
              child: Center(
                child: _initializationError != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: SelectableText(
                          '3D initialization failed: $_initializationError',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      )
                    : !_ready
                        ? const CircularProgressIndicator()
                        : Listener(
                            onPointerSignal: _zoom,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: _orbit,
                              child: SizedBox.expand(
                                child: SceneView(_scene!, cameraBuilder: _camera),
                              ),
                            ),
                          ),
              ),
            ),
          ),
          MtnMinecraftRendererControls(
            overlayEnabled: _showOverlay,
            enabled: _ready,
            onOverlayChanged: _toggleOverlay,
          ),
        ],
      ),
    );
  }
}

/// GPU-independent R1 controls. Can be widget-tested without creating Scene.
class MtnMinecraftRendererControls extends StatelessWidget {
  const MtnMinecraftRendererControls({
    super.key,
    required this.overlayEnabled,
    required this.enabled,
    required this.onOverlayChanged,
  });

  final bool overlayEnabled;
  final bool enabled;
  final ValueChanged<bool> onOverlayChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text('Drag to orbit · Wheel to zoom · Head: 8×8 PNG / nearest sampling'),
          ),
          const Text('Head overlay'),
          Switch(
            value: overlayEnabled,
            onChanged: enabled ? onOverlayChanged : null,
          ),
        ],
      ),
    );
  }
}
