// Vérifie la tolérance ajoutée en P5.3 (docs/ecarts/login.md §6) :
// `LoginView` (compte enseignant en attente de validation) renvoie un 403
// `{"detail","error_type","role"}` hors enveloppe standard
// `{"error":{"code","message","fields"}}` — sans cette tolérance,
// `ApiException.fromEnvelope` réduirait ce cas à un générique
// « Erreur serveur (403) », perdant le message et le rôle.
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/core/network/api_exception.dart';

void main() {
  group('ApiException.fromEnvelope', () {
    test('enveloppe standard : mappe code/message/fields normalement', () {
      final e = ApiException.fromEnvelope({
        'error': {
          'code': 'THROTTLED',
          'message': 'Trop de requêtes. Réessayez dans 42 secondes.',
          'fields': {'retry_after': 42},
        },
      }, statusCode: 429);

      expect(e.isThrottled, isTrue);
      expect(e.retryAfterSeconds, 42);
    });

    test('403 account_inactive hors enveloppe standard : reconnu, message et rôle préservés', () {
      final e = ApiException.fromEnvelope({
        'detail': '⚠️ Votre compte enseignant est en attente de validation par l\'administrateur.',
        'error_type': 'account_inactive',
        'role': 'enseignant',
      }, statusCode: 403);

      expect(e.isAccountInactive, isTrue);
      expect(e.message, contains('en attente de validation'));
      expect(e.fields['role'], 'enseignant');
      expect(e.statusCode, 403);
    });

    test('enveloppe totalement inattendue : repli générique SERVER_ERROR (comportement inchangé)', () {
      final e = ApiException.fromEnvelope({'une_page_html_de_proxy': true}, statusCode: 502);

      expect(e.code, ApiErrorCodes.serverError);
      expect(e.isAccountInactive, isFalse);
      expect(e.fields, isEmpty);
    });
  });
}
