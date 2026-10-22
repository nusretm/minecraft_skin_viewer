import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart';

/// R4-D production-widget acceptance and manual GPU lifecycle harness.
/// The local PNG paths are developer conveniences, never published assets.
class MtnMinecraftR4DViewerGallery extends StatefulWidget {
  const MtnMinecraftR4DViewerGallery({super.key});

  @override
  State<MtnMinecraftR4DViewerGallery> createState() =>
      _MtnMinecraftR4DViewerGalleryState();
}

class _MtnMinecraftR4DViewerGalleryState
    extends State<MtnMinecraftR4DViewerGallery> {
  static const skinPath =
      r'D:\development\cross-platform\9fede215f7cb6884.png';
  static const capePath = r'D:\development\cross-platform\cape.png';

  final MtnMinecraftSkinViewerController _camera =
      MtnMinecraftSkinViewerController();
  MtnMinecraftSkinTexture? _skin;
  MtnMinecraftCapeTexture? _cape;
  Uint8List? _skinPng;
  Uint8List? _capePng;

  bool _visible = true;
  bool _stressRunning = false;
  int _stressCompleted = 0;
  Object? _error;
  Completer<void>? _sceneReady;

  @override
  void initState() {
    super.initState();
    _camera.addListener(_refreshControls);
    _loadFixtures();
  }

  void _refreshControls() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFixtures() async {
    try {
      final skinBytes = await _loadOrSynthetic(
        skinPath, width: 64, height: 64, cape: false);
      final capeBytes = await _loadOrSynthetic(
        capePath, width: 64, height: 32, cape: true);
      final skin = await MtnMinecraftSkinTexture.fromPng(
        skinBytes, modelType: MtnMinecraftSkinModelType.slim);
      final cape = await MtnMinecraftCapeTexture.fromPng(capeBytes);
      if (!mounted) return;
      setState(() {
        _skinPng = skinBytes;
        _capePng = capeBytes;
        _skin = skin;
        _cape = cape;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<Uint8List> _loadOrSynthetic(
    String path, {required int width, required int height, required bool cape}
  ) async {
    try {
      final file = io.File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (cape) {
          await MtnMinecraftCapeTexture.fromPng(bytes);
        } else {
          await MtnMinecraftSkinTexture.fromPng(
            bytes, modelType: MtnMinecraftSkinModelType.slim);
        }
        return bytes;
      }
    } catch (_) {
      // No dependency on the developer's machine during CI or other installs.
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    if (cape) {
      const atlas = MtnMinecraftCapeUvLayout();
      for (final face in MtnMinecraftSkinFace.values) {
        final rect = atlas.face(face);
        canvas.drawRect(
          ui.Rect.fromLTWH(rect.x.toDouble(), rect.y.toDouble(),
              rect.width.toDouble(), rect.height.toDouble()),
          ui.Paint()..color = face == MtnMinecraftSkinFace.front
              ? const ui.Color(0xFFE04838)
              : const ui.Color(0xFF4467BC),
        );
      }
    } else {
      final atlas = MtnMinecraftSkinUvLayout(MtnMinecraftSkinModelType.slim);
      for (final layer in MtnMinecraftSkinLayer.values) {
        for (final part in MtnMinecraftSkinBodyPart.values) {
          for (final face in MtnMinecraftSkinFace.values) {
            final rect = atlas.face(part, face, layer: layer);
            canvas.drawRect(
              ui.Rect.fromLTWH(rect.x.toDouble(), rect.y.toDouble(),
                  rect.width.toDouble(), rect.height.toDouble()),
              ui.Paint()..color = layer == MtnMinecraftSkinLayer.base
                  ? ui.Color.fromARGB(255,
                      60 + part.index * 26, 70 + face.index * 19, 160)
                  : const ui.Color(0x00000000),
            );
          }
        }
      }
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('Synthetic PNG failed');
      return Uint8List.fromList(byteData.buffer.asUint8List(
          byteData.offsetInBytes, byteData.lengthInBytes));
    } finally {
      image.dispose();
    }
  }

  Future<void> _switchModel(MtnMinecraftSkinModelType model) async {
    final png = _skinPng;
    if (png == null) return;
    try {
      final skin = await MtnMinecraftSkinTexture.fromPng(
        png, modelType: model);
      if (mounted) setState(() => _skin = skin);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _reloadTextures() async {
    if (_skinPng == null || _capePng == null || _skin == null) return;
    final model = _skin!.modelType;
    try {
      final skin = await MtnMinecraftSkinTexture.fromPng(
        _skinPng!, modelType: model);
      final cape = await MtnMinecraftCapeTexture.fromPng(_capePng!);
      if (mounted) {
        setState(() {
          _skin = skin;
          _cape = cape;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  /// Twenty actual remove-frame/recreate-and-ready cycles, not twenty
  /// coalesced setState calls. Observe process GPU memory before/after.
  Future<void> _stress20() async {
    if (_stressRunning || _skin == null) return;
    setState(() {
      _stressRunning = true;
      _stressCompleted = 0;
      _error = null;
    });
    _camera.setPose(MtnMinecraftSkinPose.idle);
    try {
      for (var i = 0; i < 20 && mounted; i++) {
        setState(() => _visible = false);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        final ready = Completer<void>();
        _sceneReady = ready;
        setState(() => _visible = true);
        await ready.future.timeout(const Duration(seconds: 25));
        // Allow the SceneView to present a real frame before unmounting it:
        // otherwise rapid callback/state cycles can skip GPU presentation.
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        setState(() => _stressCompleted = i + 1);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      _sceneReady = null;
      if (mounted) {
        setState(() {
          _visible = true;
          _stressRunning = false;
        });
      }
    }
  }

  void _onViewerReady() {
    final ready = _sceneReady;
    if (ready != null && !ready.isCompleted) ready.complete();
  }

  @override
  void dispose() {
    _camera.removeListener(_refreshControls);
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = _skin;
    return Scaffold(
      appBar: AppBar(title: const Text('R4-D — Public 3D Viewer & Lifecycle')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (skin != null)
                  SegmentedButton<MtnMinecraftSkinModelType>(
                    segments: const [
                      ButtonSegment(
                        value: MtnMinecraftSkinModelType.classic,
                        label: Text('Classic'),
                      ),
                      ButtonSegment(
                        value: MtnMinecraftSkinModelType.slim,
                        label: Text('Slim'),
                      ),
                    ],
                    selected: {skin.modelType},
                    onSelectionChanged: (values) => _switchModel(values.first),
                  ),
                FilterChip(
                  label: const Text('Outer layers'),
                  selected: _camera.showOuterLayer,
                  onSelected: _camera.setShowOuterLayer,
                ),
                FilterChip(
                  label: const Text('Cape'),
                  selected: _camera.showCape,
                  onSelected: _camera.setShowCape,
                ),
                SegmentedButton<MtnMinecraftSkinPose>(
                  segments: const [
                    ButtonSegment(value: MtnMinecraftSkinPose.idle,
                        label: Text('Idle')),
                    ButtonSegment(value: MtnMinecraftSkinPose.walk,
                        label: Text('Walk')),
                  ],
                  selected: {_camera.pose},
                  onSelectionChanged: (v) => _camera.setPose(v.first),
                ),
                OutlinedButton(
                  onPressed: _stressRunning ? null : _reloadTextures,
                  child: const Text('Reload textures'),
                ),
                ElevatedButton(
                  onPressed: _stressRunning ? null : _stress20,
                  child: const Text('20× recreate / dispose'),
                ),
                Text('Completed: $_stressCompleted/20'),
                OutlinedButton(
                  onPressed: () => _camera.reset(),
                  child: const Text('Reset camera'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // R5-B: the exact same decoded skin drives the public
                // 2D head/full-body widgets and the GPU 3D viewer.
                // These 2D widgets are declarative; they do not need
                // their own controller or a duplicate copy of pose state.
                if (skin != null)
                  SizedBox(
                    width: 160,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text('2D Head'),
                          const SizedBox(height: 8),
                          MtnMinecraftSkinHead(
                            texture: skin,
                            size: 64,
                            showOuterLayer: _camera.showOuterLayer,
                          ),
                          const SizedBox(height: 24),
                          const Text('2D Skin Preview'),
                          const SizedBox(height: 8),
                          MtnMinecraftSkinPreview(
                            texture: skin,
                            height: 192,
                            showOuterLayer: _camera.showOuterLayer,
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: ColoredBox(
                    color: const Color(0xFF252B39),
                    child: _error != null
                        ? Center(child: SelectableText(_error.toString()))
                        : skin == null
                            ? const Center(child: CircularProgressIndicator())
                            : _visible
                                ? MtnMinecraftSkinViewer(
                                    texture: skin,
                                    cape: _cape,
                                    controller: _camera,
                                    onReady: _onViewerReady,
                                    onError: (e) {
                                      if (_sceneReady != null &&
                                          !_sceneReady!.isCompleted) {
                                        _sceneReady!.completeError(e);
                                      }
                                      if (mounted) setState(() => _error = e);
                                    },
                                  )
                                : const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text('Real package widget; 20-cycle button tests GPU '
                'create/dispose, but memory stability needs Windows monitoring.'),
          ),
        ],
      ),
    );
  }
}
