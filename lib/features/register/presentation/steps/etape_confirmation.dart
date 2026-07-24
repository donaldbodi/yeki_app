import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/repositories/formation_repository.dart';

/// Étape 5/5 (ou 2/2 pour un enseignant) — résumé en lecture seule des
/// étapes précédentes, avec un lien retour par section. Le bouton final
/// de soumission vit dans la barre de navigation partagée de
/// `RegisterPage` (pas ici) : la validation finale dépend aussi des
/// sélections des menus déroulants, hors du registre de
/// `YkFormController`.
class EtapeConfirmation extends StatelessWidget {
  const EtapeConfirmation({
    super.key,
    required this.nameCtrl,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.userType,
    required this.selectedParcours,
    required this.selectedDepartement,
    required this.selectedNiveau,
    required this.onEditStep,
  });

  final TextEditingController nameCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final ValueListenable<String> userType;
  final ValueListenable<ParcoursOption?> selectedParcours;
  final ValueListenable<DepartementOption?> selectedDepartement;
  final ValueListenable<String?> selectedNiveau;
  final ValueChanged<int> onEditStep;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Confirmation', style: YkTypography.h2(context)),
          SizedBox(height: YkSpacing.xs),
          Text(
            'Vérifiez vos informations avant de créer votre compte.',
            style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.md),
          YkCard(
            child: Padding(
              padding: EdgeInsets.all(YkSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Section(
                    title: 'Identité',
                    onEdit: () => onEditStep(0),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([nameCtrl, usernameCtrl, emailCtrl, userType]),
                      builder: (context, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          YkKeyValue(label: 'Nom', value: nameCtrl.text),
                          YkKeyValue(label: "Nom d'utilisateur", value: usernameCtrl.text),
                          YkKeyValue(label: 'Email', value: emailCtrl.text),
                          YkKeyValue(
                            label: 'Rôle',
                            value: userType.value == 'apprenant' ? 'Apprenant' : 'Enseignant',
                          ),
                        ],
                      ),
                    ),
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: userType,
                    builder: (context, type, _) {
                      if (type != 'apprenant') return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Divider(),
                          _Section(
                            title: 'Parcours',
                            onEdit: () => onEditStep(1),
                            child: ValueListenableBuilder<ParcoursOption?>(
                              valueListenable: selectedParcours,
                              builder: (context, p, _) =>
                                  YkKeyValue(label: 'Parcours', value: p?.nom ?? '—'),
                            ),
                          ),
                          const Divider(),
                          _Section(
                            title: 'Département',
                            onEdit: () => onEditStep(2),
                            child: ValueListenableBuilder<DepartementOption?>(
                              valueListenable: selectedDepartement,
                              builder: (context, d, _) =>
                                  YkKeyValue(label: 'Département', value: d?.nom ?? '—'),
                            ),
                          ),
                          const Divider(),
                          _Section(
                            title: 'Niveau',
                            onEdit: () => onEditStep(3),
                            child: ValueListenableBuilder<String?>(
                              valueListenable: selectedNiveau,
                              builder: (context, n, _) =>
                                  YkKeyValue(label: 'Niveau', value: n ?? '—'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.onEdit, required this.child});

  final String title;
  final VoidCallback onEdit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: YkTypography.label(context)),
            YkLink(label: 'Modifier', onTap: onEdit),
          ],
        ),
        child,
      ],
    );
  }
}
