/// Codes d'erreur connus renvoyés par le backend (`error.code` de
/// l'enveloppe DRF, `apps/core/exceptions.py`) plus les codes propres au
/// client (échec réseau pur, requête annulée). Constantes plutôt qu'une
/// hiérarchie de classes scellée : un code futur inconnu côté backend
/// dégrade proprement (`ApiErrorCodes.unknown`) sans obliger à modifier le
/// client, cohérent avec la convention 100% manuelle du projet.
class ApiErrorCodes {
  ApiErrorCodes._();

  static const String validationError = 'VALIDATION_ERROR';
  static const String notFound = 'NOT_FOUND';
  static const String permissionDenied = 'PERMISSION_DENIED';
  static const String notAuthenticated = 'NOT_AUTHENTICATED';
  static const String throttled = 'THROTTLED';
  static const String conflict = 'CONFLICT';
  static const String paymentRequired = 'PAYMENT_REQUIRED';
  static const String insufficientBalance = 'INSUFFICIENT_BALANCE';
  static const String serverError = 'SERVER_ERROR';

  /// Cas hors convention : `LoginView` (compte enseignant en attente de
  /// validation) renvoie un 403 `{"detail","error_type","role"}` qui ne
  /// suit PAS l'enveloppe standard `{"error":{"code","message","fields"}}`
  /// — voir `ApiException.fromEnvelope` et `docs/ecarts/login.md` (P5.3).
  /// Incohérence backend connue, à corriger dans un futur ticket.
  static const String accountInactive = 'ACCOUNT_INACTIVE';

  // Codes propres au client (pas d'enveloppe serveur à parser).
  static const String networkError = 'NETWORK_ERROR';
  static const String requestCancelled = 'REQUEST_CANCELLED';
  static const String unknown = 'UNKNOWN_ERROR';
}

/// Exception unifiée pour tout appel via [ApiClient]. Toute erreur qui
/// sort du client (réponse d'erreur du serveur, timeout, pas de réseau,
/// requête annulée) est convertie en `ApiException` — jamais une
/// `DioException` brute — pour que les appelants n'aient besoin que d'un
/// seul `catch (ApiException e)`.
class ApiException implements Exception {
  final String code;
  final String message;

  /// Toujours présent (jamais null), possiblement vide. Le type est
  /// `Map<String, dynamic>` et non `Map<String, List<String>>` car le
  /// backend renvoie deux formes différentes selon l'origine de
  /// l'erreur : la forme DRF standard `{"champ": ["message"]}` pour les
  /// erreurs de validation de serializer, ou une forme personnalisée à
  /// types arbitraires pour les exceptions métier (ex.
  /// `PaymentRequiredError` renvoie `{"prix_participation": 100,
  /// "need_payment": true}`).
  final Map<String, dynamic> fields;

  /// Identifiant court (8 caractères hex) généré par le backend pour
  /// corréler avec ses logs serveur en cas de SERVER_ERROR. Absent pour
  /// les erreurs purement côté client (réseau, annulation).
  final String? requestId;

  /// Code HTTP d'origine, absent si aucune réponse n'a été reçue
  /// (timeout, pas de réseau, DNS).
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    required this.fields,
    this.requestId,
    this.statusCode,
  });

  /// Construit l'exception depuis l'enveloppe JSON décodée
  /// `{"error": {"code","message","fields","request_id"}}`. Défensif :
  /// une enveloppe malformée ou inattendue (ex. page d'erreur HTML d'un
  /// proxy/hébergeur) ne doit jamais faire planter le parsing lui-même.
  factory ApiException.fromEnvelope(
    Map<String, dynamic> envelope, {
    required int statusCode,
  }) {
    final error = envelope['error'];
    if (error is! Map) {
      // Tolérance P5.3 (docs/ecarts/login.md §6) : `LoginView` renvoie le
      // compte enseignant inactif hors enveloppe standard, en
      // {"detail","error_type","role"} — reconnu spécifiquement ici pour
      // ne pas perdre le message ni le rôle. Correctif frontend temporaire,
      // le backend devrait à terme émettre l'enveloppe standard.
      if (envelope['error_type'] == 'account_inactive') {
        return ApiException(
          code: ApiErrorCodes.accountInactive,
          message: (envelope['detail'] as String?) ??
              'Compte en attente de validation.',
          fields: {'role': envelope['role']},
          statusCode: statusCode,
        );
      }
      // Tolérance P5.5 (docs/ecarts/forgot_password.md §3) : les vues du
      // flux mot de passe oublié (ForgotPassword/VerifyOTP/ResetPassword)
      // renvoient à la main `{"detail": "..."}` sur les erreurs 400, pas
      // l'enveloppe standard — générique plutôt que dupliqué par vue,
      // couvre aussi tout futur endpoint legacy au même format.
      // P10.6 : les vues Yéki IA (`apps/ia/views.py`) renvoient ce même
      // format légataire mais avec des champs supplémentaires au 402/503
      // (`solde_actuel`, `minimum_requis`, `cout_estime_min`,
      // `cout_estime_max`) — auparavant silencieusement perdus par ce
      // repli (`fields: const {}`), alors qu'aucun appelant existant de
      // cette branche ne lisait `.fields` (uniquement `.message`) :
      // conserver les clés restantes est purement additif.
      if (envelope['detail'] is String) {
        return ApiException(
          code: ApiErrorCodes.validationError,
          message: envelope['detail'] as String,
          fields: Map<String, dynamic>.from(envelope)..remove('detail'),
          statusCode: statusCode,
        );
      }
      return ApiException(
        code: ApiErrorCodes.serverError,
        message: 'Erreur serveur ($statusCode).',
        fields: const {},
        statusCode: statusCode,
      );
    }
    final fieldsRaw = error['fields'];
    return ApiException(
      code: (error['code'] as String?) ?? ApiErrorCodes.unknown,
      message: (error['message'] as String?) ?? 'Une erreur est survenue.',
      fields: fieldsRaw is Map
          ? Map<String, dynamic>.from(fieldsRaw)
          : const {},
      requestId: error['request_id'] as String?,
      statusCode: statusCode,
    );
  }

  /// Échec de transport pur : timeout, pas de réseau, résolution DNS
  /// impossible — le serveur n'a jamais répondu, il n'y a donc aucune
  /// enveloppe à parser.
  factory ApiException.network([String? detail]) => ApiException(
        code: ApiErrorCodes.networkError,
        message: 'Vérifiez votre connexion internet et réessayez.',
        fields: const {},
      );

  factory ApiException.cancelled() => const ApiException(
        code: ApiErrorCodes.requestCancelled,
        message: 'Requête annulée.',
        fields: {},
      );

  bool get isThrottled => code == ApiErrorCodes.throttled;

  bool get isAccountInactive => code == ApiErrorCodes.accountInactive;

  /// Nombre de secondes avant de pouvoir retenter, uniquement renseigné
  /// par le backend sur une réponse THROTTLED (`fields.retry_after`).
  int? get retryAfterSeconds {
    if (!isThrottled) return null;
    final v = fields['retry_after'];
    return v is num ? v.toInt() : null;
  }

  bool get isNetworkError => code == ApiErrorCodes.networkError;

  bool get isAuthError => code == ApiErrorCodes.notAuthenticated;

  /// P8.3 : `InsufficientBalanceError` (backend) renvoie
  /// `fields: {solde_actuel, montant_requis}` — utilisé par
  /// `YkWalletDebitConfirmSheet` pour proposer une recharge plutôt qu'un
  /// message d'erreur générique.
  bool get isInsufficientBalance => code == ApiErrorCodes.insufficientBalance;

  int? get soldeActuel {
    if (!isInsufficientBalance) return null;
    final v = fields['solde_actuel'];
    return v is num ? v.toInt() : null;
  }

  int? get montantRequis {
    if (!isInsufficientBalance) return null;
    final v = fields['montant_requis'];
    return v is num ? v.toInt() : null;
  }

  @override
  String toString() => 'ApiException($code, status=$statusCode): $message';
}
