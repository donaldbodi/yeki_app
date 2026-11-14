// Vérifie le parsing des modèles administration générale (P9.6) — pas
// d'appel réseau réel (même limite documentée que paiement_models_test.dart :
// aucune infrastructure de mock ApiClient/dio dans ce projet). Couvre en
// particulier le point comptable central du ticket : `totalDuAuxCadres`
// (passif) et `totalEncaisse` sont deux champs DISTINCTS, jamais fusionnés
// par le parsing.
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/features/admin_general/data/admin_general_models.dart';

void main() {
  group('AdminDashboardFinancier.fromJson', () {
    test('parse tous les champs, ventilations et total dû aux cadres restent distincts', () {
      final f = AdminDashboardFinancier.fromJson({
        'total_encaisse': 100000,
        'ventilation_categorie': {'recharge': 40000, 'formation': 60000},
        'ventilation_departement': [
          {'departement_id': 1, 'departement__nom': 'Maths', 'total': 60000},
        ],
        'solde_compte_ia': 5000,
        'solde_general_yeki_calcule': 30000,
        'total_du_aux_cadres': 42000,
        'demandes_en_attente': {'paiement': 3, 'retrait': 1},
        'delai_moyen_minutes': {'paiement': 90.0, 'retrait': null},
      });
      expect(f.totalEncaisse, 100000);
      expect(f.ventilationCategorie, {'recharge': 40000, 'formation': 60000});
      expect(f.ventilationDepartement, hasLength(1));
      expect(f.ventilationDepartement.first.departementNom, 'Maths');
      expect(f.soldeCompteIa, 5000);
      expect(f.soldeGeneralYekiCalcule, 30000);
      // Le total dû aux cadres NE DOIT JAMAIS être fondu dans total_encaisse
      // (point comptable explicitement signalé par le ticket P9.6).
      expect(f.totalDuAuxCadres, 42000);
      expect(f.totalDuAuxCadres, isNot(f.totalEncaisse));
      expect(f.demandesEnAttentePaiement, 3);
      expect(f.demandesEnAttenteRetrait, 1);
      expect(f.delaiMoyenMinutesPaiement, 90.0);
      expect(f.delaiMoyenMinutesRetrait, isNull);
    });

    test('tolère des champs absents (défauts sûrs)', () {
      final f = AdminDashboardFinancier.fromJson(const {});
      expect(f.totalEncaisse, 0);
      expect(f.ventilationCategorie, isEmpty);
      expect(f.ventilationDepartement, isEmpty);
      expect(f.totalDuAuxCadres, 0);
      expect(f.demandesEnAttentePaiement, 0);
      expect(f.delaiMoyenMinutesPaiement, isNull);
    });
  });

  group('AdminTransaction.fromJson', () {
    test('parse une ligne formation avec part tiers/bénéficiaire', () {
      final t = AdminTransaction.fromJson({
        'id': 1,
        'date': '2026-07-01T10:00:00Z',
        'apprenant': 'Jean Dupont',
        'categorie': 'formation',
        'departement': 'Mathématiques',
        'montant_brut': 10000,
        'part_yeki': 3000,
        'part_tiers_beneficiaire': 7000,
        'beneficiaire': 'Cadre Test',
        'operateur': 'orange_money',
        'statut': 'succes',
        'decideur': 'Service Client Test',
      });
      expect(t.categorie, 'formation');
      expect(t.partYeki, 3000);
      expect(t.partTiersBeneficiaire, 7000);
      expect(t.beneficiaire, 'Cadre Test');
    });

    test('recharge/abonnement : part tiers à 0, pas de bénéficiaire', () {
      final t = AdminTransaction.fromJson({
        'id': 2,
        'date': '2026-07-01T10:00:00Z',
        'apprenant': 'Jean Dupont',
        'categorie': 'recharge',
        'montant_brut': 5000,
        'part_yeki': 0,
        'part_tiers_beneficiaire': 0,
        'operateur': 'wallet',
        'statut': 'succes',
      });
      expect(t.partTiersBeneficiaire, 0);
      expect(t.beneficiaire, isNull);
      expect(t.departement, isNull);
    });
  });

  group('AdminGeneralDashboard.fromJson', () {
    test('parse parcours avec administrateur nommé et sans', () {
      final d = AdminGeneralDashboard.fromJson({
        'stats': {'nb_parcours': 2, 'nb_apprenants': 100},
        'parcours': [
          {
            'id': 1,
            'nom': 'Cursus',
            'type_parcours': 'cursus',
            'nb_departements': 3,
            'enseignant_admin': {'id': 9, 'nom': 'Ada Admin', 'username': 'ada', 'email': 'ada@yeki.cm'},
          },
          {'id': 2, 'nom': 'Prépa', 'type_parcours': 'prepa', 'enseignant_admin': null},
        ],
        'departements': [],
        'top_enseignants': [],
        'enseignants': [],
      });
      expect(d.stats.nbParcours, 2);
      expect(d.parcours, hasLength(2));
      expect(d.parcours[0].enseignantAdmin?.nom, 'Ada Admin');
      expect(d.parcours[1].enseignantAdmin, isNull);
    });
  });
}
