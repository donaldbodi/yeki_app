import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';
import 'package:yeki/models/paiement_models.dart';

/// Paiement. Couvre CinetPay (initiation/vérification) et, depuis P9.3,
/// le paiement manuel Orange Money/MTN MoMo (`YkManualPaymentFlow`) et le
/// retrait (cadres) — wallet (solde/recharger IAP) reste sur
/// `WalletRepository`, un moyen de paiement distinct non remplacé par le
/// flux manuel.
///
/// Sur une `ApiException`, inspecter `e.fields` : `PAYMENT_REQUIRED`/
/// `INSUFFICIENT_BALANCE` y placent `prix_participation`/`olympiade_id`/
/// `need_payment` (types arbitraires, pas seulement des messages), et
/// `THROTTLED` y place `retry_after` (secondes).
class PaiementRepository {
  final ApiClient _api;

  PaiementRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> initierCinetpay(
    Map<String, dynamic> payload,
  ) async {
    final data = await _api.post(
      PaiementEndpoints.paiementsCinetpayInitier,
      data: payload,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> verifier(String reference) async {
    final data = await _api.get(PaiementEndpoints.paiementsCinetpayVerifier(reference));
    return Map<String, dynamic>.from(data as Map);
  }

  /// Paramètres publics (USSD, numéros de dépôt, nom affiché, WhatsApp
  /// Service Client, délai de validation) — `AllowAny` côté backend.
  Future<ParametresPublics> parametresPublics() async {
    final data = await _api.get(PaiementEndpoints.parametresPublics);
    return ParametresPublics.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Soumission d'une demande de paiement manuel — `payload` porte à la
  /// fois les champs génériques du flux (`operateur`/`id_transaction`/
  /// `montant`/`numero_emetteur`, fournis par `YkManualPaymentFlow`) et
  /// les champs métier propres à ce qui est acheté (`categorie`,
  /// `departement_id`/`objet_id`/`type_abonnement`), ajoutés par l'écran
  /// appelant avant l'appel.
  Future<Map<String, dynamic>> soumettreManuel(Map<String, dynamic> payload) async {
    final data = await _api.post(PaiementEndpoints.paiementsManuelSoumettre, data: payload);
    return Map<String, dynamic>.from(data as Map);
  }

  /// Demandes de paiement manuel de l'apprenant connecté — paginé
  /// (`PaginatedListMixin` côté backend), triées de la plus récente à la
  /// plus ancienne. `statut` optionnel (`en_attente`|`validee`|`refusee`).
  Future<List<DemandePaiementManuel>> mesDemandes({String? statut}) async {
    final data = await _api.get(
      PaiementEndpoints.paiementsManuelMesDemandes,
      query: statut != null ? {'statut': statut} : null,
    );
    final results = Map<String, dynamic>.from(data as Map)['results'] as List? ?? [];
    return results
        .map((e) => DemandePaiementManuel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Demande de retrait (cadres) — solde gelé (débité) immédiatement à la
  /// création, en attente de traitement par le Service Client.
  Future<Map<String, dynamic>> demanderRetrait(Map<String, dynamic> payload) async {
    final data = await _api.post(PaiementEndpoints.retraitsDemander, data: payload);
    return Map<String, dynamic>.from(data as Map);
  }

  // ── Service Client (P9.5) ──────────────────────────────────────────

  /// File d'attente des paiements manuels — FIFO, `statut` optionnel
  /// (défaut backend : `en_attente` ; `'all'` pour tout voir).
  Future<List<DemandePaiementManuel>> fileAttentePaiements({String? statut}) async {
    final data = await _api.get(
      PaiementEndpoints.serviceClientPaiements,
      query: statut != null ? {'statut': statut} : null,
    );
    final results = Map<String, dynamic>.from(data as Map)['results'] as List? ?? [];
    return results
        .map((e) => DemandePaiementManuel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> validerPaiement(int id, {int? montantConstate}) async {
    final data = await _api.post(
      PaiementEndpoints.serviceClientPaiementsValider(id),
      data: montantConstate != null ? {'montant_constate': montantConstate} : null,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> refuserPaiement(int id, String motifRefus) async {
    final data = await _api.post(
      PaiementEndpoints.serviceClientPaiementsRefuser(id),
      data: {'motif_refus': motifRefus},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// File d'attente des retraits — chaque ligne inclut le solde actuel du
  /// bénéficiaire (exigence explicite du ticket).
  Future<List<DemandeRetrait>> fileAttenteRetraits({String? statut}) async {
    final data = await _api.get(
      PaiementEndpoints.serviceClientRetraits,
      query: statut != null ? {'statut': statut} : null,
    );
    final results = Map<String, dynamic>.from(data as Map)['results'] as List? ?? [];
    return results.map((e) => DemandeRetrait.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Valider un retrait NE crédite/débite rien (le solde a déjà été gelé à
  /// la création) — seul le statut passe à `validee`.
  Future<Map<String, dynamic>> validerRetrait(int id) async {
    final data = await _api.post(PaiementEndpoints.serviceClientRetraitsValider(id));
    return Map<String, dynamic>.from(data as Map);
  }

  /// Refuser un retrait libère le gel (crédite `montant_brut` au
  /// bénéficiaire côté backend) — `motifRefus` obligatoire.
  Future<Map<String, dynamic>> refuserRetrait(int id, String motifRefus) async {
    final data = await _api.post(
      PaiementEndpoints.serviceClientRetraitsRefuser(id),
      data: {'motif_refus': motifRefus},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<ServiceClientStatistiques> statistiquesServiceClient() async {
    final data = await _api.get(PaiementEndpoints.serviceClientStatistiques);
    return ServiceClientStatistiques.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
