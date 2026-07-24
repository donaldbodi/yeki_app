import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';

/// Paiement. Tranche initiale : initiation et vérification CinetPay
/// seulement — wallet (solde/recharger/historique), abonnement/IAP
/// attendent la migration de leur écran.
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
}
