import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens Android's share sheet. The chosen app does the sending, so Stillscreen
/// itself needs no internet access.
abstract class ShareService {
  Future<void> shareImage(Uint8List png, String text);
}

class AndroidShareService implements ShareService {
  static const _channel = MethodChannel('app.stillscreen.focus/blocking');

  @override
  Future<void> shareImage(Uint8List png, String text) async {
    await _channel.invokeMethod<void>('shareImage', {'bytes': png, 'text': text});
  }
}

class UnsupportedShareService implements ShareService {
  @override
  Future<void> shareImage(Uint8List png, String text) async {
    throw UnsupportedError('Sharing works on Android only.');
  }
}

final shareServiceProvider = Provider<ShareService>((ref) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidShareService();
  }
  return UnsupportedShareService();
});
