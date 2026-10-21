import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mtn_minecraft_skin_viewer/mtn_minecraft_skin_viewer.dart';

/// Standalone R3 Windows visual smoke gallery. Generated fixtures only; no
/// accounts, network, Mojang assets or Flutter GPU scene are involved.
class MtnMinecraftR3Gallery extends StatefulWidget {
  const MtnMinecraftR3Gallery({super.key});

  @override
  State<MtnMinecraftR3Gallery> createState() => _MtnMinecraftR3GalleryState();
}

class _MtnMinecraftR3GalleryState extends State<MtnMinecraftR3Gallery> {
  MtnMinecraftSkinTexture? _skin;
  MtnMinecraftCapeTexture? _cape;
  MtnMinecraftSkinModelType _model = MtnMinecraftSkinModelType.classic;
  MtnMinecraftSkinView _view = MtnMinecraftSkinView.front;
  bool _layers = true;
  bool _legacy = false;
  Object? _error;
  int _serial = 0;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final serial = ++_serial;
    setState(() {
      _skin = null;
      _error = null;
    });
    try {
      final png = await _makeSkinPng(_model, legacy: _legacy);
      final skin = await MtnMinecraftSkinTexture.fromPng(
        png, modelType: _model);
      final capePng = await _makeCapePng();
      final cape = await MtnMinecraftCapeTexture.fromPng(capePng);
      if (!mounted || serial != _serial) return;
      setState(() {
        _skin = skin;
        _cape = cape;
      });
    } catch (e) {
      if (!mounted || serial != _serial) return;
      setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _serial++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = _skin;
    final cape = _cape;
    return Scaffold(
      appBar: AppBar(title: const Text('R3 — 2D Skin & Cape Preview')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Synthetic atlas demonstration. Real Java 64×64 / 64×32 PNGs use the same public widgets.'),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16, runSpacing: 8,
            children: [
              SegmentedButton<MtnMinecraftSkinModelType>(
                segments: const [
                  ButtonSegment(value: MtnMinecraftSkinModelType.classic, label: Text('Classic')),
                  ButtonSegment(value: MtnMinecraftSkinModelType.slim, label: Text('Slim')),
                ],
                selected: {_model},
                onSelectionChanged: (values) {
                  setState(() => _model = values.first);
                  _prepare();
                },
              ),
              SegmentedButton<MtnMinecraftSkinView>(
                segments: const [
                  ButtonSegment(value: MtnMinecraftSkinView.front, label: Text('Front')),
                  ButtonSegment(value: MtnMinecraftSkinView.back, label: Text('Back')),
                ],
                selected: {_view},
                onSelectionChanged: (values) =>
                    setState(() => _view = values.first),
              ),
              FilterChip(
                label: const Text('Outer layers'),
                selected: _layers,
                onSelected: (v) => setState(() => _layers = v),
              ),
              FilterChip(
                label: const Text('Legacy 64×32'),
                selected: _legacy,
                onSelected: (v) {
                  setState(() => _legacy = v);
                  _prepare();
                },
              ),
              ElevatedButton.icon(
                onPressed: _prepare,
                icon: const Icon(Icons.refresh),
                label: const Text('Recreate textures'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_error != null)
            SelectableText('R3 fixture error: ' + _error.toString(),
                style: const TextStyle(color: Colors.redAccent))
          else if (skin == null || cape == null)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 24,
              runSpacing: 24,
              children: [
                _previewPanel(
                  'Head 32px',
                  MtnMinecraftSkinHead(
                    texture: skin, size: 32, view: _view,
                    showOuterLayer: _layers),
                ),
                _previewPanel(
                  'Head 128px',
                  MtnMinecraftSkinHead(
                    texture: skin, size: 128, view: _view,
                    showOuterLayer: _layers),
                ),
                _previewPanel(
                  'Body — ' + (_legacy ? 'Legacy' : 'Modern'),
                  MtnMinecraftSkinPreview(
                    texture: skin, height: 256,
                    view: _view, showOuterLayer: _layers),
                ),
                _previewPanel(
                  'Cape',
                  MtnMinecraftCapePreview(
                    texture: cape, height: 256, view: _view),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _previewPanel(String label, Widget preview) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF252B39),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: preview,
        ),
      ),
    ],
  );
}

Future<Uint8List> _encodePicture(ui.PictureRecorder recorder, int w, int h) async {
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  picture.dispose();
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('PNG encoding failed');
    return Uint8List.fromList(bytes.buffer.asUint8List(
      bytes.offsetInBytes, bytes.lengthInBytes));
  } finally {
    image.dispose();
  }
}

Future<Uint8List> _makeSkinPng(
  MtnMinecraftSkinModelType model, {
  required bool legacy,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final layout = MtnMinecraftSkinUvLayout(model);
  const colors = <Color>[
    Color(0xFFF5C494),
    Color(0xFF249FB3),
    Color(0xFFB57A51),
    Color(0xFFDAA077),
    Color(0xFF3A468C),
    Color(0xFF4153B0),
  ];
  for (final part in MtnMinecraftSkinBodyPart.values) {
    if (legacy && (part == MtnMinecraftSkinBodyPart.leftArm ||
        part == MtnMinecraftSkinBodyPart.leftLeg)) continue;
    final color = colors[part.index];
    for (final face in [MtnMinecraftSkinFace.front, MtnMinecraftSkinFace.back]) {
      final rect = layout.face(part, face);
      canvas.drawRect(
        ui.Rect.fromLTWH(rect.x.toDouble(), rect.y.toDouble(),
          rect.width.toDouble(), rect.height.toDouble()),
        ui.Paint()..color = face == MtnMinecraftSkinFace.front
          ? color : Color.fromARGB(255, (color.r * 180).round(),
            (color.g * 180).round(), (color.b * 180).round()),
      );
      if (!legacy) {
        final outer = layout.face(part, face, layer: MtnMinecraftSkinLayer.outer);
        canvas.drawRect(
          ui.Rect.fromLTWH(outer.x.toDouble(), outer.y.toDouble(),
            1, outer.height.toDouble()),
          ui.Paint()..color = const Color(0xBFFFDD55),
        );
      }
    }
  }
  return _encodePicture(recorder, 64, legacy ? 32 : 64);
}

Future<Uint8List> _makeCapePng() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const layout = MtnMinecraftCapeUvLayout();
  for (final face in [MtnMinecraftSkinFace.front, MtnMinecraftSkinFace.back]) {
    final rect = layout.face(face);
    canvas.drawRect(
      ui.Rect.fromLTWH(rect.x.toDouble(), rect.y.toDouble(),
        rect.width.toDouble(), rect.height.toDouble()),
      ui.Paint()..color = face == MtnMinecraftSkinFace.back
          ? const Color(0xFFB83C72) : const Color(0xFF284EB0),
    );
    canvas.drawRect(
      ui.Rect.fromLTWH(rect.x.toDouble() + 2, rect.y.toDouble() + 2,
          6, 2),
      ui.Paint()..color = const Color(0xFFE6D4A8),
    );
  }
  return _encodePicture(recorder, 64, 32);
}
