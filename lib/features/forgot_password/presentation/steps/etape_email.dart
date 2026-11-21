import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/repositories/auth_repository.dart';

/// Étape 1/3 — saisie de l'email. `YkFormController` propre à cette
/// étape, PAS partagé avec l'étape 3 (nouveau mot de passe) : l'
/// `IndexedStack` du wizard garde les 3 étapes montées simultanément,
/// un contrôleur partagé y enregistrerait les champs des deux étapes à
/// la fois — `YkFormController.canSubmit` exige TOUS les champs
/// enregistrés, pas seulement ceux de l'étape courante.
class EtapeEmail extends StatefulWidget {
  const EtapeEmail({super.key, required this.onCodeEnvoye});

  /// Email envoyé + `debug_code` éventuel (mode DEBUG serveur uniquement).
  final void Function(String email, String? debugCode) onCodeEnvoye;

  @override
  State<EtapeEmail> createState() => _EtapeEmailState();
}

class _EtapeEmailState extends State<EtapeEmail> {
  final _emailCtrl = TextEditingController();
  final _formController = YkFormController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _formController.dispose();
    super.dispose();
  }

  /// Réponse serveur volontairement générique (anti-énumération) : un
  /// 200 ne garantit pas que le compte existe. Seule vraie erreur
  /// attendue ici : le throttling 3/10min — converti en message
  /// explicite plutôt que laissé dans le résumé générique du formulaire.
  Future<void> _envoyerCode() async {
    try {
      final debugCode = await AuthRepository().forgotPassword(
        email: _emailCtrl.text.trim(),
      );
      widget.onCodeEnvoye(_emailCtrl.text.trim(), debugCode);
    } on ApiException catch (e) {
      if (!e.isThrottled) rethrow;
      final seconds = e.retryAfterSeconds;
      throw ApiException(
        code: e.code,
        message: seconds != null
            ? 'Trop de tentatives. Réessayez dans $seconds secondes.'
            : 'Trop de tentatives. Réessayez dans quelques instants.',
        fields: const {},
        statusCode: e.statusCode,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(YkSpacing.md),
      child: YkForm(
        controller: _formController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_unread_outlined, size: 48, color: YkColors.accent(context)),
            SizedBox(height: YkSpacing.md),
            Text(
              'Mot de passe oublié',
              textAlign: TextAlign.center,
              style: YkTypography.h2(context),
            ),
            SizedBox(height: YkSpacing.xs),
            Text(
              'Entrez votre email pour recevoir un code de vérification.',
              textAlign: TextAlign.center,
              style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
            ),
            SizedBox(height: YkSpacing.lg),
            YkTextField(
              controller: _emailCtrl,
              name: 'email',
              required: true,
              label: 'Email',
              prefixIcon: Icons.alternate_email_rounded,
              validator: (v) => v != null && v.contains('@') ? null : 'Adresse email invalide.',
            ),
            SizedBox(height: YkSpacing.lg),
            YkFormSubmitButton(
              controller: _formController,
              label: 'Envoyer le code',
              onValidSubmit: _envoyerCode,
              successMessage: 'Code envoyé. Vérifiez votre boîte email.',
            ),
          ],
        ),
      ),
    );
  }
}
