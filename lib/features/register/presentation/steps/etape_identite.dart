import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

/// Étape 1/5 (ou 1/2 pour un enseignant) — identité + rôle. Les champs
/// sont enregistrés sur le `YkFormController` partagé de `RegisterPage`
/// (le mapping d'erreurs serveur par champ fonctionne même si l'erreur
/// arrive pendant que l'étape Confirmation est active).
class EtapeIdentite extends StatelessWidget {
  const EtapeIdentite({
    super.key,
    required this.nameCtrl,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.pwdCtrl,
    required this.confirmPwdCtrl,
    required this.userType,
  });

  final TextEditingController nameCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController pwdCtrl;
  final TextEditingController confirmPwdCtrl;
  final ValueNotifier<String> userType;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Créez votre compte', style: YkTypography.h2(context)),
          SizedBox(height: YkSpacing.xs),
          Text(
            'Vous êtes ?',
            style: YkTypography.label(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.xs),
          ValueListenableBuilder<String>(
            valueListenable: userType,
            builder: (context, value, _) => YkSegmented<String>(
              segments: const [
                YkSegment(value: 'apprenant', label: 'Apprenant', icon: Icons.school_rounded),
                YkSegment(value: 'enseignant', label: 'Enseignant', icon: Icons.workspace_premium_rounded),
              ],
              selected: value,
              onChanged: (v) => userType.value = v,
            ),
          ),
          SizedBox(height: YkSpacing.md),
          YkTextField(
            controller: nameCtrl,
            name: 'name',
            required: true,
            label: 'Nom complet',
            prefixIcon: Icons.badge_outlined,
          ),
          SizedBox(height: YkSpacing.sm),
          YkTextField(
            controller: usernameCtrl,
            name: 'username',
            required: true,
            label: "Nom d'utilisateur",
            prefixIcon: Icons.alternate_email_rounded,
          ),
          SizedBox(height: YkSpacing.sm),
          YkTextField(
            controller: emailCtrl,
            name: 'email',
            required: true,
            label: 'Email',
            prefixIcon: Icons.mail_outline_rounded,
            validator: (v) => v != null && v.contains('@') ? null : 'Adresse email invalide.',
          ),
          SizedBox(height: YkSpacing.sm),
          YkTextField(
            controller: pwdCtrl,
            name: 'password',
            type: YkTextFieldType.password,
            required: true,
            label: 'Mot de passe',
            prefixIcon: Icons.lock_outline_rounded,
            validator: (v) =>
                v != null && v.length >= 6 ? null : 'Au moins 6 caractères.',
          ),
          SizedBox(height: YkSpacing.sm),
          YkTextField(
            controller: confirmPwdCtrl,
            name: 'confirmPassword',
            type: YkTextFieldType.password,
            required: true,
            label: 'Confirmer le mot de passe',
            prefixIcon: Icons.lock_outline_rounded,
            validator: (v) =>
                v == pwdCtrl.text ? null : 'Les mots de passe ne correspondent pas.',
          ),
        ],
      ),
    );
  }
}
