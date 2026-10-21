import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'mtn_minecraft_skin_texture.dart';
import 'mtn_minecraft_skin_uv.dart';

/// The side of a player/cape viewed straight-on in a flat 2D preview.
enum MtnMinecraftSkinView { front, back }

/// A square Minecraft head avatar using the shared R2 skin atlas.
class MtnMinecraftSkinHead extends StatelessWidget {
  const MtnMinecraftSkinHead({
    super.key,
    required this.texture,
    this.size = 64,
    this.view = MtnMinecraftSkinView.front,
    this.showOuterLayer = true,
  }) : assert(size > 0);

  final MtnMinecraftSkinTexture texture;
  final double size;
  final MtnMinecraftSkinView view;
  final bool showOuterLayer;

  @override
  Widget build(BuildContext context) => _MtnMinecraftPixelCanvas(
    texture: texture,
    logicalWidth: 8,
    logicalHeight: 8,
    pixelSize: size / 8,
    view: view,
    showOuterLayer: showOuterLayer,
    kind: _MtnMinecraftPreviewKind.head,
  );
}

/// Flat full-body Minecraft preview; logical character extent is 16 x 32.
///
/// Classic arms are 4px, Slim arms are 3px. Both models are read from
/// [texture.modelType], rather than inferred from the PNG or widget size.
class MtnMinecraftSkinPreview extends StatelessWidget {
  const MtnMinecraftSkinPreview({
    super.key,
    required this.texture,
    this.height = 256,
    this.view = MtnMinecraftSkinView.front,
    this.showOuterLayer = true,
  }) : assert(height > 0);

  final MtnMinecraftSkinTexture texture;
  final double height;
  final MtnMinecraftSkinView view;
  final bool showOuterLayer;

  @override
  Widget build(BuildContext context) => _MtnMinecraftPixelCanvas(
    texture: texture,
    logicalWidth: 16,
    logicalHeight: 32,
    pixelSize: height / 32,
    view: view,
    showOuterLayer: showOuterLayer,
    kind: _MtnMinecraftPreviewKind.body,
  );
}

/// Front or back of the flat 10 x 16 Minecraft Java Edition cape fabric.
class MtnMinecraftCapePreview extends StatelessWidget {
  const MtnMinecraftCapePreview({
    super.key,
    required this.texture,
    this.height = 256,
    this.view = MtnMinecraftSkinView.back,
  }) : assert(height > 0);

  final MtnMinecraftCapeTexture texture;
  final double height;
  final MtnMinecraftSkinView view;

  @override
  Widget build(BuildContext context) => _MtnMinecraftPixelCanvas(
    texture: texture,
    logicalWidth: 10,
    logicalHeight: 16,
    pixelSize: height / 16,
    view: view,
    showOuterLayer: false,
    kind: _MtnMinecraftPreviewKind.cape,
  );
}

enum _MtnMinecraftPreviewKind { head, body, cape }

/// Owns exactly one decoded Flutter image while its texture identity is fixed.
/// Changing a view, layer toggle, size or window constraints does not decode.
class _MtnMinecraftPixelCanvas extends StatefulWidget {
  const _MtnMinecraftPixelCanvas({
    required this.texture,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.pixelSize,
    required this.view,
    required this.showOuterLayer,
    required this.kind,
  });

  final Object texture;
  final int logicalWidth;
  final int logicalHeight;
  final double pixelSize;
  final MtnMinecraftSkinView view;
  final bool showOuterLayer;
  final _MtnMinecraftPreviewKind kind;

  @override
  State<_MtnMinecraftPixelCanvas> createState() => _MtnMinecraftPixelCanvasState();
}

class _MtnMinecraftPixelCanvasState extends State<_MtnMinecraftPixelCanvas> {
  ui.Image? _image;
  Object? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _MtnMinecraftPixelCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.texture, widget.texture)) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final generation = ++_generation;
    final previous = _image;
    _image = null;
    _error = null;
    previous?.dispose();

    final source = widget.texture;
    final rgba = source is MtnMinecraftSkinTexture
        ? source.rgba
        : (source as MtnMinecraftCapeTexture).rgba;
    final width = source is MtnMinecraftSkinTexture
        ? MtnMinecraftSkinTexture.width
        : MtnMinecraftCapeTexture.width;
    final height = source is MtnMinecraftSkinTexture
        ? MtnMinecraftSkinTexture.height
        : MtnMinecraftCapeTexture.height;

    try {
      final decoded = await _imageFromStraightRgba(rgba, width, height);
      if (!mounted || generation != _generation) {
        decoded.dispose();
        return;
      }
      setState(() => _image = decoded);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _generation++;
    _image?.dispose();
    _image = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final width = widget.logicalWidth * widget.pixelSize;
    final height = widget.logicalHeight * widget.pixelSize;
    return SizedBox(
      width: width,
      height: height,
      child: _error != null
          ? const Center(child: Text('Invalid texture'))
          : image == null
              ? const SizedBox.shrink()
              : CustomPaint(
                  painter: _MtnMinecraftSpritePainter(
                    image: image,
                    skin: widget.texture is MtnMinecraftSkinTexture
                        ? widget.texture as MtnMinecraftSkinTexture
                        : null,
                    kind: widget.kind,
                    view: widget.view,
                    showOuterLayer: widget.showOuterLayer,
                    pixelSize: widget.pixelSize,
                  ),
                ),
    );
  }
}

/// Flutter raw RGBA8888 images use *premultiplied* alpha. R2 stores straight
/// RGBA8888 to preserve source texels. Do not pass it unchanged to a raw
/// Flutter image or translucent hat/cape colors will be composited incorrectly.
Future<ui.Image> _imageFromStraightRgba(Uint8List rgba, int width, int height) async {
  final premultiplied = Uint8List.fromList(rgba);
  for (var i = 0; i < premultiplied.length; i += 4) {
    final alpha = premultiplied[i + 3];
    if (alpha == 255) continue;
    premultiplied[i] = (premultiplied[i] * alpha + 127) ~/ 255;
    premultiplied[i + 1] = (premultiplied[i + 1] * alpha + 127) ~/ 255;
    premultiplied[i + 2] = (premultiplied[i + 2] * alpha + 127) ~/ 255;
  }

  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(premultiplied);
    descriptor = ui.ImageDescriptor.raw(
      buffer, width: width, height: height, pixelFormat: ui.PixelFormat.rgba8888);
    codec = await descriptor.instantiateCodec();
    return (await codec.getNextFrame()).image;
  } finally {
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}

class _MtnMinecraftSpritePainter extends CustomPainter {
  const _MtnMinecraftSpritePainter({
    required this.image,
    required this.skin,
    required this.kind,
    required this.view,
    required this.showOuterLayer,
    required this.pixelSize,
  });

  final ui.Image image;
  final MtnMinecraftSkinTexture? skin;
  final _MtnMinecraftPreviewKind kind;
  final MtnMinecraftSkinView view;
  final bool showOuterLayer;
  final double pixelSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;

    void drawFace(MtnMinecraftSkinUvRect source, double x, double y) {
      final bounds = ui.Rect.fromLTWH(
        source.x.toDouble(), source.y.toDouble(),
        source.width.toDouble(), source.height.toDouble());
      final dst = ui.Rect.fromLTWH(
        x * pixelSize, y * pixelSize,
        source.width * pixelSize, source.height * pixelSize);
      // The front/back face UV rects have no face-local flip. Top/bottom
      // orientation is intentionally handled only by future 3D adapters.
      canvas.drawImageRect(image, bounds, dst, paint);
    }

    if (kind == _MtnMinecraftPreviewKind.cape) {
      final rect = const MtnMinecraftCapeUvLayout().face(
        view == MtnMinecraftSkinView.front
            ? MtnMinecraftSkinFace.front
            : MtnMinecraftSkinFace.back);
      drawFace(rect, 0, 0);
      return;
    }

    final texture = skin!;
    final layout = MtnMinecraftSkinUvLayout(texture.modelType);
    final face = view == MtnMinecraftSkinView.front
        ? MtnMinecraftSkinFace.front
        : MtnMinecraftSkinFace.back;

    void drawPart(MtnMinecraftSkinBodyPart part, double x, double y) {
      drawFace(layout.face(part, face), x, y);
      if (showOuterLayer) {
        drawFace(layout.face(part, face, layer: MtnMinecraftSkinLayer.outer), x, y);
      }
    }

    if (kind == _MtnMinecraftPreviewKind.head) {
      drawPart(MtnMinecraftSkinBodyPart.head, 0, 0);
      return;
    }

    // A flat projection with Minecraft-native 16x32 sprite measurements.
    // Looking from behind swaps the viewer-side left/right limbs.
    final back = view == MtnMinecraftSkinView.back;
    final armWidth = layout.dimensions(MtnMinecraftSkinBodyPart.rightArm).width;
    drawPart(MtnMinecraftSkinBodyPart.head, 4, 0);
    drawPart(MtnMinecraftSkinBodyPart.body, 4, 8);
    drawPart(
      MtnMinecraftSkinBodyPart.rightArm,
      back ? 12 : 4 - armWidth.toDouble(), 8);
    drawPart(
      MtnMinecraftSkinBodyPart.leftArm,
      back ? 4 - armWidth.toDouble() : 12, 8);
    drawPart(MtnMinecraftSkinBodyPart.rightLeg, back ? 8 : 4, 20);
    drawPart(MtnMinecraftSkinBodyPart.leftLeg, back ? 4 : 8, 20);
  }

  @override
  bool shouldRepaint(covariant _MtnMinecraftSpritePainter old) =>
      !identical(image, old.image) ||
      !identical(skin, old.skin) ||
      kind != old.kind || view != old.view ||
      showOuterLayer != old.showOuterLayer ||
      pixelSize != old.pixelSize;
}
