import 'dart:io';

import 'package:flutter/services.dart';

typedef RemotePlaybackCallback = void Function(String action, [int? positionMs]);

class NowPlayingService {
  NowPlayingService._();
  static const MethodChannel _channel = MethodChannel('com.zaxo/now_playing');

  static RemotePlaybackCallback? _remoteCallback;
  static bool _handlerRegistered = false;

  static void setRemoteCallback(RemotePlaybackCallback? callback) {
    _remoteCallback = callback;
    if (!_handlerRegistered) {
      _handlerRegistered = true;
      _channel.setMethodCallHandler(_handleRemoteCall);
    }
  }

  static Future<dynamic> _handleRemoteCall(MethodCall call) async {
    final cb = _remoteCallback;
    if (cb == null) return null;
    switch (call.method) {
      case 'onRemotePlay':
        cb('play');
        break;
      case 'onRemotePause':
        cb('pause');
        break;
      case 'onRemoteTogglePlayPause':
        cb('toggle');
        break;
      case 'onRemoteSeek':
        cb('seek', call.arguments as int?);
        break;
    }
    return null;
  }

  static Future<void> setNowPlaying({
    required String title,
    String artist = '',
    String? artworkUrl,
    required int durationMs,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('setNowPlaying', {
        'title': title,
        'artist': artist,
        if (artworkUrl != null && artworkUrl.isNotEmpty) 'artworkUrl': artworkUrl,
        'durationMs': durationMs,
      });
    } on PlatformException catch (_) {}
  }

  static Future<void> updatePlayback({
    required int positionMs,
    required bool isPlaying,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('updatePlayback', {
        'positionMs': positionMs,
        'isPlaying': isPlaying,
      });
    } on PlatformException catch (_) {}
  }

  static Future<void> clearNowPlaying() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('clearNowPlaying');
    } on PlatformException catch (_) {}
  }
}
