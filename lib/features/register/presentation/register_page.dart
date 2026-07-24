// lib/features/register/presentation/register_page.dart
//
// Écran d'inscription. Refondu en P5.4 (rituel P5.0) — fiche d'écarts :
// docs/ecarts/register.md. Wizard 5 étapes (Identité/Parcours/
// Département/Niveau/Confirmation) via `IndexedStack` — les 5 étapes
// restent montées simultanément (aucune saisie perdue en revenant en
// arrière, aucune couche de sauvegarde de brouillon à construire).
//
// `StatefulWidget` simple (pas de besoin Riverpod). `lib/features/`
// interdit `setState` (règle 7) : tout l'état passe par
// `YkFormController` (déjà un ChangeNotifier) ou des `ValueNotifier`.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/auth_repository.dart';
import 'package:yeki/repositories/formation_repository.dart';

import 'steps/etape_confirmation.dart';
import 'steps/etape_departement.dart';
import 'steps/etape_identite.dart';
import 'steps/etape_niveau.dart';
import 'steps/etape_parcours.dart';

const _kLabelsApprenant = ['Identité', 'Parcours', 'Département', 'Niveau', 'Confirmation'];
const _kLabelsEnseignant = ['Identité', 'Confirmation'];
const _kIdentiteStep = 0;
const _kParcoursStep = 1;
const _kDepartementStep = 2;
const _kNiveauStep = 3;
const _kConfirmationStep = 4;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final YkFormController _formController;
  final ValueNotifier<int> _currentStep = ValueNotifier(_kIdentiteStep);
  final ValueNotifier<String> _userType = ValueNotifier('apprenant');

  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  final ValueNotifier<ParcoursOption?> _selectedParcours = ValueNotifier(null);
  final ValueNotifier<DepartementOption?> _selectedDepartement = ValueNotifier(null);
  final ValueNotifier<String?> _selectedNiveau = ValueNotifier(null);

  final ValueNotifier<List<ParcoursOption>?> _parcoursOptions = ValueNotifier(null);
  final ValueNotifier<List<DepartementOption>?> _departementOptions = ValueNotifier(null);
  final ValueNotifier<List<String>?> _niveauOptions = ValueNotifier(null);

  final _formationRepo = FormationRepository();

  bool get _isApprenant => _userType.value == 'apprenant';

  @override
  void initState() {
    super.initState();
    _formController = YkFormController();
    _loadParcours();
  }

  Future<void> _loadParcours() async {
    List<ParcoursOption> list;
    try {
      list = await _formationRepo.parcours();
    } catch (_) {
      list = const [];
    }
    if (mounted) _parcoursOptions.value = list;
  }

  Future<void> _onParcoursSelected(ParcoursOption? parcours) async {
    _selectedParcours.value = parcours;
    _selectedDepartement.value = null;
    _selectedNiveau.value = null;
    _departementOptions.value = null;
    _niveauOptions.value = null;
    if (parcours == null) return;

    List<DepartementOption> list;
    try {
      list = await _formationRepo.departementsForParcours(parcours.id);
    } catch (_) {
      list = const [];
    }
    // L'utilisateur a pu changer de parcours pendant le chargement.
    if (mounted && _selectedParcours.value?.id == parcours.id) {
      _departementOptions.value = list;
    }
  }

  Future<void> _onDepartementSelected(DepartementOption? departement) async {
    _selectedDepartement.value = departement;
    _selectedNiveau.value = null;
    _niveauOptions.value = null;
    if (departement == null) return;

    List<String> list;
    try {
      list = await _formationRepo.niveauxForDepartement(departement.id);
    } catch (_) {
      list = const [];
    }
    if (mounted && _selectedDepartement.value?.id == departement.id) {
      _niveauOptions.value = list;
    }
  }

  void _goNext() {
    if (_currentStep.value == _kIdentiteStep && !_isApprenant) {
      _currentStep.value = _kConfirmationStep;
    } else {
      _currentStep.value += 1;
    }
  }

  void _goBack() {
    if (_currentStep.value == _kConfirmationStep && !_isApprenant) {
      _currentStep.value = _kIdentiteStep;
    } else {
      _currentStep.value -= 1;
    }
  }

  bool _canAdvanceFromCurrentStep() {
    switch (_currentStep.value) {
      case _kIdentiteStep:
        return _formController.canSubmit;
      case _kParcoursStep:
        return _selectedParcours.value != null;
      case _kDepartementStep:
        return _selectedDepartement.value != null;
      case _kNiveauStep:
        return _selectedNiveau.value != null;
      default:
        return true;
    }
  }

  bool _canSubmitFinal() {
    if (!_formController.canSubmit) return false;
    if (!_isApprenant) return true;
    return _selectedParcours.value != null &&
        _selectedDepartement.value != null &&
        _selectedNiveau.value != null;
  }

  Future<void> _submitRegistration() async {
    await AuthRepository().register(
      name: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _pwdCtrl.text,
      userType: _userType.value,
      parcoursId: _isApprenant ? _selectedParcours.value?.id : null,
      departementId: _isApprenant ? _selectedDepartement.value?.id : null,
      niveau: _isApprenant ? _selectedNiveau.value : null,
    );
    // Le token renvoyé n'est pas utilisé pour une auto-connexion (décision
    // actée, voir docs/ecarts/register.md) : le flux redirige vers /login,
    // comme le faisait l'écran précédent.
    if (!mounted) return;
    context.replaceNamed(AppRoute.login);
  }

  @override
  void dispose() {
    _formController.dispose();
    _currentStep.dispose();
    _userType.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _selectedParcours.dispose();
    _selectedDepartement.dispose();
    _selectedNiveau.dispose();
    _parcoursOptions.dispose();
    _departementOptions.dispose();
    _niveauOptions.dispose();
    super.dispose();
  }

  Widget _buildSteps() {
    return IndexedStack(
      sizing: StackFit.expand,
      index: _currentStep.value,
      children: [
        EtapeIdentite(
          nameCtrl: _nameCtrl,
          usernameCtrl: _usernameCtrl,
          emailCtrl: _emailCtrl,
          pwdCtrl: _pwdCtrl,
          confirmPwdCtrl: _confirmPwdCtrl,
          userType: _userType,
        ),
        EtapeParcours(
          options: _parcoursOptions,
          selected: _selectedParcours,
          onSelected: _onParcoursSelected,
        ),
        EtapeDepartement(
          options: _departementOptions,
          selected: _selectedDepartement,
          onSelected: _onDepartementSelected,
        ),
        EtapeNiveau(
          options: _niveauOptions,
          selected: _selectedNiveau,
          onSelected: (n) => _selectedNiveau.value = n,
        ),
        EtapeConfirmation(
          nameCtrl: _nameCtrl,
          usernameCtrl: _usernameCtrl,
          emailCtrl: _emailCtrl,
          userType: _userType,
          selectedParcours: _selectedParcours,
          selectedDepartement: _selectedDepartement,
          selectedNiveau: _selectedNiveau,
          onEditStep: (i) => _currentStep.value = i,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // `YkForm` shrink-wrap son propre contenu (son `Column` interne mesure
    // TOUJOURS son enfant avec une hauteur non bornée, comme tout `Column`
    // mesurant un enfant non flexible — propriété générale de
    // `RenderFlex`, indépendante de `mainAxisSize`) : un `IndexedStack`
    // multi-étapes qui doit remplir l'espace restant de l'écran ne peut
    // donc pas être `YkForm.child` directement (overflow garanti, cas
    // jamais rencontré par les écrans `YkForm` existants — tous à une
    // seule page). `YkFormScope` + `Form` sont utilisés ici directement
    // (ce que `YkForm` fait en interne, moins sa `Column` shrink-wrap) :
    // identique pour l'enregistrement des champs et la validation, mais
    // sans imposer de hauteur non bornée à l'`IndexedStack`. Le résumé
    // d'erreurs (que `YkForm` afficherait automatiquement) est donc
    // reconstruit ici, juste au-dessus — voir `_ErrorSummaryBanner`.
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.md, YkSpacing.md, 0),
              child: AnimatedBuilder(
                animation: Listenable.merge([_currentStep, _userType]),
                builder: (context, _) {
                  final apprenant = _isApprenant;
                  final labels = apprenant ? _kLabelsApprenant : _kLabelsEnseignant;
                  final effectiveIndex = apprenant
                      ? _currentStep.value
                      : (_currentStep.value == _kIdentiteStep ? 0 : 1);
                  return YkStepIndicator(labels: labels, currentIndex: effectiveIndex);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.sm, YkSpacing.md, 0),
              child: _ErrorSummaryBanner(controller: _formController),
            ),
            Expanded(
              child: YkFormScope(
                controller: _formController,
                child: Form(
                  key: _formController.formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentStep,
                    builder: (context, step, _) => _buildSteps(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(YkSpacing.md),
              child: _NavigationBar(
                currentStep: _currentStep,
                userType: _userType,
                formController: _formController,
                selectedParcours: _selectedParcours,
                selectedDepartement: _selectedDepartement,
                selectedNiveau: _selectedNiveau,
                canAdvance: _canAdvanceFromCurrentStep,
                canSubmitFinal: _canSubmitFinal,
                onBack: _goBack,
                onNext: _goNext,
                onSubmitFinal: () => _formController.submit(
                  context: context,
                  onValidSubmit: _submitRegistration,
                  successMessage: 'Compte créé. Connectez-vous pour continuer.',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: YkSpacing.sm),
              child: TextButton(
                onPressed: () => context.pushNamed(AppRoute.login),
                child: const Text('Déjà un compte ? Se connecter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `YkForm` affiche ce résumé automatiquement lorsqu'il enveloppe tout le
/// contenu — impossible ici (voir le commentaire dans `build()` :
/// `YkForm.child` ne peut pas contenir l'`IndexedStack` extensible sans
/// provoquer un débordement). Reprend directement `YkFormErrorSummary`
/// (composant public du design system, pas une réécriture) au lieu de
/// dupliquer sa présentation.
class _ErrorSummaryBanner extends StatelessWidget {
  const _ErrorSummaryBanner({required this.controller});

  final YkFormController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final errors = controller.summaryErrors;
        if (errors.isEmpty) return const SizedBox.shrink();
        return YkFormErrorSummary(errors: errors);
      },
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.currentStep,
    required this.userType,
    required this.formController,
    required this.selectedParcours,
    required this.selectedDepartement,
    required this.selectedNiveau,
    required this.canAdvance,
    required this.canSubmitFinal,
    required this.onBack,
    required this.onNext,
    required this.onSubmitFinal,
  });

  final ValueNotifier<int> currentStep;
  final ValueNotifier<String> userType;
  final YkFormController formController;
  final ValueNotifier<ParcoursOption?> selectedParcours;
  final ValueNotifier<DepartementOption?> selectedDepartement;
  final ValueNotifier<String?> selectedNiveau;
  final bool Function() canAdvance;
  final bool Function() canSubmitFinal;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmitFinal;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        currentStep,
        userType,
        formController,
        selectedParcours,
        selectedDepartement,
        selectedNiveau,
      ]),
      builder: (context, _) {
        final isFirst = currentStep.value == _kIdentiteStep;
        final isLast = currentStep.value == _kConfirmationStep;
        return Row(
          children: [
            if (!isFirst) ...[
              YkButton(
                label: 'Précédent',
                variant: YkButtonVariant.secondary,
                onPressed: onBack,
              ),
              SizedBox(width: YkSpacing.sm),
            ],
            Expanded(
              child: isLast
                  ? YkButton(
                      label: 'Créer mon compte',
                      isLoading: formController.isSubmitting,
                      onPressed: canSubmitFinal() ? onSubmitFinal : null,
                    )
                  : YkButton(
                      label: 'Suivant',
                      onPressed: canAdvance() ? onNext : null,
                    ),
            ),
          ],
        );
      },
    );
  }
}
