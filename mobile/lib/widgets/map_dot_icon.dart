import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Rounded dot marker bitmap for [GoogleMap] (not the default pin).
Future<BitmapDescriptor> buildMapDotIcon({
  required Color fill,
  int size = 12,
  double imagePixelRatio = 1.0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(size / 2, size / 2);
  final radius = size / 2;

  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = fill
      ..isAntiAlias = true,
  );

  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    return BitmapDescriptor.defaultMarker;
  }

  return BitmapDescriptor.bytes(
    bytes.buffer.asUint8List(),
    imagePixelRatio: imagePixelRatio,
    width: size.toDouble(),
    height: size.toDouble(),
  );
}
