// Vérifie le parsing des modèles paiement manuel (P9.3) — pas d'appel
// réseau réel (même limite documentée que formation_repository_test.dart :
// aucune infrastructure de mock ApiClient/dio dans ce projet).
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/models/paiement_models.dart';

void main() {
  group('ParametresPublics.fromJson', () {
    test('parse tous les champs', () {
      final p = ParametresPublics.fromJson({
        'ussd_orange_money': '#150*1#',
        'ussd_mtn_momo': '*126#',
        'numero_depot_orange': '694000000',
        'numero_depot_mtn': '670000000',
        'nom_affiche_depot': 'YEKI SARL',
        'whatsapp_service_client': '237600000000',
        'delai_validation_paiement_minutes': 60,
        'mode_paiement': 'les_deux',
      });
      expect(p.ussdOrangeMoney, '#150*1#');
      expect(p.ussdMtnMomo, '*126#');
      expect(p.numeroDepotOrange, '694000000');
      expect(p.numeroDepotMtn, '670000000');
      expect(p.nomAfficheDepot, 'YEKI SARL');
      expect(p.whatsappServiceClient, '237600000000');
      expect(p.delaiValidationPaiementMinutes, 60);
      expect(p.modePaiement, 'les_deux');
      expect(p.cinetpayDisponible, isTrue);
      expect(p.manuelDisponible, isTrue);
    });

    test('tolère des champs absents (défauts sûrs, mode manuel par défaut)', () {
      final p = ParametresPublics.fromJson(const {});
      expect(p.ussdOrangeMoney, '');
      expect(p.delaiValidationPaiementMinutes, 60);
      expect(p.modePaiement, 'manuel');
      expect(p.cinetpayDisponible, isFalse);
      expect(p.manuelDisponible, isTrue);
    });

    test('mode_paiement == cinetpay désactive le manuel', () {
      final p = ParametresPublics.fromJson({'mode_paiement': 'cinetpay'});
      expect(p.cinetpayDisponible, isTrue);
      expect(p.manuelDisponible, isFalse);
    });
  });

  group('DemandePaiementManuel.fromJson', () {
    test('parse une demande en attente (montant_constate/date_traitement null)', () {
      final d = DemandePaiementManuel.fromJson({
        'id': 12,
        'categorie': 'recharge',
        'montant': 5000,
        'montant_constate': null,
        'operateur': 'orange_money',
        'id_transaction': 'CI240912.1234.A56789',
        'numero_emetteur': '690000000',
        'statut': 'en_attente',
        'motif_refus': '',
        'date_creation': '2026-07-20T10:00:00Z',
        'date_traitement': null,
      });
      expect(d.id, 12);
      expect(d.categorie, 'recharge');
      expect(d.montant, 5000);
      expect(d.montantConstate, isNull);
      expect(d.operateur, 'orange_money');
      expect(d.statut, 'en_attente');
      expect(d.dateTraitement, isNull);
    });

    test('parse une demande validée avec écart montant_constate', () {
      final d = DemandePaiementManuel.fromJson({
        'id': 13,
        'categorie': 'formation',
        'montant': 5000,
        'montant_constate': 4900,
        'operateur': 'mtn_momo',
        'id_transaction': 'MP240912.5678.B12345',
        'numero_emetteur': '',
        'statut': 'validee',
        'motif_refus': '',
        'date_creation': '2026-07-20T10:00:00Z',
        'date_traitement': '2026-07-20T10:30:00Z',
      });
      expect(d.montantConstate, 4900);
      expect(d.statut, 'validee');
      expect(d.dateTraitement, isNotNull);
    });

    test('tolère des champs absents (défauts sûrs)', () {
      final d = DemandePaiementManuel.fromJson(const {});
      expect(d.id, 0);
      expect(d.categorie, '');
      expect(d.statut, 'en_attente');
      expect(d.montantConstate, isNull);
    });
  });
}
