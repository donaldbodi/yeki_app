// lib/services/images_hors_ligne.dart
//
// Photos (de profil notamment) disponibles hors ligne sur mobile : chaque
// image téléchargée est gardée sur le téléphone, et resservie quand le
// réseau manque. `Image.network`/`NetworkImage` ne gardent les images qu'en
// mémoire : la photo de profil disparaissait sans connexion.
//
// Usage : `imageReseau(url)` à la place de `NetworkImage(url)`. Sur le web,
// c'est simplement `NetworkImage` (le navigateur a son propre cache).

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:hive/hive.dart';

import 'package:yeki/services/offline_encryption_service.dart';

ImageProvider imageReseau(String url) => kIsWeb ? NetworkImage(url) : ImageHorsLigne(url);

class ImagesHorsLigne {
  ImagesHorsLigne._();

  static const _nomBox = 'yeki_images';
  static const _tailleMax = 1500 * 1024; // pas de grosses images dans le cache
  static Box<String>? _box;
  static final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 20)));

  /// À appeler au démarrage, après `OfflineService.init()` (qui initialise Hive).
  static Future<void> init() async {
    if (kIsWeb || _box != null) return;
    try {
      _box = await Hive.openBox<String>(_nomBox, encryptionCipher: await OfflineEncryptionService.hiveCipher());
    } catch (e) {
      debugPrint('ImagesHorsLigne.init : $e');
      await Hive.deleteBoxFromDisk(_nomBox);
      _box = await Hive.openBox<String>(_nomBox, encryptionCipher: await OfflineEncryptionService.hiveCipher());
    }
  }

  /// Octets de l'image : téléchargés (et gardés), ou la copie gardée sans réseau.
  static Future<Uint8List> octets(String url) async {
    try {
      final reponse = await _dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
      final octets = Uint8List.fromList(reponse.data ?? const []);
      if (octets.isNotEmpty && octets.length <= _tailleMax) {
        await _box?.put(url, base64Encode(octets));
      }
      return octets;
    } catch (_) {
      final garde = _box?.get(url);
      if (garde != null) return base64Decode(garde);
      rethrow;
    }
  }
}

/// `ImageProvider` qui passe par [ImagesHorsLigne].
@immutable
class ImageHorsLigne extends ImageProvider<ImageHorsLigne> {
  const ImageHorsLigne(this.url);

  final String url;

  @override
  Future<ImageHorsLigne> obtainKey(ImageConfiguration configuration) => SynchronousFuture<ImageHorsLigne>(this);

  @override
  ImageStreamCompleter loadImage(ImageHorsLigne key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(codec: _charger(decode), scale: 1.0, debugLabel: url);
  }

  Future<ui.Codec> _charger(ImageDecoderCallback decode) async {
    final octets = await ImagesHorsLigne.octets(url);
    final buffer = await ui.ImmutableBuffer.fromUint8List(octets);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) => other is ImageHorsLigne && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
