// Vérifie `OlympiadeInscriptionController` (P8.3) sans réseau. Le paiement
// lui-même est délégué à `YkManualPaymentFlow` (composant partagé, testé
// séparément) : ce contrôleur n'expose que les deux appels réseau bruts
// (`inscrire`/`payerParticipation`) qu'il orchestre — vérifiés ici via un
// faux repository (même patron que `test/devoir_detail_controller_test.dart`).
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/features/olympiades/presentation/olympiade_inscription_controller.dart';
import 'package:yeki/repositories/olympiade_repository.dart';

class _FakeOlympiadeRepository extends OlympiadeRepository {
  _FakeOlympiadeRepository({this.erreurInscrire});

  final ApiException? erreurInscrire;
  int appelsInscrire = 0;
  int appelsPayerParticipation = 0;

  @override
  Future<void> inscrire(int olympiadeId) async {
    appelsInscrire++;
    if (erreurInscrire != null) throw erreurInscrire!;
  }

  @override
  Future<void> payerParticipation(int olympiadeId) async {
    appelsPayerParticipation++;
  }
}

void main() {
  group('OlympiadeInscriptionController', () {
    test('toggleAccepte inverse accepteReglement', () {
      final c = OlympiadeInscriptionController(olympiadeId: 1, repository: _FakeOlympiadeRepository());
      expect(c.accepteReglement, isFalse);
      c.toggleAccepte();
      expect(c.accepteReglement, isTrue);
      c.toggleAccepte();
      expect(c.accepteReglement, isFalse);
    });

    test('inscrire() bascule inscriptionEnCours pendant l\'appel puis le remet à false', () async {
      final repo = _FakeOlympiadeRepository();
      final c = OlympiadeInscriptionController(olympiadeId: 5, repository: repo);

      final future = c.inscrire();
      expect(c.inscriptionEnCours, isTrue);
      await future;
      expect(c.inscriptionEnCours, isFalse);
      expect(repo.appelsInscrire, 1);
    });

    test('inscrire() laisse remonter ApiException (402) — géré par l\'écran, pas le contrôleur', () async {
      final repo = _FakeOlympiadeRepository(
        erreurInscrire: const ApiException(
          message: 'Paiement requis',
          code: ApiErrorCodes.paymentRequired,
          fields: {},
        ),
      );
      final c = OlympiadeInscriptionController(olympiadeId: 5, repository: repo);

      await expectLater(c.inscrire(), throwsA(isA<ApiException>()));
      // Même après l'exception, l'état de chargement redescend (bloc finally).
      expect(c.inscriptionEnCours, isFalse);
    });

    test('payerParticipation délègue au repository — le montant est fixe côté serveur, jamais un paramètre client', () async {
      final repo = _FakeOlympiadeRepository();
      final c = OlympiadeInscriptionController(olympiadeId: 5, repository: repo);

      await c.payerParticipation();

      expect(repo.appelsPayerParticipation, 1);
    });
  });
}
