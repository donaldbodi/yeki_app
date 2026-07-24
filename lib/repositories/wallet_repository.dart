import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';

/// Portefeuille Yéki — tranche initiale (P8.3) : uniquement le solde,
/// nécessaire à `YkManualPaymentFlow`. Le reste (historique de
/// transactions, recharge CinetPay) reste sur son propre écran, hors
/// périmètre de ce ticket.
class WalletRepository {
  final ApiClient _api;

  WalletRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<int> solde() async {
    final data = await _api.get(PaiementEndpoints.walletSolde);
    return (Map<String, dynamic>.from(data as Map)['solde'] as num?)?.toInt() ?? 0;
  }
}
