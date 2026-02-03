import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/work_item.dart';

class PrefsService {
  PrefsService._();
  static final PrefsService shared = PrefsService._();

  static final List<VoidCallback> worksUpdatedListeners = [];
  static void notifyWorksUpdated() {
    for (final cb in List.of(worksUpdatedListeners)) cb();
  }

  static const _userName = 'zaxo_user_name';
  static const _userAvatarPath = 'zaxo_user_avatar_path';
  static const _userSignature = 'zaxo_user_signature';
  static const _userCoins = 'zaxo_user_coins';
  static const _works = 'zaxo_works';
  static const _generatedImages = 'zaxo_generated_images';
  static const _musicCustomCovers = 'zaxo_music_custom_covers';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<String?> getUserName() async {
    return (await _prefs).getString(_userName);
  }

  Future<void> setUserName(String name) async {
    await (await _prefs).setString(_userName, name);
  }

  Future<String?> getUserAvatarPath() async {
    final p = (await _prefs).getString(_userAvatarPath);
    return (p == null || p.isEmpty) ? null : p;
  }

  Future<void> setUserAvatarPath(String? path) async {
    if (path == null || path.isEmpty) {
      await (await _prefs).remove(_userAvatarPath);
    } else {
      await (await _prefs).setString(_userAvatarPath, path);
    }
  }

  Future<String?> getUserSignature() async {
    return (await _prefs).getString(_userSignature);
  }

  Future<void> setUserSignature(String? signature) async {
    if (signature == null || signature.isEmpty) {
      await (await _prefs).remove(_userSignature);
    } else {
      await (await _prefs).setString(_userSignature, signature);
    }
  }

  Future<int> getUserCoins() async {
    return (await _prefs).getInt(_userCoins) ?? 0;
  }

  Future<void> setUserCoins(int coins) async {
    await (await _prefs).setInt(_userCoins, coins);
  }

  Future<bool> deductCoins(int amount) async {
    final current = await getUserCoins();
    if (current < amount) return false;
    await setUserCoins(current - amount);
    return true;
  }

  Future<List<WorkItem>> getAllWorks() async {
    final raw = (await _prefs).getString(_works);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => WorkItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveWork(WorkItem work) async {
    final list = await getAllWorks();
    list.add(work);
    await (await _prefs).setString(_works, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> deleteWorks(List<String> ids) async {
    final list = await getAllWorks();
    list.removeWhere((e) => ids.contains(e.id));
    await (await _prefs).setString(_works, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> updateWork(WorkItem work) async {
    final list = await getAllWorks();
    final i = list.indexWhere((e) => e.id == work.id);
    if (i >= 0) {
      list[i] = work;
      await (await _prefs).setString(_works, jsonEncode(list.map((e) => e.toJson()).toList()));
    }
  }

  Future<List<GeneratedImage>> getAllGeneratedImages() async {
    final raw = (await _prefs).getString(_generatedImages);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => GeneratedImage.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveGeneratedImage(GeneratedImage image) async {
    final list = await getAllGeneratedImages();
    list.insert(0, image);
    await (await _prefs).setString(_generatedImages, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> updateGeneratedImage(GeneratedImage image) async {
    final list = await getAllGeneratedImages();
    final i = list.indexWhere((e) => e.id == image.id);
    if (i >= 0) {
      list[i] = image;
      await (await _prefs).setString(_generatedImages, jsonEncode(list.map((e) => e.toJson()).toList()));
    }
  }

  Future<void> deleteGeneratedImage(String id) async {
    final list = await getAllGeneratedImages();
    list.removeWhere((e) => e.id == id);
    await (await _prefs).setString(_generatedImages, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<String?> getMusicCustomCover(String musicId) async {
    final raw = (await _prefs).getString(_musicCustomCovers);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map[musicId] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> setMusicCustomCover(String musicId, String? relativePath) async {
    final raw = (await _prefs).getString(_musicCustomCovers);
    Map<String, dynamic> map = {};
    if (raw != null) {
      try {
        map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    if (relativePath == null || relativePath.isEmpty) {
      map.remove(musicId);
    } else {
      map[musicId] = relativePath;
    }
    await (await _prefs).setString(_musicCustomCovers, jsonEncode(map));
  }
}
