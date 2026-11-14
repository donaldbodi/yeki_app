// lib/services/offline_encryption_service.dart
//
// Source unique de vérité pour le chiffrement du contenu hors-ligne
// (P12.3) — boxes Hive de `offline_service.dart` et fichiers téléchargés
// de `download_manager.dart`/`lecture_lecon_page.dart`. Une seule clé
// AES-256, générée une fois et conservée via `flutter_secure_storage`
// (même mécanisme déjà utilisé par `auth_state.dart` pour le jeton
// d'authentification — réutilisé, pas dupliqué, règle 1).
//
// AES-GCM (authentifié) plutôt que CBC : une altération du fichier
// chiffré (corruption disque, falsification) fait échouer le
// déchiffrement au lieu de renvoyer silencieusement des données
// corrompues — cohérent avec la vérification SHA-256 ajoutée en P12.1.

import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class OfflineEncryptionService {
  static const _secureStorage = FlutterSecureStorage();
  static const _keyStorageKey = 'offline_content_encryption_key';

  /// Nonce GCM — 12 octets, taille standard recommandée pour AES-GCM.
  static const int _ivLength = 12;

  /// Récupère la clé persistée, ou en génère et persiste une nouvelle
  /// (première utilisation). Contrairement au jeton d'authentification
  /// (`auth_state.dart`), une panne de `flutter_secure_storage` ici n'a
  /// pas de repli silencieux acceptable : sans la même clé retrouvée à
  /// chaque appel, le contenu déjà chiffré deviendrait illisible. Se
  /// propage donc telle quelle (appelants déjà dans des blocs try/catch
  /// qui traitent un échec de déchiffrement comme "à retélécharger").
  static Future<encrypt.Key> getOrCreateKey() async {
    final existing = await _secureStorage.read(key: _keyStorageKey);
    if (existing != null) {
      return encrypt.Key.fromBase64(existing);
    }
    final nouvelleCle = encrypt.Key.fromSecureRandom(32);
    await _secureStorage.write(key: _keyStorageKey, value: nouvelleCle.base64);
    return nouvelleCle;
  }

  /// Chiffre pour un box Hive (`offline_service.dart`) — même clé que le
  /// chiffrement de fichiers, format de stockage propre à Hive.
  static Future<HiveAesCipher> hiveCipher() async {
    final cle = await getOrCreateKey();
    return HiveAesCipher(cle.bytes);
  }

  /// Fonctions pures (clé explicite, pas d'accès disque/plateforme) —
  /// testables directement sans mock de canal `flutter_secure_storage`
  /// (indisponible en environnement de test, voir commentaire de
  /// `auth_state.dart:57-62`).
  static Uint8List encryptBytesWithKey(Uint8List clair, encrypt.Key cle) {
    final iv = encrypt.IV.fromSecureRandom(_ivLength);
    final encrypter = encrypt.Encrypter(encrypt.AES(cle, mode: encrypt.AESMode.gcm));
    final chiffre = encrypter.encryptBytes(clair, iv: iv);
    return Uint8List.fromList([...iv.bytes, ...chiffre.bytes]);
  }

  static Uint8List decryptBytesWithKey(Uint8List paquet, encrypt.Key cle) {
    final iv = encrypt.IV(paquet.sublist(0, _ivLength));
    final octetsChiffres = paquet.sublist(_ivLength);
    final encrypter = encrypt.Encrypter(encrypt.AES(cle, mode: encrypt.AESMode.gcm));
    final dechiffre = encrypter.decryptBytes(encrypt.Encrypted(octetsChiffres), iv: iv);
    return Uint8List.fromList(dechiffre);
  }

  /// Chiffre [clair] et l'écrit à [destPath].
  static Future<void> encryptBytesToFile(Uint8List clair, String destPath) async {
    final cle = await getOrCreateKey();
    final paquet = encryptBytesWithKey(clair, cle);
    await File(destPath).writeAsBytes(paquet);
  }

  /// Déchiffre le fichier à [encryptedPath] et renvoie les octets clairs.
  static Future<Uint8List> decryptFileBytes(String encryptedPath) async {
    final cle = await getOrCreateKey();
    final paquet = await File(encryptedPath).readAsBytes();
    return decryptBytesWithKey(paquet, cle);
  }

  /// Déchiffre vers un fichier temporaire — à utiliser juste avant une
  /// lecture (PDF/vidéo) qui exige un vrai chemin sur disque ; le fichier
  /// renvoyé doit être supprimé par l'appelant une fois la lecture
  /// terminée (le clair ne doit exister que le temps de la lecture).
  static Future<File> decryptToTempFile(String encryptedPath, String tempFileName) async {
    final octets = await decryptFileBytes(encryptedPath);
    final dir = await getTemporaryDirectory();
    final fichierTemp = File('${dir.path}/$tempFileName');
    await fichierTemp.writeAsBytes(octets);
    return fichierTemp;
  }
}
