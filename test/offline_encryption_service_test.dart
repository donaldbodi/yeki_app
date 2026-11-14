// Vérifie le cœur du chiffrement du contenu hors-ligne (P12.3) : les
// fonctions pures `encryptBytesWithKey`/`decryptBytesWithKey` (clé
// explicite, aucun accès `flutter_secure_storage`) — les méthodes qui
// touchent `flutter_secure_storage` (`getOrCreateKey`,
// `encryptBytesToFile`, etc.) ne sont volontairement pas testées ici :
// ce canal de plateforme n'a pas de mock disponible en test (voir
// `auth_state.dart:57-62`, même limite déjà documentée pour le jeton
// d'authentification).
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/services/offline_encryption_service.dart';

void main() {
  group('OfflineEncryptionService — chiffrement/déchiffrement AES-GCM', () {
    final cle = encrypt.Key.fromSecureRandom(32);

    test('aller-retour : les octets déchiffrés sont identiques aux octets clairs', () {
      final clair = Uint8List.fromList('Contenu de leçon confidentiel'.codeUnits);
      final paquet = OfflineEncryptionService.encryptBytesWithKey(clair, cle);
      final dechiffre = OfflineEncryptionService.decryptBytesWithKey(paquet, cle);
      expect(dechiffre, equals(clair));
    });

    test('deux chiffrements du même contenu produisent des paquets différents (IV aléatoire)', () {
      final clair = Uint8List.fromList('même contenu, deux chiffrements'.codeUnits);
      final paquet1 = OfflineEncryptionService.encryptBytesWithKey(clair, cle);
      final paquet2 = OfflineEncryptionService.encryptBytesWithKey(clair, cle);
      expect(paquet1, isNot(equals(paquet2)));
    });

    test('falsification détectée : altérer le paquet chiffré fait échouer le déchiffrement', () {
      final clair = Uint8List.fromList('contenu protégé'.codeUnits);
      final paquet = OfflineEncryptionService.encryptBytesWithKey(clair, cle);
      final paquetAltere = Uint8List.fromList(paquet);
      paquetAltere[paquetAltere.length - 1] ^= 0xFF;
      expect(
        () => OfflineEncryptionService.decryptBytesWithKey(paquetAltere, cle),
        throwsA(anything),
      );
    });

    test('une mauvaise clé ne peut pas déchiffrer', () {
      final clair = Uint8List.fromList('secret'.codeUnits);
      final paquet = OfflineEncryptionService.encryptBytesWithKey(clair, cle);
      final autreCle = encrypt.Key.fromSecureRandom(32);
      expect(
        () => OfflineEncryptionService.decryptBytesWithKey(paquet, autreCle),
        throwsA(anything),
      );
    });
  });
}
