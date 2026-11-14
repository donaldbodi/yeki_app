import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/auth_repository.dart';

/// Étape 3/3 — nouveau mot de passe. `YkFormController` propre à cette
/// étape (voir `EtapeEmail` pour la raison : pas de contrôleur partagé
/// entre étapes montées simultanément par l'`IndexedStack` du wizard).
class EtapeNouveauMdp extends StatefulWidget {
  const EtapeNouveauMdp({super.key, required this.email, required this.resetToken});

  final String email;
  final ValueListenable<String?> resetToken;

  @override
  State<EtapeNouveauMdp> createState() => _EtapeNouveauMdpState();
}

class _EtapeNouveauMdpState extends State<EtapeNouveauMdp> {
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formController = YkFormController();
  final ValueNotifier<bool> _succes = ValueNotifier(false);

  @override
  void dispose() {
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    _formController.dispose();
    _succes.dispose();
    super.dispose();
  }

  Future<void> _reinitialiser() async {
    await AuthRepository().resetPassword(
      email: widget.email,
      resetToken: widget.resetToken.value ?? '',
      newPassword: _pwdCtrl.text,
      confirmPassword: _confirmCtrl.text,
    );
    _succes.value = true;
  }

  String? _validerMotDePasse(String? v) {
    if (v == null || v.length < 8) return 'Au moins 8 caractères.';
    if (!RegExp(r'[a-zA-Z]').hasMatch(v)) return 'Au moins une lettre.';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Au moins un chiffre.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _succes,
      builder: (context, succes, _) => succes ? _buildSucces(context) : _buildFormulaire(context),
    );
  }

  Widget _buildSucces(BuildContext context) {
    return YkEmptyState(
      icon: Icons.check_circle_outline_rounded,
      title: 'Mot de passe réinitialisé',
      message: 'Connectez-vous avec votre nouveau mot de passe.',
      actionLabel: 'Se connecter',
      onAction: () => context.goNamed(AppRoute.login),
    );
  }

  Widget _buildFormulaire(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(YkSpacing.md),
      child: YkForm(
        controller: _formController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_reset_outlined, size: 48, color: YkColors.accent(context)),
            SizedBox(height: YkSpacing.md),
            Text(
              'Nouveau mot de passe',
              textAlign: TextAlign.center,
              style: YkTypography.h2(context),
            ),
            SizedBox(height: YkSpacing.lg),
            YkTextField(
              controller: _pwdCtrl,
              name: 'newPassword',
              type: YkTextFieldType.password,
              required: true,
              label: 'Nouveau mot de passe',
              prefixIcon: Icons.lock_outline_rounded,
              validator: _validerMotDePasse,
            ),
            SizedBox(height: YkSpacing.xs),
            AnimatedBuilder(
              animation: _pwdCtrl,
              builder: (context, _) => _ChecklistMotDePasse(motDePasse: _pwdCtrl.text),
            ),
            SizedBox(height: YkSpacing.sm),
            YkTextField(
              controller: _confirmCtrl,
              name: 'confirmPassword',
              type: YkTextFieldType.password,
              required: true,
              label: 'Confirmer le mot de passe',
              prefixIcon: Icons.shield_outlined,
              validator: (v) =>
                  v == _pwdCtrl.text ? null : 'Les mots de passe ne correspondent pas.',
            ),
            SizedBox(height: YkSpacing.lg),
            YkFormSubmitButton(
              controller: _formController,
              label: 'Réinitialiser',
              onValidSubmit: _reinitialiser,
              successMessage: 'Mot de passe réinitialisé.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Reprend les critères déjà validés côté backend (8+ caractères, 1
/// lettre, 1 chiffre) — checklist en direct via `AnimatedBuilder` sur le
/// `TextEditingController` (déjà un `Listenable`), sans `setState`.
class _ChecklistMotDePasse extends StatelessWidget {
  const _ChecklistMotDePasse({required this.motDePasse});

  final String motDePasse;

  bool get _longueur => motDePasse.length >= 8;
  bool get _lettre => RegExp(r'[a-zA-Z]').hasMatch(motDePasse);
  bool get _chiffre => RegExp(r'[0-9]').hasMatch(motDePasse);

  @override
  Widget build(BuildContext context) {
    return YkCard(
      variant: YkCardVariant.filled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Critères requis',
            style: YkTypography.label(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.xxs),
          _regle(context, 'Au moins 8 caractères', _longueur),
          _regle(context, 'Au moins une lettre', _lettre),
          _regle(context, 'Au moins un chiffre', _chiffre),
        ],
      ),
    );
  }

  Widget _regle(BuildContext context, String label, bool valide) {
    final color = valide ? YkColors.success : YkColors.textTertiary(context);
    return Padding(
      padding: EdgeInsets.only(top: YkSpacing.xxs),
      child: Row(
        children: [
          Icon(valide ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: color),
          SizedBox(width: YkSpacing.xs),
          Text(label, style: YkTypography.bodySm(context).copyWith(color: color)),
        ],
      ),
    );
  }
}
