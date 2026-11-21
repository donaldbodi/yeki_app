// Vérifie le parsing de `lib/models/olympiade_models.dart` (P8.3) — modèles
// APPRENANT qui remplacent l'usage apprenant de `OlympiadeItem`
// (formations_models.dart), dont le `fromJson` lisait des clés disparues
// (`prix_1er`/`prix_2eme`/`prix_3eme`, `matiere`, `niveau`) et construisait
// une « récompense » toujours vide (`" /  / "`). Ce test prouve que le vrai
// champ `recompense` (texte riche) est bien lu, et qu'aucune régression sur
// `mon_inscription`/`edition` ne se réintroduit silencieusement.
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/models/olympiade_models.dart';

Map<String, dynamic> _jsonOlympiade({
  String recompense = '<p>Un trophée et 50 000 FCFA</p>',
  String statut = 'inscription',
  Map<String, dynamic>? monInscription,
  int prixParticipation = 100,
}) => {
  'id': 7,
  'titre': 'Grand Prix Yéki',
  'description': 'Règlement complet ici.',
  'edition': 'Édition 2026',
  'date_ouverture_inscription': '2026-07-01T00:00:00Z',
  'date_cloture_inscription': '2026-07-20T00:00:00Z',
  'date_debut_olympiade': '2026-07-25T09:00:00Z',
  'date_fin_olympiade': '2026-07-25T11:00:00Z',
  'duree_minutes': 120,
  'nb_questions': 30,
  'note_sur': 20,
  'recompense': recompense,
  'prix_global': 200000,
  'prix_participation': prixParticipation,
  'demande_paiement_participants': prixParticipation > 0,
  'statut': statut,
  'est_inscrit': true,
  'nb_inscrits': 42,
  'inscription_ouverte': true,
  'devoir_id': 99,
  'mon_inscription': monInscription,
  'niveaux_accessibles': ['Terminale', 'Première'],
  // Champs retirés du modèle backend (P8.1) — présents dans certaines
  // réponses legacy éventuelles, ne doivent jamais faire planter le parsing
  // ni être lus par erreur.
  'prix_1er': '',
  'prix_2eme': '',
  'prix_3eme': '',
  'matiere': 'Ignoré',
  'niveau': 'Ignoré',
};

void main() {
  group('OlympiadeApprenant.fromJson', () {
    test('lit le vrai champ recompense (bug prix_1er/2e/3e corrigé)', () {
      final o = OlympiadeApprenant.fromJson(_jsonOlympiade());
      expect(o.recompense, '<p>Un trophée et 50 000 FCFA</p>');
      expect(o.recompense, isNot(contains('null')));
    });

    test('lit edition, niveaux_accessibles et prix_global', () {
      final o = OlympiadeApprenant.fromJson(_jsonOlympiade());
      expect(o.edition, 'Édition 2026');
      expect(o.niveauxAccessibles, ['Terminale', 'Première']);
      expect(o.prixGlobal, 200000);
    });

    test('mon_inscription absent → null, sans exception', () {
      final o = OlympiadeApprenant.fromJson(_jsonOlympiade(monInscription: null));
      expect(o.monInscription, isNull);
    });

    test('mon_inscription présent → parsé (note/classement/soumis/statut)', () {
      final o = OlympiadeApprenant.fromJson(
        _jsonOlympiade(
          monInscription: {'id': 12, 'note': 17.5, 'classement': 3, 'soumis': true, 'statut': 'corrige'},
        ),
      );
      expect(o.monInscription, isNotNull);
      expect(o.monInscription!.note, 17.5);
      expect(o.monInscription!.classement, 3);
      expect(o.monInscription!.soumis, isTrue);
      expect(o.monInscription!.statut, 'corrige');
    });

    test("afficherClassement vrai seulement si statut == 'terminee' (sans accent)", () {
      final enCours = OlympiadeApprenant.fromJson(_jsonOlympiade(statut: 'en_cours'));
      final terminee = OlympiadeApprenant.fromJson(_jsonOlympiade(statut: 'terminee'));
      expect(enCours.afficherClassement, isFalse);
      expect(terminee.afficherClassement, isTrue);
    });
  });

  group('ClassementOlympiadeEntry.fromJson', () {
    test('lit nom_complet, mention et note_sur_20 (jamais lus par l\'ancien fichier)', () {
      final e = ClassementOlympiadeEntry.fromJson({
        'rang': 1,
        'nom_complet': 'Awa Ngo',
        'username': 'awa.ngo',
        'note': 27.0,
        'note_sur_20': 18.0,
        'mention': 'Très bien',
      });
      expect(e.rang, 1);
      expect(e.nomComplet, 'Awa Ngo');
      expect(e.noteSur20, 18.0);
      expect(e.mention, 'Très bien');
    });

    test('nom_complet vide → repli possible sur username côté appelant', () {
      final e = ClassementOlympiadeEntry.fromJson({
        'rang': 2,
        'nom_complet': '',
        'username': 'j.doe',
        'note': 20.0,
        'note_sur_20': 13.3,
        'mention': 'Bien',
      });
      expect(e.nomComplet, isEmpty);
      expect(e.username, 'j.doe');
    });
  });
}
