// Vérifie `OlympiadesController` (P8.3) sans réseau — filtrage par phase et
// gestion des états chargement/erreur. Le repository est remplacé par un
// faux (même patron que `test/devoir_detail_controller_test.dart`) : aucune
// infrastructure de mock ApiClient/dio dans ce projet.
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/olympiades/presentation/olympiades_controller.dart';
import 'package:yeki/models/olympiade_models.dart';
import 'package:yeki/repositories/olympiade_repository.dart';

class _FakeOlympiadeRepository extends OlympiadeRepository {
  _FakeOlympiadeRepository({this.olympiades, this.erreur});

  final List<OlympiadeApprenant>? olympiades;
  final Object? erreur;

  @override
  Future<List<OlympiadeApprenant>> pourMoi() async {
    if (erreur != null) throw erreur!;
    return olympiades ?? [];
  }
}

OlympiadeApprenant _olympiade({required int id, required String statut}) => OlympiadeApprenant(
  id: id,
  titre: 'Olympiade $id',
  description: '',
  edition: '',
  dateOuvertureInscription: DateTime(2026, 1, 1),
  dateClotureInscription: DateTime(2026, 1, 10),
  dateDebutOlympiade: DateTime(2026, 1, 15),
  dateFinOlympiade: DateTime(2026, 1, 15, 2),
  dureeMinutes: 120,
  nbQuestions: 30,
  noteSur: 20,
  recompense: '',
  prixGlobal: 0,
  prixParticipation: 0,
  demandePaiementParticipants: false,
  statut: statut,
  estInscrit: false,
  nbInscrits: 0,
  inscriptionOuverte: true,
  devoirId: null,
  monInscription: null,
  niveauxAccessibles: const [],
);

void main() {
  group('OlympiadesController', () {
    test('charger() peuple toutes et passe à pret', () async {
      final controller = _FakeOlympiadeRepository(
        olympiades: [_olympiade(id: 1, statut: 'inscription'), _olympiade(id: 2, statut: 'terminee')],
      );
      final c = OlympiadesController(repository: controller);

      await c.charger();

      expect(c.etat, OlympiadesEtat.pret);
      expect(c.toutes.length, 2);
    });

    test('filtrerPar restreint affichees à la phase choisie', () async {
      final repo = _FakeOlympiadeRepository(
        olympiades: [
          _olympiade(id: 1, statut: 'inscription'),
          _olympiade(id: 2, statut: 'en_cours'),
          _olympiade(id: 3, statut: 'terminee'),
        ],
      );
      final c = OlympiadesController(repository: repo);
      await c.charger();

      expect(c.affichees.length, 3);

      c.filtrerPar('en_cours');
      expect(c.affichees.map((o) => o.id).toList(), [2]);

      c.filtrerPar('tous');
      expect(c.affichees.length, 3);
    });

    test('échec réseau → état erreur, pas d\'exception non gérée', () async {
      final repo = _FakeOlympiadeRepository(erreur: Exception('réseau indisponible'));
      final c = OlympiadesController(repository: repo);

      await c.charger();

      expect(c.etat, OlympiadesEtat.erreur);
      expect(c.erreurMessage, isNotNull);
    });
  });
}
