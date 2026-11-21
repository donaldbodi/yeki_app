import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_icon_button.dart';
import '../inputs/yk_text_field.dart';

/// Barre d'application générique — CDC_DESIGN §5.3.3.
///
/// Remplace `lib/widgets/yeki_app_bar.dart` (qui exportait en réalité
/// `YekiHeader`, un header d'accueil spécialisé — wallet, notifications,
/// menu profil — pas un app bar de navigation générique ; conservé,
/// déprécié, `cursus_page.dart` non migré dans ce ticket).
///
/// Deux modes : usage direct dans `Scaffold(appBar:)` (hauteur fixe), ou
/// [YkAppBar.sliver] pour un rétrécissement réel au défilement dans un
/// `NestedScrollView`/`CustomScrollView`.
class YkAppBar extends StatefulWidget implements PreferredSizeWidget {
  const YkAppBar({
    super.key,
    required this.title,
    this.showBackButton,
    this.actions = const [],
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.centerTitle = false,
  });

  final String title;

  /// `null` = automatique (affiché si une route précédente existe).
  final bool? showBackButton;
  final List<Widget> actions;

  /// Non nul → une icône de recherche apparaît dans les actions ; au tap,
  /// le titre bascule vers un champ de recherche.
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<YkAppBar> createState() => _YkAppBarState();

  /// Variante Sliver — pour les écrans à rétrécissement réel au
  /// défilement (motif déjà utilisé par `formation_detail_page.dart`).
  static Widget sliver({
    required BuildContext context,
    required String title,
    bool? showBackButton,
    List<Widget> actions = const [],
    double expandedHeight = 200,
    Widget? background,
  }) {
    final canPop = showBackButton ?? Navigator.canPop(context);
    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      backgroundColor: YkColors.surface(context),
      foregroundColor: YkColors.textPrimary(context),
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: canPop
          ? Center(
              child: YkIconButton(
                icon: Icons.arrow_back,
                label: 'Retour',
                onPressed: () => Navigator.maybePop(context),
              ),
            )
          : null,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
        ),
        background: background,
      ),
    );
  }
}

class _YkAppBarState extends State<YkAppBar> {
  bool _searching = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = widget.showBackButton ?? Navigator.canPop(context);
    final hasSearch = widget.onSearchChanged != null;

    Widget? leading;
    if (_searching) {
      leading = YkIconButton(
        icon: Icons.arrow_back,
        label: 'Fermer la recherche',
        onPressed: () => setState(() => _searching = false),
      );
    } else if (canPop) {
      leading = YkIconButton(
        icon: Icons.arrow_back,
        label: 'Retour',
        onPressed: () => Navigator.maybePop(context),
      );
    }

    final titleWidget = _searching
        ? YkTextField(
            type: YkTextFieldType.search,
            controller: _searchCtrl,
            hint: 'Rechercher…',
            autofocus: true,
            onChanged: widget.onSearchChanged,
            onSubmitted: widget.onSearchSubmitted,
          )
        : Text(
            widget.title,
            style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
            overflow: TextOverflow.ellipsis,
          );

    return Material(
      color: YkColors.surface(context),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              SizedBox(width: YkSpacing.xs),
              ?leading,
              SizedBox(width: YkSpacing.xs),
              Expanded(
                child: Align(
                  alignment: widget.centerTitle ? Alignment.center : Alignment.centerLeft,
                  child: titleWidget,
                ),
              ),
              if (hasSearch && !_searching)
                YkIconButton(
                  icon: Icons.search,
                  label: 'Rechercher',
                  onPressed: () => setState(() => _searching = true),
                ),
              ...widget.actions,
              SizedBox(width: YkSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}
