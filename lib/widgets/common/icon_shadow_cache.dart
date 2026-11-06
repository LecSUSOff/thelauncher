import 'dart:typed_data';
import 'dart:ui' as ui;

class IconShadowCache {
  static const _maxEntries = 128;
  static final _entries = <(Uint8List, double, double), Future<Uint8List>>{};

  static Future<Uint8List> get(Uint8List icon, double size, double pixelRatio) {
    final key = (icon, size, pixelRatio);
    final existing = _entries.remove(key);
    if (existing != null) {
      _entries[key] = existing;
      return existing;
    }
    final future = _render(icon, size, pixelRatio);
    _entries[key] = future;
    if (_entries.length > _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    return future;
  }

  static Future<Uint8List> _render(
    Uint8List bytes,
    double size,
    double pixelRatio,
  ) async {
    final codec = await ui.instantiateImageCodec(bytes);
    ui.Image? source;
    ui.Image? shadow;
    ui.Picture? picture;
    try {
      source = (await codec.getNextFrame()).image;
      const padding = 12.0;
      final extent = ((size + padding * 2) * pixelRatio).ceil();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(pixelRatio);
      canvas.saveLayer(
        null,
        ui.Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
      );
      final scale =
          size / (source.width > source.height ? source.width : source.height);
      final width = source.width * scale;
      final height = source.height * scale;
      canvas.drawImageRect(
        source,
        ui.Rect.fromLTWH(
          0,
          0,
          source.width.toDouble(),
          source.height.toDouble(),
        ),
        ui.Rect.fromLTWH(
          padding + (size - width) / 2,
          padding + (size - height) / 2,
          width,
          height,
        ),
        ui.Paint()
          ..filterQuality = ui.FilterQuality.low
          ..colorFilter = const ui.ColorFilter.mode(
            ui.Color.fromRGBO(0, 0, 0, 0.45),
            ui.BlendMode.srcIn,
          ),
      );
      canvas.restore();
      picture = recorder.endRecording();
      shadow = await picture.toImage(extent, extent);
      final data = await shadow.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode icon shadow');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      source?.dispose();
      shadow?.dispose();
      picture?.dispose();
      codec.dispose();
    }
  }
}
