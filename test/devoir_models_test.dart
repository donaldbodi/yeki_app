// Vérifie le parsing des modèles devoir (P7.4) depuis un JSON
// représentatif des réponses backend réelles (DevoirsCoursView,
// EnonceDevoirSerializer, QuestionDevoirAdminSerializer avec le champ
// `enonce_devoir` ajouté en P7.4).
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/models/devoir_models.dart';

void main() {
  group('ChoixReponseItem', () {
    test('fromJson lit est_correct', () {
      final choix = ChoixReponseItem.fromJson({'id': 1, 'texte': 'Paris', 'est_correct': true});
      expect(choix.id, 1);
      expect(choix.texte, 'Paris');
      expect(choix.estCorrect, isTrue);
    });
  });

  group('QuestionDevoirItem', () {
    test('fromJson lit enonce_devoir pour le regroupement par énoncé', () {
      final question = QuestionDevoirItem.fromJson({
        'id': 5,
        'enonce': 'Capitale ?',
        'type_question': 'qcm',
        'points': 2.0,
        'ordre': 1,
        'enonce_devoir': 42,
        'choix': [
          {'id': 1, 'texte': 'Paris', 'est_correct': true},
          {'id': 2, 'texte': 'Lyon', 'est_correct': false},
        ],
        'reponse_attendue': '',
        'reponse_exemple': '',
      });

      expect(question.enonceDevoirId, 42);
      expect(question.estQcm, isTrue);
      expect(question.choix.length, 2);
      expect(question.choix[0].estCorrect, isTrue);
    });

    test('enonce_devoir absent → null (pas 0)', () {
      final question = QuestionDevoirItem.fromJson({
        'id': 5,
        'enonce': 'Q',
        'type_question': 'texte',
        'points': 1.0,
        'ordre': 1,
      });
      expect(question.enonceDevoirId, isNull);
    });
  });

  group('EnonceDevoirItem', () {
    test('copyWith injecte les questions sans changer le reste', () {
      final enonce = EnonceDevoirItem.fromJson({'id': 42, 'contenu': '<p>Énoncé</p>', 'ordre': 1});
      final avecQuestions = enonce.copyWith(
        questions: [
          QuestionDevoirItem.fromJson({
            'id': 1,
            'enonce': 'Q1',
            'type_question': 'texte',
            'points': 1.0,
            'ordre': 1,
            'enonce_devoir': 42,
          }),
        ],
      );
      expect(avecQuestions.id, 42);
      expect(avecQuestions.contenu, '<p>Énoncé</p>');
      expect(avecQuestions.questions.length, 1);
    });
  });

  group('DevoirListItem', () {
    test('fromJson lit coefficient/fichier_correction_url (P7.4)', () {
      final devoir = DevoirListItem.fromJson({
        'id': 1,
        'titre': 'Devoir n°2',
        'description': 'Suites numériques',
        'date_debut': '2026-07-01T00:00:00Z',
        'date_limite': '2026-07-22T00:00:00Z',
        'est_ouvert': true,
        'est_expire': false,
        'est_publie': true,
        'nb_questions': 4,
        'note_sur': 14,
        'coefficient': 2.0,
        'duree_minutes': 45,
        'tentatives_max': 1,
        'type_correction': 'manuel',
        'fichier_correction_url': 'https://example.test/correction.pdf',
        'stats': {'nb_soumissions': 12, 'nb_corriges': 8, 'moyenne': 11.5},
      });

      expect(devoir.coefficient, 2.0);
      expect(devoir.fichierCorrectionUrl, 'https://example.test/correction.pdf');
      expect(devoir.estManuel, isTrue);
      expect(devoir.stats?.nbCorriges, 8);
    });

    test('ma_soumission absent → null', () {
      final devoir = DevoirListItem.fromJson({
        'id': 1,
        'titre': 'D',
        'description': '',
        'est_ouvert': true,
        'est_expire': false,
        'est_publie': true,
        'nb_questions': 1,
        'note_sur': 20,
        'coefficient': 1.0,
        'duree_minutes': 60,
        'tentatives_max': 1,
        'type_correction': 'auto',
      });
      expect(devoir.maSoumission, isNull);
    });
  });

  // P7.5 : vue APPRENANT (`QuestionDevoirSerializer`/`EnonceDevoirSerializer`/
  // `DevoirDetailSerializer`, `GET /devoirs/<id>/`) — l'ancien modèle
  // apprenant (`lib/views/pages/apprenants/devoir_models.dart`,
  // `QuestionDevoir.fromJson`) lisait `j['texte']` au lieu du champ réel
  // `enonce` : ce test confirme que le nouveau modèle lit la bonne clé.
  group('QuestionDevoirComposer', () {
    test('fromJson lit enonce (pas texte), jamais est_correct/reponse_attendue', () {
      final question = QuestionDevoirComposer.fromJson({
        'id': 5,
        'enonce': 'Quelle est la capitale de la France ?',
        'type_question': 'qcm',
        'points': 2.0,
        'ordre': 1,
        'choix': [
          {'id': 1, 'texte': 'Paris'},
          {'id': 2, 'texte': 'Lyon'},
        ],
      });

      expect(question.enonce, 'Quelle est la capitale de la France ?');
      expect(question.estQcm, isTrue);
      expect(question.choix.length, 2);
      expect(question.choix[0].texte, 'Paris');
    });

    test('type texte libre → estQcm faux, points non entiers acceptés', () {
      final question = QuestionDevoirComposer.fromJson({
        'id': 6,
        'enonce': 'Expliquez le théorème de Pythagore.',
        'type_question': 'texte',
        'points': 1.75,
        'ordre': 2,
        'choix': [],
      });

      expect(question.estQcm, isFalse);
      expect(question.points, 1.75);
      expect(question.choix, isEmpty);
    });
  });

  group('EnonceDevoirComposer', () {
    test('fromJson regroupe déjà ses questions (P7.1, pas de recomposition côté client)', () {
      final enonce = EnonceDevoirComposer.fromJson({
        'id': 42,
        'contenu': '<p>Lisez le texte suivant.</p>',
        'ordre': 1,
        'questions': [
          {'id': 1, 'enonce': 'Q1 QCM', 'type_question': 'qcm', 'points': 1.0, 'ordre': 1, 'choix': []},
          {'id': 2, 'enonce': 'Q2 texte libre', 'type_question': 'texte', 'points': 1.0, 'ordre': 2, 'choix': []},
        ],
      });

      expect(enonce.questions.length, 2);
      expect(enonce.questions[0].estQcm, isTrue);
      // Reproduit le scénario du bug signalé (P7.5) : un devoir MIXTE
      // qcm+texte doit exposer les deux types de question.
      expect(enonce.questions[1].estQcm, isFalse);
    });
  });

  group('DevoirAComposer', () {
    test('fromJson lit sorties_max/nb_sorties et regroupe toutesLesQuestions', () {
      final devoir = DevoirAComposer.fromJson({
        'id': 1,
        'titre': 'Devoir n°3',
        'description': 'Géométrie',
        'date_debut': '2026-07-01T00:00:00Z',
        'date_limite': '2026-07-22T00:00:00Z',
        'duree_minutes': 45,
        'note_sur': 20,
        'coefficient': 1.0,
        'type_correction': 'auto',
        'sorties_max': 2,
        'nb_sorties': 1,
        'enonces': [
          {
            'id': 1,
            'contenu': '<p>Énoncé 1</p>',
            'ordre': 1,
            'questions': [
              {'id': 1, 'enonce': 'Q1', 'type_question': 'qcm', 'points': 1.0, 'ordre': 1, 'choix': []},
            ],
          },
          {
            'id': 2,
            'contenu': '<p>Énoncé 2</p>',
            'ordre': 2,
            'questions': [
              {'id': 2, 'enonce': 'Q2', 'type_question': 'texte', 'points': 1.0, 'ordre': 1, 'choix': []},
            ],
          },
        ],
      });

      expect(devoir.tentativesMax, 2);
      expect(devoir.nbSorties, 1);
      expect(devoir.enonces.length, 2);
      expect(devoir.toutesLesQuestions.length, 2);
      expect(devoir.toutesLesQuestions.map((q) => q.typeQuestion), ['qcm', 'texte']);
    });

    test('estOlympiade lit type_devoir (mode immersif — ne pas confondre avec question_par_question, mort)', () {
      final normal = DevoirAComposer.fromJson({
        'id': 1,
        'titre': 'D',
        'description': '',
        'type_devoir': 'normal',
        'duree_minutes': 60,
        'note_sur': 20,
        'coefficient': 1.0,
        'type_correction': 'auto',
        'sorties_max': 1,
        'nb_sorties': 0,
        'enonces': [],
      });
      final olympiade = DevoirAComposer.fromJson({
        'id': 2,
        'titre': 'D',
        'description': '',
        'type_devoir': 'olympiade',
        'duree_minutes': 60,
        'note_sur': 20,
        'coefficient': 1.0,
        'type_correction': 'auto',
        'sorties_max': 1,
        'nb_sorties': 0,
        'enonces': [],
      });

      expect(normal.estOlympiade, isFalse);
      expect(olympiade.estOlympiade, isTrue);
    });
  });

  // P7.6 : vue APPRENANT post-correction (`SoumissionResultatSerializer`,
  // `GET /devoirs/<id>/resultat/`) — distincte de la vue composition
  // (`QuestionDevoirComposer`, jamais `estCorrect`).
  group('ChoixResultatDevoir', () {
    test('fromJson lit est_correct (snapshot complet post-correction)', () {
      final choix = ChoixResultatDevoir.fromJson({'id': 1, 'texte': 'Paris', 'est_correct': true});
      expect(choix.estCorrect, isTrue);
    });
  });

  group('DetailReponseDevoir', () {
    test('fromJson QCM : choix complet, bonne_reponse, commentaire_enseignant', () {
      final detail = DetailReponseDevoir.fromJson({
        'question_id': 1,
        'question_enonce': 'Capitale ?',
        'type_question': 'qcm',
        'reponse_utilisateur': 'Lyon',
        'choix_selectionne': 'Lyon',
        'choix': [
          {'id': 1, 'texte': 'Paris', 'est_correct': true},
          {'id': 2, 'texte': 'Lyon', 'est_correct': false},
        ],
        'est_correct': false,
        'points_obtenus': 0,
        'points_max': 1.0,
        'bonne_reponse': 'Paris',
        'reponse_exemple': '',
        'commentaire_enseignant': 'Bon travail',
      });

      expect(detail.estQcm, isTrue);
      expect(detail.choix.length, 2);
      expect(detail.choix.firstWhere((c) => c.estCorrect).texte, 'Paris');
      expect(detail.estCorrect, isFalse);
      expect(detail.bonneReponse, 'Paris');
      expect(detail.commentaireEnseignant, 'Bon travail');
    });

    test('est_correct absent (null) → en attente de correction manuelle, pas faux', () {
      final detail = DetailReponseDevoir.fromJson({
        'question_id': 2,
        'question_enonce': 'Expliquez.',
        'type_question': 'texte',
        'reponse_utilisateur': 'Ma réponse.',
        'choix_selectionne': null,
        'choix': [],
        'est_correct': null,
        'points_obtenus': null,
        'points_max': 2.0,
        'bonne_reponse': null,
        'reponse_exemple': 'Exemple attendu.',
        'commentaire_enseignant': '',
      });

      expect(detail.estQcm, isFalse);
      expect(detail.estCorrect, isNull);
      expect(detail.pointsObtenus, isNull);
      expect(detail.reponseExemple, 'Exemple attendu.');
    });
  });

  group('ResultatDevoir', () {
    test('fromJson lit note_sur (P7.6) et regroupe questions_detail', () {
      final resultat = ResultatDevoir.fromJson({
        'devoir_titre': 'Devoir n°4',
        'statut': 'corrige',
        'note': 15.5,
        'note_sur': 20,
        'commentaire': 'Bien joué',
        'soumis_le': '2026-07-01T10:00:00Z',
        'corrige_le': '2026-07-02T10:00:00Z',
        'est_en_retard': false,
        'est_suspecte': false,
        'fichier_correction_url': 'https://example.test/correction.pdf',
        'questions_detail': [
          {
            'question_id': 1,
            'question_enonce': 'Q1',
            'type_question': 'qcm',
            'reponse_utilisateur': 'A',
            'choix_selectionne': 'A',
            'choix': [],
            'est_correct': true,
            'points_obtenus': 1.0,
            'points_max': 1.0,
            'bonne_reponse': 'A',
            'reponse_exemple': '',
            'commentaire_enseignant': 'Bien joué',
          },
        ],
      });

      expect(resultat.note, 15.5);
      expect(resultat.noteSur, 20.0);
      expect(resultat.fichierCorrectionUrl, 'https://example.test/correction.pdf');
      expect(resultat.questionsDetail.length, 1);
    });

    test('note absent (null) — devoir en correction manuelle non encore noté', () {
      final resultat = ResultatDevoir.fromJson({
        'devoir_titre': 'Devoir manuel',
        'statut': 'en_retard',
        'note': null,
        'note_sur': 20,
        'commentaire': '',
        'est_en_retard': true,
        'est_suspecte': false,
        'questions_detail': [],
      });

      expect(resultat.note, isNull);
      expect(resultat.estEnRetard, isTrue);
    });
  });
}
