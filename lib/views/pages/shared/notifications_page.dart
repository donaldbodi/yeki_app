// lib/views/pages/shared/notifications_page.dart
//
// Refondu en P10.4 (rituel P5.0) — basculement complet vers
// `NotificationRepository`/`AppNotification` (plus de `http`/
// `SharedPreferences` bruts, plus de classe `NotificationItem` locale
// dupliquant le modèle). `ChangeNotifier` (`NotificationsController`),
// pas `setState` (règle 7 de `check_design_system.sh`).
//
// Défauts corrigés par rapport à la version précédente : les 6 puces de
// filtre affichées ne filtraient réellement que sur « Non lues » (les
// autres ne changeaient que l'état visuel de sélection, jamais la liste
// affichée) ; le tap sur une notification ne faisait que la marquer comme
// lue, sans jamais lire `action_route` ni naviguer nulle part (exigence
// centrale du ticket : « clic → go_router vers action_route ») ; le type
// `paiement` manquait des tables couleur/icône ; la réponse paginée du
// backend (`{results:[...]}`) n'était pas gérée (cast direct en `List`,
// même classe de bug que celui trouvé dans `forum_page.dart`) — corrigé
// dans `NotificationRepository.list()`, pas ici.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/features/notifications/presentation/notifications_controller.dart';
import 'package:yeki/models/notification_models.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotificationsController();
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapNotification(AppNotification n) {
    if (!n.estLue) {
      _controller.marquerLue(n.id);
    }
    if (n.actionRoute.isNotEmpty) {
      context.go(n.actionRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: YkColors.background(context),
          // Dégradé de la même famille que les en-têtes Admin Général/
          // Historique (harmonieux avec le reste de l'app) — remplace
          // l'AppBar Material par défaut, sans en changer le comportement
          // (bouton retour/actions inchangés, juste re-habillé).
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: YkColors.textOnPrimary,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [YkColors.primary800, YkColors.primary700, YkColors.primary500],
                ),
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Notifications'),
                if (_controller.nonLuesCount > 0) ...[
                  SizedBox(width: YkSpacing.xs),
                  YkBadge(count: _controller.nonLuesCount),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: _controller.nonLuesCount > 0 ? _controller.marquerToutesLues : null,
                child: Text('Tout lire', style: YkTypography.label(context).copyWith(color: YkColors.textOnPrimary)),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Actualiser',
                onPressed: _controller.charger,
              ),
            ],
          ),
          body: Column(
            children: [
              _buildFiltres(context),
              Expanded(child: _buildCorps(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltres(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.sm),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            YkChip(
              label: 'Toutes',
              variant: YkChipVariant.filter,
              selected: _controller.filtre == NotificationsFiltre.toutes,
              onSelected: (_) => _controller.filtrerToutes(),
            ),
            SizedBox(width: YkSpacing.xs),
            YkChip(
              label: 'Non lues',
              variant: YkChipVariant.filter,
              selected: _controller.filtre == NotificationsFiltre.nonLues,
              onSelected: (_) => _controller.filtrerNonLues(),
            ),
            for (final type in AppNotificationType.values) ...[
              SizedBox(width: YkSpacing.xs),
              YkChip(
                label: _libelleType(type),
                variant: YkChipVariant.filter,
                selected:
                    _controller.filtre == NotificationsFiltre.parType &&
                    _controller.typeFiltre == type,
                onSelected: (_) => _controller.filtrerParType(type),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCorps(BuildContext context) {
    if (_controller.chargement) {
      return Padding(
        padding: EdgeInsets.all(YkSpacing.md),
        child: YkSkeleton.list(itemCount: 6, itemHeight: 84),
      );
    }
    if (_controller.enErreur) {
      return YkEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Impossible de charger vos notifications',
        message: 'Vérifiez votre connexion puis réessayez.',
        actionLabel: 'Réessayer',
        onAction: _controller.charger,
      );
    }
    final items = _controller.filtrees;
    if (items.isEmpty) {
      return YkEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'Aucune notification',
        message: _messageVide(),
      );
    }
    return RefreshIndicator(
      onRefresh: _controller.charger,
      child: ListView.separated(
        padding: EdgeInsets.all(YkSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(height: YkSpacing.sm),
        itemBuilder: (context, index) => _buildCarte(context, items[index]),
      ),
    );
  }

  String _messageVide() {
    switch (_controller.filtre) {
      case NotificationsFiltre.toutes:
        return "Vous n'avez reçu aucune notification pour l'instant.";
      case NotificationsFiltre.nonLues:
        return 'Toutes vos notifications ont déjà été lues.';
      case NotificationsFiltre.parType:
        return 'Aucune notification de type « ${_libelleType(_controller.typeFiltre!)} ».';
    }
  }

  Widget _buildCarte(BuildContext context, AppNotification n) {
    final style = _styleType(n.type);
    return Dismissible(
      key: ValueKey(n.id),
      direction: n.estLue ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _controller.marquerLue(n.id);
        return false;
      },
      background: ClipRRect(
        borderRadius: BorderRadius.circular(YkRadius.md),
        child: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(horizontal: YkSpacing.lg),
          color: YkColors.success.withValues(alpha: 0.12),
          child: Icon(Icons.done_rounded, color: YkColors.success),
        ),
      ),
      child: YkCard(
        variant: n.estLue ? YkCardVariant.outlined : YkCardVariant.filled,
        accentColor: n.estLue ? null : style.couleur,
        onTap: () => _onTapNotification(n),
        semanticLabel: n.titre,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: style.couleur.withValues(alpha: 0.14),
              child: Icon(style.icone, color: style.couleur, size: 20),
            ),
            SizedBox(width: YkSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.titre,
                    style: YkTypography.label(context).copyWith(
                      color: YkColors.textPrimary(context),
                      fontWeight: n.estLue ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: YkSpacing.xxs),
                  Text(
                    n.contenu,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: YkTypography.bodySm(
                      context,
                    ).copyWith(color: YkColors.textSecondary(context)),
                  ),
                  SizedBox(height: YkSpacing.xxs),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(n.creeLe),
                    style: YkTypography.caption(
                      context,
                    ).copyWith(color: YkColors.textTertiary(context)),
                  ),
                ],
              ),
            ),
            if (!n.estLue) ...[
              SizedBox(width: YkSpacing.xs),
              YkBadge(variant: YkBadgeVariant.dot, color: YkColors.accent(context)),
            ],
          ],
        ),
      ),
    );
  }

  String _libelleType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.devoir:
        return 'Devoirs';
      case AppNotificationType.correction:
        return 'Corrections';
      case AppNotificationType.olympiade:
        return 'Olympiades';
      case AppNotificationType.rappel:
        return 'Rappels';
      case AppNotificationType.classement:
        return 'Classements';
      case AppNotificationType.forum:
        return 'Forum';
      case AppNotificationType.system:
        return 'Système';
      case AppNotificationType.paiement:
        return 'Paiement';
    }
  }

  _StyleNotification _styleType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.devoir:
        return _StyleNotification(Icons.assignment_outlined, YkColors.info);
      case AppNotificationType.correction:
        return _StyleNotification(Icons.fact_check_outlined, YkColors.success);
      case AppNotificationType.olympiade:
        return _StyleNotification(Icons.emoji_events_outlined, YkColors.warning);
      case AppNotificationType.rappel:
        return _StyleNotification(Icons.alarm_outlined, YkColors.warning);
      case AppNotificationType.classement:
        return _StyleNotification(Icons.leaderboard_outlined, YkColors.info);
      case AppNotificationType.forum:
        return _StyleNotification(Icons.forum_outlined, YkColors.info);
      case AppNotificationType.paiement:
        return _StyleNotification(Icons.payments_outlined, YkColors.success);
      case AppNotificationType.system:
        return _StyleNotification(Icons.info_outline_rounded, YkColors.primary700);
    }
  }
}

class _StyleNotification {
  const _StyleNotification(this.icone, this.couleur);

  final IconData icone;
  final Color couleur;
}
