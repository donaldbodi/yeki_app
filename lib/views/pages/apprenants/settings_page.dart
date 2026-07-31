// lib/views/pages/apprenants/settings_page.dart
//
// Refondu en P11.8 (rituel P5.0) : bascule vers `AuthRepository` (plus de
// `http` brut) et les tokens/composants `Yk*` — `YkDialog.confirm`
// remplace 2 `AlertDialog` quasi identiques faits main.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/auth_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _repo = AuthRepository();
  bool _notifEnabled = true;
  bool _biometry = false;
  static const _lang = 'Français';

  @override
  void initState() {
    super.initState();
    _chargerParametres();
  }

  Future<void> _chargerParametres() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifEnabled = prefs.getBool('notifications_enabled') ?? true;
      _biometry = prefs.getBool('biometry_enabled') ?? false;
    });
  }

  Future<void> _sauvegarderParametres() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notifEnabled);
    await prefs.setBool('biometry_enabled', _biometry);
  }

  Future<void> _confirmerDeconnexion() async {
    final confirme = await YkDialog.confirm(
      context: context,
      title: 'Déconnexion',
      message: 'Souhaitez-vous vraiment vous déconnecter ?',
      confirmLabel: 'Se déconnecter',
      variant: YkDialogVariant.destructive,
    );
    if (confirme == true) await authState.logout();
  }

  Future<void> _confirmerSuppression() async {
    final confirme = await YkDialog.confirm(
      context: context,
      title: 'Supprimer le compte',
      message: 'Cette action est irréversible. Toutes vos données seront perdues.',
      confirmLabel: 'Supprimer',
      variant: YkDialogVariant.destructive,
    );
    if (confirme != true) return;

    try {
      await _repo.deleteAccount();
      if (mounted) await authState.clearSession();
    } on ApiException catch (e) {
      if (mounted) YkSnack.error(context, e.message);
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur réseau.');
    }
  }

  Future<void> _changerMotDePasse(String ancien, String nouveau, String confirmation) async {
    if (nouveau != confirmation) {
      YkSnack.error(context, 'Les mots de passe ne correspondent pas.');
      return;
    }
    if (nouveau.length < 8) {
      YkSnack.error(context, 'Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }
    try {
      final nouveauToken = await _repo.changePassword(oldPassword: ancien, newPassword: nouveau);
      if (!mounted) return;
      YkSnack.success(context, 'Mot de passe modifié avec succès !');
      if (nouveauToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', nouveauToken);
      }
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) YkSnack.error(context, e.message);
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur réseau.');
    }
  }

  void _ouvrirChangerMdpSheet() {
    final ancienCtrl = TextEditingController();
    final nouveauCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    YkSheet.show<void>(
      context: context,
      title: 'Changer le mot de passe',
      bodyBuilder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YkTextField(controller: ancienCtrl, label: 'Ancien mot de passe', type: YkTextFieldType.password),
          SizedBox(height: YkSpacing.sm),
          YkTextField(controller: nouveauCtrl, label: 'Nouveau mot de passe', type: YkTextFieldType.password),
          SizedBox(height: YkSpacing.sm),
          YkTextField(controller: confirmCtrl, label: 'Confirmer le nouveau', type: YkTextFieldType.password),
        ],
      ),
      actionsBuilder: (ctx) => [
        YkButton(
          label: 'Confirmer',
          onPressed: () => _changerMotDePasse(ancienCtrl.text, nouveauCtrl.text, confirmCtrl.text),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: EdgeInsets.all(YkSpacing.md),
        children: [
          YkSection(
            title: 'Sécurité',
            child: _tuile(context, icon: Icons.lock_reset_rounded, titre: 'Changer le mot de passe', onTap: _ouvrirChangerMdpSheet),
          ),
          SizedBox(height: YkSpacing.md),
          YkSection(
            title: 'Notifications',
            child: _tuileInterrupteur(
              context,
              icon: Icons.notifications_rounded,
              titre: 'Notifications push',
              sousTitre: "Recevoir les alertes de l'app",
              valeur: _notifEnabled,
              onChanged: (v) {
                setState(() => _notifEnabled = v);
                _sauvegarderParametres();
              },
            ),
          ),
          SizedBox(height: YkSpacing.md),
          YkSection(
            title: 'Préférences',
            child: Column(
              children: [
                _tuile(context, icon: Icons.language_rounded, titre: 'Langue', trailing: Text(_lang, style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context))), onTap: () {}),
                SizedBox(height: YkSpacing.xs),
                _tuileInterrupteur(
                  context,
                  icon: Icons.fingerprint_rounded,
                  titre: 'Biométrie',
                  sousTitre: 'Connexion par empreinte / Face ID',
                  valeur: _biometry,
                  onChanged: (v) {
                    setState(() => _biometry = v);
                    _sauvegarderParametres();
                  },
                ),
                SizedBox(height: YkSpacing.xs),
                _tuile(context, icon: Icons.replay_rounded, titre: "Revoir l'introduction", onTap: () => context.goNamed(AppRoute.onboarding)),
              ],
            ),
          ),
          SizedBox(height: YkSpacing.md),
          YkSection(
            title: 'Compte',
            child: Column(
              children: [
                _tuile(context, icon: Icons.logout_rounded, titre: 'Se déconnecter', onTap: _confirmerDeconnexion),
                SizedBox(height: YkSpacing.xs),
                _tuile(context, icon: Icons.delete_forever_rounded, titre: 'Supprimer mon compte', couleurTitre: YkColors.error, onTap: _confirmerSuppression),
              ],
            ),
          ),
          SizedBox(height: YkSpacing.lg),
          Center(child: Text('Yéki v1.0.3', style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context)))),
        ],
      ),
    );
  }

  Widget _tuile(BuildContext context, {required IconData icon, required String titre, Color? couleurTitre, Widget? trailing, required VoidCallback onTap}) {
    return YkCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(YkSpacing.xs),
            decoration: BoxDecoration(color: YkColors.accent(context).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(YkRadius.sm)),
            child: Icon(icon, color: YkColors.accent(context), size: 18),
          ),
          SizedBox(width: YkSpacing.sm),
          Expanded(child: Text(titre, style: YkTypography.bodyMd(context).copyWith(color: couleurTitre ?? YkColors.textPrimary(context), fontWeight: FontWeight.w600))),
          trailing ?? Icon(Icons.chevron_right_rounded, size: 18, color: YkColors.textTertiary(context)),
        ],
      ),
    );
  }

  Widget _tuileInterrupteur(BuildContext context, {required IconData icon, required String titre, required String sousTitre, required bool valeur, required ValueChanged<bool> onChanged}) {
    return YkCard(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(YkSpacing.xs),
            decoration: BoxDecoration(color: YkColors.accent(context).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(YkRadius.sm)),
            child: Icon(icon, color: YkColors.accent(context), size: 18),
          ),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w600)),
                Text(sousTitre, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
              ],
            ),
          ),
          Switch(value: valeur, onChanged: onChanged, activeTrackColor: YkColors.accent(context)),
        ],
      ),
    );
  }
}
