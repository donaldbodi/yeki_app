import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_endpoints.dart';

/// Portefeuille Yéki — tranche initiale (P8.3) : uniquement le solde,
/// nécessaire à `YkWalletDebitConfirmSheet`. Le reste (historique de
/// transactions, recharge) est complété par `PaiementRepository` (P9.3).
class WalletRepository {
  final ApiClient _api;

  WalletRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<int> solde() async {
    final data = await _api.get(PaiementEndpoints.walletSolde);
    return (Map<String, dynamic>.from(data as Map)['solde'] as num?)?.toInt() ?? 0;
  }

  /// Solde + totaux + 30 dernières transactions (`WalletSoldeView` renvoie
  /// tout en un seul appel) — consommé par l'écran `wallet_page.dart`.
  Future<Map<String, dynamic>> apercu() async {
    final data = await _api.get(PaiementEndpoints.walletSolde);
    return Map<String, dynamic>.from(data as Map);
  }
}
