import 'package:flutter/material.dart';
import 'package:yeki/core/network/api_exception.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_button.dart';
import '../feedback/yk_snack.dart';

/// Contrôleur d'un [YkForm] — CDC_DESIGN §5.5.1.
///
/// Centralise ce que chaque écran du projet valide aujourd'hui à la main,
/// différemment (ou pas du tout) : suivi des champs requis, activation du
/// bouton de soumission, mapping des erreurs serveur (`ApiException
/// .fields`, déjà parsées par `ApiClient`/`ErrorInterceptor` — voir
/// `lib/core/network/api_exception.dart`) champ par champ, résumé en
/// tête, focus automatique sur la première erreur.
///
/// Possédé par l'écran appelant (comme un `TextEditingController`) : créé
/// dans `initState`, disposé dans `dispose`.
class YkFormController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final Set<String> _requiredFields = {};
  final Map<String, bool> _filled = {};
  final Map<String, String> _serverErrors = {};
  final Map<String, FocusNode> _focusNodes = {};
  final List<String> _order = [];

  bool _submitting = false;
  bool get isSubmitting => _submitting;

  /// Tous les champs requis sont remplis et aucune soumission n'est déjà
  /// en cours — exigence explicite : « bouton désactivé tant qu'un champ
  /// requis est vide ».
  bool get canSubmit => !_submitting && _requiredFields.every((n) => _filled[n] == true);

  /// Erreurs serveur courantes, pour le résumé en tête.
  List<String> get summaryErrors => _serverErrors.values.toList(growable: false);

  /// [initiallyFilled] : état rempli/vide AU MOMENT de l'enregistrement
  /// (P8.2) — jamais via un `updateFieldFilled` séparé juste après : un
  /// champ pré-rempli (valeur par défaut, mode édition) rendrait alors
  /// `notifyListeners()` pendant que l'arbre est encore en train d'être
  /// construit (le `AnimatedBuilder` de [YkForm] est lui-même en cours de
  /// `build`), ce qui lève `setState() called during build`. Sans objet
  /// pré-rempli, l'ancien comportement (`putIfAbsent(name, () => false)`
  /// puis un `updateFieldFilled` distinct) ne notifiait jamais réellement
  /// au premier montage (`false == false`) — d'où le bug resté invisible
  /// jusqu'ici (login/register n'ont que des champs vides au départ).
  void registerField(
    String name, {
    required bool required,
    FocusNode? focusNode,
    bool initiallyFilled = false,
  }) {
    if (!_order.contains(name)) _order.add(name);
    if (required) {
      _requiredFields.add(name);
    } else {
      _requiredFields.remove(name);
    }
    _filled[name] = initiallyFilled;
    if (focusNode != null) _focusNodes[name] = focusNode;
  }

  void unregisterField(String name) {
    _order.remove(name);
    _requiredFields.remove(name);
    _filled.remove(name);
    _serverErrors.remove(name);
    _focusNodes.remove(name);
  }

  void updateFieldFilled(String name, bool filled) {
    if (_filled[name] == filled) return;
    _filled[name] = filled;
    notifyListeners();
  }

  String? errorFor(String name) => _serverErrors[name];

  /// Efface l'erreur serveur d'un champ dès que l'utilisateur le modifie
  /// — une erreur serveur périmée ne doit pas persister après correction.
  void clearFieldError(String name) {
    if (_serverErrors.remove(name) != null) notifyListeners();
  }

  /// Valide localement, appelle [onValidSubmit], et gère les trois issues
  /// possibles :
  /// - succès → [YkSnack.success] systématique (exigence explicite) ;
  /// - `ApiException` (400 de validation) → mappe `fields` champ par
  ///   champ, réaffiche via une 2e passe de `validate()`, focus sur le
  ///   premier champ en erreur ;
  /// - autre exception → `YkSnack.error` générique, jamais le message brut
  ///   (cohérent avec `YkErrorState`).
  Future<void> submit({
    required BuildContext context,
    required Future<void> Function() onValidSubmit,
    required String successMessage,
  }) async {
    if (_submitting) return;
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (!canSubmit) return;

    _submitting = true;
    notifyListeners();
    try {
      await onValidSubmit();
      _serverErrors.clear();
      if (context.mounted) YkSnack.success(context, successMessage);
    } on ApiException catch (e) {
      final flattened = _flattenFields(e.fields);
      _serverErrors
        ..clear()
        ..addAll(flattened);
      // Certaines erreurs métier n'ont pas de champ précis à pointer (ex.
      // `ValidationError` de niveau formulaire — identifiants incorrects,
      // voir docs/ecarts/login.md) : `e.fields` est alors vide et le
      // message serait silencieusement perdu. `_form` n'est le nom
      // d'aucun `YkTextField` : il ne remonte que dans le résumé en tête.
      if (flattened.isEmpty) _serverErrors['_form'] = e.message;
      notifyListeners();
      formKey.currentState?.validate();
      _focusFirstError();
    } catch (_) {
      if (context.mounted) {
        YkSnack.error(context, 'Une erreur est survenue. Réessayez.');
      }
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Map<String, String> _flattenFields(Map<String, dynamic> fields) {
    final result = <String, String>{};
    for (final entry in fields.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        result[entry.key] = value.first.toString();
      } else if (value != null) {
        result[entry.key] = value.toString();
      }
    }
    return result;
  }

  void _focusFirstError() {
    for (final name in _order) {
      if (_serverErrors.containsKey(name)) {
        _focusNodes[name]?.requestFocus();
        return;
      }
    }
  }
}

/// Portée ambiante d'un [YkFormController] — les champs (`YkTextField`
/// nommé) s'y accrochent via [YkFormScope.maybeOf].
class YkFormScope extends InheritedNotifier<YkFormController> {
  const YkFormScope({super.key, required YkFormController controller, required super.child})
    : super(notifier: controller);

  static YkFormController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<YkFormScope>()?.notifier;
}

/// Enveloppe de validation — CDC_DESIGN §5.5.1, contrat complet (P4.4).
///
/// Affiche automatiquement un résumé des erreurs serveur en tête (aucun
/// widget séparé à ajouter par l'appelant).
class YkForm extends StatelessWidget {
  const YkForm({
    super.key,
    required this.controller,
    required this.child,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  final YkFormController controller;
  final Widget child;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return YkFormScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final summary = controller.summaryErrors;
          return Form(
            key: controller.formKey,
            autovalidateMode: autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (summary.isNotEmpty) ...[
                  YkFormErrorSummary(errors: summary),
                  SizedBox(height: YkSpacing.sm),
                ],
                child,
              ],
            ),
          );
        },
      ),
    );
  }
}

class YkFormErrorSummary extends StatelessWidget {
  const YkFormErrorSummary({super.key, required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(YkSpacing.sm),
      decoration: BoxDecoration(
        color: YkColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(YkRadius.sm),
        border: Border.all(color: YkColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: YkColors.error, size: 18),
              SizedBox(width: YkSpacing.xs),
              Text(
                'Le formulaire contient des erreurs',
                style: YkTypography.label(context).copyWith(color: YkColors.error),
              ),
            ],
          ),
          for (final message in errors) ...[
            SizedBox(height: YkSpacing.xxs),
            Text(
              '• $message',
              style: YkTypography.bodySm(context).copyWith(color: YkColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bouton de soumission connecté à un [YkFormController] — CDC_DESIGN
/// §5.5.1 : désactivé tant qu'un champ requis est vide, avec info-bulle
/// explicative ; `isLoading` piloté par `controller.isSubmitting`.
class YkFormSubmitButton extends StatelessWidget {
  const YkFormSubmitButton({
    super.key,
    required this.controller,
    required this.label,
    required this.onValidSubmit,
    required this.successMessage,
    this.variant = YkButtonVariant.primary,
    this.size = YkButtonSize.md,
  });

  final YkFormController controller;
  final String label;
  final Future<void> Function() onValidSubmit;
  final String successMessage;
  final YkButtonVariant variant;
  final YkButtonSize size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final button = YkButton(
          label: label,
          variant: variant,
          size: size,
          isLoading: controller.isSubmitting,
          onPressed: controller.canSubmit
              ? () => controller.submit(
                  context: context,
                  onValidSubmit: onValidSubmit,
                  successMessage: successMessage,
                )
              : null,
        );
        if (controller.canSubmit) return button;
        return Tooltip(message: 'Complétez les champs obligatoires', child: button);
      },
    );
  }
}
