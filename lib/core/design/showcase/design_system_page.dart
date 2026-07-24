import 'package:flutter/material.dart';
import 'package:yeki/core/network/api_exception.dart';

import '../components/components.dart';
import '../tokens/tokens.dart';

/// Galerie du design system — CDC_DESIGN §5.2 (« entrée dans la galerie
/// /design-system avec toutes ses variantes côte à côte »).
///
/// Remplace l'ancienne page `lib/views/pages/shared/design_system_page.dart`
/// (13 pastilles de couleur seulement) — même route `/design-system`, même
/// nom de classe, même garde `kDebugMode` (voir `guards.dart`).
///
/// Organisée en un onglet par catégorie CDC (§5.3) — Actions, Saisie,
/// Conteneurs, Données, Média, Feedback, Overlays — pour rester navigable
/// à l'échelle d'une cinquantaine de composants (P5). Des contrôles
/// globaux fixes au-dessus des onglets permettent de vérifier en 30
/// secondes qu'un composant tient dans les 5 ruptures × 2 thèmes × 7
/// états, sans avoir à le refaire écran par écran :
/// - **Clair/sombre** : bascule un [Theme] LOCAL à cette galerie (via
///   [Theme.of(context).brightness], seul signal que lisent les
///   composants Yk*) — il ne change pas le thème réel de l'app.
/// - **Rupture (compact → xlarge)** : force `MediaQuery.size` à une
///   largeur représentative de chaque palier de [YkBreakpoint], dans un
///   cadre de largeur fixe défilant horizontalement — n'affecte QUE la
///   zone de contenu de l'onglet actif, pas la barre de contrôles.
/// - **Échelle de texte (×0,85 → ×1,60)** et **animations réduites** :
///   forcent `MediaQuery.textScaler`/`disableAnimations` sur TOUTE la
///   page (contrôles compris), même plage que le clamp app-wide de
///   `YekiTheme.clampedBuilder`.
/// - **Aperçu des 12 couleurs de cours** : catalogue la définition du
///   token `YkCourseColors.palette` lui-même (outil de dev) — ne
///   contrevient pas à la règle métier P4.1/P4.7 qui réserve cette
///   palette au formulaire de création/modification de cours : il ne
///   s'agit pas ici d'afficher la couleur d'un cours existant.
class DesignSystemPage extends StatefulWidget {
  const DesignSystemPage({super.key});

  @override
  State<DesignSystemPage> createState() => _DesignSystemPageState();
}

/// Largeur simulée représentative de chaque rupture — constante
/// d'outillage de développement (pas une valeur métier, rule 3 ne
/// s'applique pas ici) choisie pour tomber franchement dans la tranche
/// correspondante de `YkBreakpoints.fromWidth`.
const Map<YkBreakpoint, double> _kBreakpointWidths = {
  YkBreakpoint.compact: 375,
  YkBreakpoint.medium: 700,
  YkBreakpoint.expanded: 1000,
  YkBreakpoint.large: 1300,
  YkBreakpoint.xlarge: 1700,
};

const Map<YkBreakpoint, String> _kBreakpointLabels = {
  YkBreakpoint.compact: 'Compact',
  YkBreakpoint.medium: 'Medium',
  YkBreakpoint.expanded: 'Expanded',
  YkBreakpoint.large: 'Large',
  YkBreakpoint.xlarge: 'XLarge',
};

class _DesignSystemPageState extends State<DesignSystemPage> with SingleTickerProviderStateMixin {
  Brightness _brightness = Brightness.light;
  bool _buttonLoading = false;

  YkBreakpoint _breakpoint = YkBreakpoint.xlarge;
  double _textScale = 1.0;
  bool _reducedMotion = false;

  late final TabController _tabController = TabController(length: 7, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(brightness: _brightness, useMaterial3: true),
      child: Builder(
        builder: (context) {
          final ambient = MediaQuery.of(context);
          return MediaQuery(
            data: ambient.copyWith(
              textScaler: TextScaler.linear(_textScale),
              disableAnimations: _reducedMotion,
            ),
            child: Builder(
              builder: (context) => Scaffold(
                backgroundColor: YkColors.background(context),
                appBar: AppBar(
                  title: const Text('Design system (debug)'),
                  actions: [
                    IconButton(
                      icon: Icon(_brightness == Brightness.dark ? Icons.dark_mode : Icons.light_mode),
                      tooltip: 'Basculer clair/sombre (prévisualisation)',
                      onPressed: () => setState(() {
                        _brightness = _brightness == Brightness.dark ? Brightness.light : Brightness.dark;
                      }),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    _GlobalControlsBar(
                      breakpoint: _breakpoint,
                      onBreakpointChanged: (b) => setState(() => _breakpoint = b),
                      textScale: _textScale,
                      onTextScaleChanged: (v) => setState(() => _textScale = v),
                      reducedMotion: _reducedMotion,
                      onReducedMotionChanged: (v) => setState(() => _reducedMotion = v),
                    ),
                    YkTabs(
                      controller: _tabController,
                      tabs: const [
                        YkTabItem(label: 'Actions'),
                        YkTabItem(label: 'Saisie'),
                        YkTabItem(label: 'Conteneurs'),
                        YkTabItem(label: 'Données'),
                        YkTabItem(label: 'Feedback'),
                        YkTabItem(label: 'Overlays'),
                        // Dernier onglet à dessein : YkVideoPlayer (dans ce
                        // dernier) appelle un vrai MethodChannel dès
                        // initState. En dernière position, aucune animation
                        // de transition entre 2 autres onglets ne traverse
                        // son index, donc il ne se construit que si on le
                        // visite explicitement (voir test/design_system_page_test.dart).
                        YkTabItem(label: 'Média'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildBreakpointFrame(context, _actionsSections(context)),
                          _buildBreakpointFrame(context, _inputsSections(context)),
                          _buildBreakpointFrame(context, _containersSections(context)),
                          _buildBreakpointFrame(context, _dataSections(context)),
                          _buildBreakpointFrame(context, _feedbackSections(context)),
                          _buildBreakpointFrame(context, _overlaysSections(context)),
                          _buildBreakpointFrame(context, _mediaSections(context)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Enveloppe le contenu d'un onglet dans un cadre de largeur fixe
  /// (simulateur de rupture) — défilement horizontal si la largeur
  /// simulée dépasse la fenêtre réelle, défilement vertical à
  /// l'intérieur du cadre pour le contenu lui-même. N'affecte que cette
  /// zone : la barre de contrôles au-dessus reste utilisable quelle que
  /// soit la rupture simulée.
  Widget _buildBreakpointFrame(BuildContext context, List<Widget> sections) {
    final width = _kBreakpointWidths[_breakpoint]!;
    final ambient = MediaQuery.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width,
        child: MediaQuery(
          data: ambient.copyWith(size: Size(width, ambient.size.height)),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: YkColors.border(context)), right: BorderSide(color: YkColors.border(context))),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(YkSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: sections,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────
  List<Widget> _actionsSections(BuildContext context) => [
    _Section(
      title: 'YkButton',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: YkSpacing.sm,
            runSpacing: YkSpacing.sm,
            children: [
              for (final variant in YkButtonVariant.values)
                YkButton(label: variant.name, onPressed: () {}, variant: variant),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Wrap(
            spacing: YkSpacing.sm,
            runSpacing: YkSpacing.sm,
            children: [
              for (final size in YkButtonSize.values)
                YkButton(label: size.name, onPressed: () {}, size: size),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Wrap(
            spacing: YkSpacing.sm,
            runSpacing: YkSpacing.sm,
            children: [
              const YkButton(label: 'Désactivé', onPressed: null),
              YkButton(
                label: 'Chargement',
                isLoading: _buttonLoading,
                onPressed: () async {
                  setState(() => _buttonLoading = true);
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) setState(() => _buttonLoading = false);
                },
              ),
              const YkButton(
                label: 'Avec icône',
                onPressed: null,
                icon: Icons.check,
              ),
              const YkButton(
                label: '',
                onPressed: null,
                icon: Icons.favorite,
                iconPosition: YkButtonIconPosition.only,
                semanticLabel: 'Favori',
              ),
            ],
          ),
        ],
      ),
    ),
    _Section(
      title: 'YkIconButton',
      child: Wrap(
        spacing: YkSpacing.sm,
        children: [
          for (final variant in YkIconButtonVariant.values)
            YkIconButton(
              icon: Icons.notifications_outlined,
              label: 'Notifications (${variant.name})',
              onPressed: () {},
              variant: variant,
            ),
        ],
      ),
    ),
    _Section(
      title: 'YkFab',
      child: Wrap(
        spacing: YkSpacing.md,
        runSpacing: YkSpacing.md,
        children: [
          YkFab(icon: Icons.add, label: 'Ajouter', onPressed: () {}),
          YkFab(
            icon: Icons.edit,
            label: 'Modifier',
            variant: YkFabVariant.extended,
            onPressed: () {},
          ),
          YkFab(
            icon: Icons.close,
            label: 'Fermer',
            variant: YkFabVariant.small,
            onPressed: () {},
          ),
        ],
      ),
    ),
    _Section(title: 'YkChip', child: _ChipDemo()),
    _Section(title: 'YkSegmented', child: _SegmentedDemo()),
    _Section(
      title: 'YkLink',
      child: Wrap(
        spacing: YkSpacing.md,
        children: [
          YkLink(label: 'Voir tous les cours', onTap: () {}),
          YkLink(label: 'Documentation', external: true, onTap: () {}),
        ],
      ),
    ),
  ];

  // ── Saisie ───────────────────────────────────────────────────────
  List<Widget> _inputsSections(BuildContext context) => [
    _Section(
      title: 'YkTextField',
      child: Column(
        children: [
          const YkTextField(label: 'Nom'),
          SizedBox(height: YkSpacing.sm),
          const YkTextField(label: 'Description', type: YkTextFieldType.multiline),
          SizedBox(height: YkSpacing.sm),
          const YkTextField(label: 'Mot de passe', type: YkTextFieldType.password),
          SizedBox(height: YkSpacing.sm),
          const YkTextField(hint: 'Rechercher…', type: YkTextFieldType.search),
          SizedBox(height: YkSpacing.sm),
          const YkTextField(label: 'Téléphone', type: YkTextFieldType.number),
          SizedBox(height: YkSpacing.sm),
          const YkTextField(label: 'Avec erreur', errorText: 'Ce champ est requis'),
        ],
      ),
    ),
    _Section(
      title: 'YkForm (coquille minimale — voir P4.4)',
      child: _FormDemo(),
    ),
    _Section(
      title: 'YkFileUpload',
      child: _FileUploadDemo(),
    ),
    _Section(
      title: 'YkRichEditor / YkRichViewer',
      child: _RichTextDemo(),
    ),
    _Section(title: 'YkDropdown', child: _DropdownDemo()),
    _Section(title: 'YkMultiSelect', child: _MultiSelectDemo()),
    _Section(
      title: 'YkSlider (barème par 0,25 — pas fourni par l\'appelant)',
      child: _SliderDemo(),
    ),
    _Section(
      title: 'YkStepper',
      child: _StepperDemo(),
    ),
    _Section(title: 'YkDateTimePicker', child: _DateTimePickerDemo()),
    _Section(
      title: 'YkOtpInput',
      child: YkOtpInput(
        onCompleted: (code) => YkSnack.success(context, 'Code saisi : $code'),
      ),
    ),
    _Section(title: 'YkColorPicker', child: _ColorPickerDemo()),
    _Section(title: 'YkIconPicker', child: _IconPickerDemo()),
    _Section(
      title: 'YkSearchBar (débounce 300 ms)',
      child: YkSearchBar(
        recentSearches: const ['Mathématiques', 'Physique'],
        onQueryChanged: (q) => YkSnack.info(context, 'Recherche : "$q"'),
      ),
    ),
  ];

  // ── Conteneurs ───────────────────────────────────────────────────
  List<Widget> _containersSections(BuildContext context) => [
    _Section(
      title: 'YkCard',
      child: Wrap(
        spacing: YkSpacing.sm,
        runSpacing: YkSpacing.sm,
        children: [
          for (final variant in YkCardVariant.values)
            SizedBox(
              width: 160,
              height: 100,
              child: YkCard(
                variant: variant,
                accentColor: variant == YkCardVariant.filled ? YkColors.primary500 : null,
                child: Text(variant.name),
              ),
            ),
        ],
      ),
    ),
    _Section(
      title: 'YkAppBar',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(YkRadius.md),
        child: YkAppBar(
          title: 'Titre d\'écran',
          showBackButton: true,
          onSearchChanged: (_) {},
          actions: [
            YkIconButton(icon: Icons.more_vert, label: 'Plus', onPressed: () {}),
          ],
        ),
      ),
    ),
    _Section(
      title: 'YkAdaptiveScaffold',
      child: _AdaptiveScaffoldDemo(),
    ),
    _Section(
      title: 'YkSheet (plein écran en compact, dialog centré en large)',
      child: YkButton(
        label: 'Ouvrir YkSheet',
        onPressed: () => YkSheet.show<void>(
          context: context,
          title: 'Titre de la feuille',
          bodyBuilder: (ctx) => Padding(
            padding: EdgeInsets.all(YkSpacing.md),
            child: Text(
              'Contenu de la feuille — plein écran en compact, dialog '
              'centré au-delà (voir YkBreakpoints).',
              style: YkTypography.bodyMd(ctx).copyWith(color: YkColors.textPrimary(ctx)),
            ),
          ),
          actionsBuilder: (ctx) => [
            YkButton(label: 'Fermer', onPressed: () => Navigator.of(ctx).pop()),
          ],
        ),
      ),
    ),
    _Section(
      title: 'YkDialog',
      child: Wrap(
        spacing: YkSpacing.sm,
        children: [
          YkButton(
            label: 'Confirmation',
            onPressed: () => YkDialog.confirm(
              context: context,
              title: 'Confirmer',
              message: 'Voulez-vous vraiment continuer ?',
            ),
          ),
          YkButton(
            label: 'Destructive',
            variant: YkButtonVariant.destructive,
            onPressed: () => YkDialog.confirm(
              context: context,
              title: 'Supprimer le cours',
              message: 'Cette action est irréversible.',
              variant: YkDialogVariant.destructive,
            ),
          ),
          YkButton(
            label: 'Alerte',
            variant: YkButtonVariant.secondary,
            onPressed: () => YkDialog.alert(
              context: context,
              title: 'Information',
              message: 'Votre session expire dans 5 minutes.',
            ),
          ),
        ],
      ),
    ),
    _Section(title: 'YkTabs', child: _TabsDemo()),
    _Section(
      title: 'YkSection',
      child: YkSection(
        title: 'Mes cours',
        subtitle: '4 cours en cours',
        actionLabel: 'Voir tout',
        onAction: () {},
        child: Text(
          'Contenu de la section (liste de cours, par ex.).',
          style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
        ),
      ),
    ),
    _Section(
      title: 'YkExpansion',
      child: YkExpansion(
        title: 'Module 1 — Introduction',
        subtitle: '3 leçons',
        child: Text(
          'Contenu déplié.',
          style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
        ),
      ),
    ),
  ];

  // ── Données ──────────────────────────────────────────────────────
  List<Widget> _dataSections(BuildContext context) => [
    _Section(
      title: 'YkAvatar / YkAvatarGroup',
      child: Wrap(
        spacing: YkSpacing.md,
        runSpacing: YkSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final size in YkAvatarSize.values)
            YkAvatar(fallbackText: 'Ada Lovelace', size: size),
          const YkAvatar(fallbackText: 'Kofi Yeboah', showPresence: true, isOnline: true),
          const YkAvatar(fallbackText: 'Awa Diallo', showPresence: true),
          YkAvatarGroup(
            avatars: const [
              YkAvatar(fallbackText: 'Ada Lovelace'),
              YkAvatar(fallbackText: 'Kofi Yeboah'),
              YkAvatar(fallbackText: 'Awa Diallo'),
              YkAvatar(fallbackText: 'Jean Mballa'),
              YkAvatar(fallbackText: 'Grace Fotso'),
            ],
          ),
        ],
      ),
    ),
    _Section(
      title: 'YkBadge',
      child: Wrap(
        spacing: YkSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const YkBadge(count: 3),
          const YkBadge(count: 150),
          const YkBadge(variant: YkBadgeVariant.dot),
          const YkBadge(variant: YkBadgeVariant.label, label: 'Nouveau'),
        ],
      ),
    ),
    _Section(
      title: 'YkProgress (anneau d\'XP)',
      child: Wrap(
        spacing: YkSpacing.lg,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: 160, child: YkProgress(value: 0.6)),
          const YkProgress(shape: YkProgressShape.circular, value: 0.4),
          const YkProgress(
            shape: YkProgressShape.xpRing,
            value: 0.72,
            centerLabel: '720 XP',
            size: 80,
          ),
        ],
      ),
    ),
    _Section(
      title: 'YkStatCard',
      child: Wrap(
        spacing: YkSpacing.sm,
        runSpacing: YkSpacing.sm,
        children: [
          SizedBox(
            width: 180,
            child: YkStatCard(
              value: '24',
              label: 'Cours actifs',
              icon: Icons.school,
              trendLabel: '+12 %',
              trendPositive: true,
            ),
          ),
          SizedBox(
            width: 180,
            child: YkStatCard(
              value: '3',
              label: 'Devoirs en retard',
              icon: Icons.assignment_late,
              trendLabel: '-2',
              trendPositive: false,
            ),
          ),
        ],
      ),
    ),
    _Section(
      title: 'YkDataTable (bascule en cartes en compact)',
      child: YkDataTable(
        columns: const [
          YkDataColumn(label: 'Nom'),
          YkDataColumn(label: 'Moyenne', numeric: true),
        ],
        rows: [
          YkDataRowData(cells: [const Text('Ada Lovelace'), const Text('16,5')]),
          YkDataRowData(cells: [const Text('Kofi Yeboah'), const Text('14,2')]),
          YkDataRowData(cells: [const Text('Awa Diallo'), const Text('18,0')]),
        ],
        cardBuilder: (context, i) {
          const noms = ['Ada Lovelace', 'Kofi Yeboah', 'Awa Diallo'];
          const moyennes = ['16,5', '14,2', '18,0'];
          return YkCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(noms[i]),
                Text(moyennes[i]),
              ],
            ),
          );
        },
      ),
    ),
    _Section(
      title: 'YkTimeline',
      child: YkTimeline(
        entries: const [
          YkTimelineEntry(
            title: 'Cours créé',
            subtitle: 'Mathématiques — Niveau 6e',
            time: 'il y a 2 j',
            icon: Icons.add_circle_outline,
          ),
          YkTimelineEntry(
            title: 'Exercice publié',
            subtitle: 'Fractions — 10 questions',
            time: 'il y a 1 j',
            icon: Icons.assignment_outlined,
          ),
          YkTimelineEntry(
            title: 'Note attribuée',
            subtitle: '18/20',
            time: 'à l\'instant',
            icon: Icons.check_circle_outline,
            color: YkColors.success,
          ),
        ],
      ),
    ),
    _Section(
      title: 'YkLeaderboard (podium)',
      child: YkLeaderboard(
        entries: const [
          YkLeaderboardEntry(rank: 1, name: 'Ada Lovelace', points: 980, delta: 0),
          YkLeaderboardEntry(rank: 2, name: 'Kofi Yeboah', points: 910, delta: 1),
          YkLeaderboardEntry(rank: 3, name: 'Awa Diallo', points: 875, delta: -1),
          YkLeaderboardEntry(
            rank: 4,
            name: 'Jean Mballa',
            points: 820,
            delta: 2,
            isCurrentUser: true,
          ),
          YkLeaderboardEntry(rank: 5, name: 'Grace Fotso', points: 790, delta: -1),
        ],
      ),
    ),
    _Section(title: 'YkRating', child: _RatingDemo()),
    _Section(
      title: 'YkCountdown (warning 25 %, error 10 %)',
      child: _CountdownDemo(),
    ),
    _Section(
      title: 'YkKeyValue',
      child: Column(
        children: const [
          YkKeyValue(label: 'Niveau', value: '6e', icon: Icons.school_outlined),
          YkKeyValue(label: 'Matière', value: 'Mathématiques', icon: Icons.calculate_outlined),
          YkKeyValue(label: 'Enseignant', value: 'M. Mballa', icon: Icons.person_outline),
        ],
      ),
    ),
  ];

  // ── Média ────────────────────────────────────────────────────────
  List<Widget> _mediaSections(BuildContext context) => [
    _Section(
      title: 'YkVideoPlayer',
      child: const AspectRatio(
        aspectRatio: 16 / 9,
        child: YkVideoPlayer(
          videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          chapters: [
            YkVideoChapter(label: 'Intro', position: Duration.zero),
            YkVideoChapter(label: 'Développement', position: Duration(seconds: 5)),
          ],
        ),
      ),
    ),
    _Section(
      title: 'YkAudioPlayer',
      child: const YkAudioPlayer(
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        label: 'Message vocal — forum',
      ),
    ),
    _Section(
      title: 'YkPdfViewer (filigrane nom + identifiant)',
      child: Container(
        padding: EdgeInsets.all(YkSpacing.md),
        decoration: BoxDecoration(
          color: YkColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(YkRadius.md),
        ),
        child: Text(
          'YkPdfViewer attend un fichier déjà téléchargé sur le disque '
          '(`filePath`) — il ne télécharge rien lui-même. Pas de fichier '
          'local disponible dans cette galerie de démonstration ; voir '
          '`lecture_lecon_page.dart` pour un usage réel avec filigrane '
          'dynamique nom + identifiant.',
          style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
        ),
      ),
    ),
    _Section(
      title: 'YkImageViewer',
      child: SizedBox(
        height: 240,
        child: YkImageViewer(
          imageUrls: [
            'https://picsum.photos/seed/yeki1/600/400',
            'https://picsum.photos/seed/yeki2/600/400',
          ],
        ),
      ),
    ),
    _Section(
      title: 'YkLessonFeed (flux vertical style TikTok)',
      child: SizedBox(
        height: 420,
        child: YkLessonFeed(
          items: [
            YkLessonFeedItem(
              id: '1',
              player: ColoredBox(
                color: YkColors.primary700,
                child: const Center(
                  child: Text('Leçon 1', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            YkLessonFeedItem(
              id: '2',
              player: ColoredBox(
                color: YkColors.primary500,
                child: const Center(
                  child: Text('Leçon 2', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
          onLike: (_) {},
          onFavorite: (_) {},
          onPreoccupation: (_) {},
          onShare: (_) {},
          onDownload: (_) {},
        ),
      ),
    ),
  ];

  // ── Feedback ─────────────────────────────────────────────────────
  List<Widget> _feedbackSections(BuildContext context) => [
    _Section(
      title: 'YkSkeleton',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const YkSkeleton.line(width: 200),
          SizedBox(height: YkSpacing.sm),
          const YkSkeleton.card(width: 200),
          SizedBox(height: YkSpacing.sm),
          const YkSkeleton.list(itemCount: 2),
          SizedBox(height: YkSpacing.sm),
          const YkSkeleton.grid(itemCount: 4),
          SizedBox(height: YkSpacing.sm),
          const YkSkeleton.table(rows: 2, columns: 3),
        ],
      ),
    ),
    _Section(
      title: 'YkEmptyState',
      child: SizedBox(
        height: 260,
        child: YkEmptyState(
          icon: Icons.assignment_outlined,
          title: 'Aucun devoir publié pour l\'instant',
          message: 'Revenez plus tard : votre enseignant n\'a encore rien publié.',
          actionLabel: 'Actualiser',
          onAction: () {},
        ),
      ),
    ),
    _Section(
      title: 'YkErrorState',
      child: SizedBox(
        height: 340,
        child: YkErrorState(
          message: 'Impossible de charger vos cours',
          cause: 'Vérifiez votre connexion internet',
          onRetry: () {},
          onContactSupport: () {},
        ),
      ),
    ),
    _Section(
      title: 'YkConfirmSheet',
      child: Wrap(
        spacing: YkSpacing.sm,
        runSpacing: YkSpacing.sm,
        children: [
          for (final policy in YkExitPolicy.values)
            YkButton(
              label: policy.name,
              size: YkButtonSize.sm,
              onPressed: () async {
                final quitter = await YkConfirmSheet.confirmExit(context, policy: policy);
                if (context.mounted) {
                  YkSnack.info(context, quitter ? 'Décision : quitter' : 'Décision : rester');
                }
              },
            ),
        ],
      ),
    ),
    _Section(
      title: 'YkSnack',
      child: Wrap(
        spacing: YkSpacing.sm,
        runSpacing: YkSpacing.sm,
        children: [
          YkButton(
            label: 'Succès',
            onPressed: () => YkSnack.success(context, 'Exercice créé avec succès'),
          ),
          YkButton(
            label: 'Erreur',
            variant: YkButtonVariant.destructive,
            onPressed: () => YkSnack.error(context, 'Une erreur est survenue'),
          ),
          YkButton(
            label: 'Avertissement',
            variant: YkButtonVariant.secondary,
            onPressed: () => YkSnack.warning(context, 'Échéance proche'),
          ),
          YkButton(
            label: 'Info + Annuler',
            variant: YkButtonVariant.tertiary,
            onPressed: () => YkSnack.info(
              context,
              'Cours archivé',
              onUndo: () {},
            ),
          ),
        ],
      ),
    ),
    _Section(title: 'YkOfflineBanner', child: _OfflineBannerDemo()),
    _Section(
      title: 'YkToast',
      child: YkButton(
        label: 'Afficher un toast',
        onPressed: () => YkToast.show(context, 'Modifications enregistrées'),
      ),
    ),
    _Section(
      title: 'YkCelebration (gain de rang)',
      child: YkButton(
        label: 'Simuler un gain de rang',
        onPressed: () => showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: YkCelebration(
              title: 'Félicitations !',
              statLabel: 'Nouveau rang au département',
              statValue: '#3',
              onDismiss: () => Navigator.of(ctx).pop(),
            ),
          ),
        ),
      ),
    ),
  ];

  // ── Overlays ─────────────────────────────────────────────────────
  List<Widget> _overlaysSections(BuildContext context) => [
    _Section(
      title: 'YkMenu',
      child: YkMenu<String>(
        items: const [
          YkMenuItem(value: 'edit', label: 'Modifier', icon: Icons.edit_outlined),
          YkMenuItem(value: 'delete', label: 'Supprimer', icon: Icons.delete_outline),
        ],
        onSelected: (v) => YkSnack.info(context, 'Action : $v'),
        child: const YkButton(label: 'Ouvrir le menu', onPressed: null),
      ),
    ),
    _Section(
      title: 'YkTooltip',
      child: YkTooltip(
        message: 'Nombre de points gagnés ce mois-ci',
        child: Icon(Icons.info_outline, color: YkColors.textSecondary(context)),
      ),
    ),
    _Section(title: 'YkPopover', child: _PopoverDemo()),
    _Section(title: 'YkOnboardingSpot', child: _OnboardingSpotDemo()),
    _Section(
      title: 'YkPaywall',
      child: YkPaywall(
        title: 'Débloquez le contenu premium',
        description: 'Accédez à tous les exercices corrigés et olympiades.',
        features: const [
          'Exercices corrigés illimités',
          'Accès à toutes les olympiades',
          'Support prioritaire',
        ],
        plans: [
          YkPaywallPlan(label: 'Mensuel', priceLabel: '1 500 FCFA/mois', onSelect: () {}),
          YkPaywallPlan(
            label: 'Annuel',
            priceLabel: '13 000 FCFA/an',
            badge: 'Économisez 28 %',
            onSelect: () {},
          ),
        ],
      ),
    ),
  ];
}

/// Barre de contrôles globaux — fixe au-dessus des onglets, s'applique à
/// toutes les catégories (voir doc de [DesignSystemPage]).
class _GlobalControlsBar extends StatelessWidget {
  const _GlobalControlsBar({
    required this.breakpoint,
    required this.onBreakpointChanged,
    required this.textScale,
    required this.onTextScaleChanged,
    required this.reducedMotion,
    required this.onReducedMotionChanged,
  });

  final YkBreakpoint breakpoint;
  final ValueChanged<YkBreakpoint> onBreakpointChanged;
  final double textScale;
  final ValueChanged<double> onTextScaleChanged;
  final bool reducedMotion;
  final ValueChanged<bool> onReducedMotionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(YkSpacing.sm),
      decoration: BoxDecoration(
        color: YkColors.surfaceVariant(context),
        border: Border(bottom: BorderSide(color: YkColors.border(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: YkSpacing.md,
            runSpacing: YkSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 380,
                child: YkSegmented<YkBreakpoint>(
                  segments: [
                    for (final b in YkBreakpoint.values)
                      YkSegment(value: b, label: _kBreakpointLabels[b]!),
                  ],
                  selected: breakpoint,
                  onChanged: onBreakpointChanged,
                ),
              ),
              SizedBox(
                width: 320,
                child: YkSlider(
                  label: 'Échelle de texte',
                  value: textScale,
                  min: 0.85,
                  max: 1.60,
                  step: 0.05,
                  valueFormatter: (v) => '×${v.toStringAsFixed(2)}',
                  onChanged: onTextScaleChanged,
                ),
              ),
              YkChip(
                label: 'Animations réduites',
                variant: YkChipVariant.filter,
                selected: reducedMotion,
                onSelected: onReducedMotionChanged,
              ),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Text(
            'Couleurs de cours (YkCourseColors.palette)',
            style: YkTypography.label(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.xs),
          Wrap(
            spacing: YkSpacing.sm,
            runSpacing: YkSpacing.xs,
            children: [
              for (final swatch in YkCourseColors.palette)
                YkTooltip(
                  message: '${swatch.nom} — ${YkColorPicker.hexOf(swatch.base)}',
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: swatch.base, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context)),
          ),
          SizedBox(height: YkSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _FormDemo extends StatefulWidget {
  @override
  State<_FormDemo> createState() => _FormDemoState();
}

class _FormDemoState extends State<_FormDemo> {
  final YkFormController _controller = YkFormController();
  final TextEditingController _titreCtrl = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _titreCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (_titreCtrl.text.trim().toLowerCase() == 'test') {
      // Simule une réponse 400 du serveur (enveloppe P1.6) pour démontrer
      // le mapping champ par champ sans dépendre d'un vrai appel réseau.
      throw ApiException(
        code: ApiErrorCodes.validationError,
        message: 'Le formulaire contient des erreurs.',
        fields: const {
          'titre': ['Ce titre existe déjà, choisissez-en un autre.'],
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return YkForm(
      controller: _controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YkTextField(
            name: 'titre',
            label: 'Titre',
            required: true,
            controller: _titreCtrl,
          ),
          SizedBox(height: YkSpacing.xs),
          Text(
            'Astuce galerie : tapez « test » puis validez pour simuler une '
            'erreur serveur mappée sur ce champ.',
            style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.sm),
          YkFormSubmitButton(
            controller: _controller,
            label: 'Valider',
            onValidSubmit: _submit,
            successMessage: 'Enregistré avec succès',
          ),
        ],
      ),
    );
  }
}

class _FileUploadDemo extends StatefulWidget {
  @override
  State<_FileUploadDemo> createState() => _FileUploadDemoState();
}

class _FileUploadDemoState extends State<_FileUploadDemo> {
  YkPickedFile? _picked;

  @override
  Widget build(BuildContext context) {
    return YkFileUpload(
      label: "Image d'énoncé",
      constraint: const YkFileConstraint(
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        maxSizeBytes: 5 * 1024 * 1024,
      ),
      picked: _picked,
      onChanged: (file) => setState(() => _picked = file),
    );
  }
}

class _RichTextDemo extends StatefulWidget {
  @override
  State<_RichTextDemo> createState() => _RichTextDemoState();
}

class _RichTextDemoState extends State<_RichTextDemo> {
  String _html = '<p>Modifiez ce texte…</p>';
  bool _preview = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _preview ? 'Aperçu (YkRichViewer)' : 'Édition (YkRichEditor)',
              style: YkTypography.label(context).copyWith(color: YkColors.textSecondary(context)),
            ),
            YkButton(
              label: _preview ? 'Éditer' : 'Aperçu',
              size: YkButtonSize.sm,
              variant: YkButtonVariant.secondary,
              onPressed: () => setState(() => _preview = !_preview),
            ),
          ],
        ),
        SizedBox(height: YkSpacing.xs),
        if (_preview)
          YkRichViewer(html: _html)
        else
          YkRichEditor(
            initialHtml: _html,
            onChanged: (html) => _html = html,
            label: "Énoncé (démo galerie)",
            imageConstraint: const YkFileConstraint(
              allowedExtensions: ['jpg', 'jpeg', 'png'],
              maxSizeBytes: 5 * 1024 * 1024,
            ),
            // Pas de vrai backend d'upload générique (constat P4.5) : la
            // galerie simule un hébergement immédiat.
            onUploadImage: (file) async {
              await Future.delayed(const Duration(milliseconds: 400));
              return 'https://picsum.photos/seed/${file.name}/400/240';
            },
          ),
      ],
    );
  }
}

class _AdaptiveScaffoldDemo extends StatefulWidget {
  @override
  State<_AdaptiveScaffoldDemo> createState() => _AdaptiveScaffoldDemoState();
}

class _AdaptiveScaffoldDemoState extends State<_AdaptiveScaffoldDemo> {
  static const _roles = [
    'apprenant',
    'enseignant',
    'enseignant_principal',
    'enseignant_cadre',
    'enseignant_admin',
    'admin',
    'service_client',
  ];

  String _role = 'apprenant';
  String? _selectedRouteName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Utilisez le simulateur de rupture ci-dessus pour voir les 5 '
          'ruptures (compact/medium/expanded/large/xlarge). Les destinations '
          'grisées n\'ont pas encore d\'écran (voir P4.6) — toucher affiche '
          '« Bientôt disponible ».',
          style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
        ),
        SizedBox(height: YkSpacing.sm),
        DropdownButton<String>(
          value: _role,
          items: [
            for (final role in _roles) DropdownMenuItem(value: role, child: Text(role)),
          ],
          onChanged: (role) => setState(() {
            _role = role!;
            _selectedRouteName = null;
          }),
        ),
        SizedBox(height: YkSpacing.sm),
        Container(
          height: 560,
          decoration: BoxDecoration(
            border: Border.all(color: YkColors.border(context)),
            borderRadius: BorderRadius.circular(YkRadius.md),
          ),
          clipBehavior: Clip.antiAlias,
          child: YkAdaptiveScaffold(
            groups: YkNavConfig.forRole(_role),
            selectedRouteName: _selectedRouteName,
            onDestinationTap: (routeName) => setState(() => _selectedRouteName = routeName),
            userName: 'Ada Lovelace',
            userRole: _role,
            onSettings: () => YkSnack.info(context, 'Paramètres'),
            onLogout: () => YkSnack.info(context, 'Déconnexion'),
            badges: const {'devoirs': 3, 'forum': 2, 'olympiade': 1, 'notifications': 5},
            contextPanel: Container(
              color: YkColors.surfaceVariant(context),
              padding: EdgeInsets.all(YkSpacing.md),
              child: Text(
                'Panneau contextuel (xlarge)\nProgression, activité récente, '
                'échéances, classement.',
                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
              ),
            ),
            body: Center(
              child: Text(
                'Corps de l\'écran\nRoute sélectionnée : ${_selectedRouteName ?? '(aucune)'}',
                textAlign: TextAlign.center,
                style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── P4.7 : démos des nouveaux composants ──────────────────────────

class _ChipDemo extends StatefulWidget {
  @override
  State<_ChipDemo> createState() => _ChipDemoState();
}

class _ChipDemoState extends State<_ChipDemo> {
  bool _filterSelected = false;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: YkSpacing.sm,
      runSpacing: YkSpacing.sm,
      children: [
        YkChip(
          label: 'Filtre',
          variant: YkChipVariant.filter,
          selected: _filterSelected,
          onSelected: (v) => setState(() => _filterSelected = v),
        ),
        YkChip(
          label: 'Saisie',
          variant: YkChipVariant.input,
          onDeleted: () {},
        ),
        YkChip(
          label: 'Assistant',
          variant: YkChipVariant.assist,
          onPressed: () {},
        ),
        YkChip(
          label: 'Suggestion',
          variant: YkChipVariant.suggestion,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _SegmentedDemo extends StatefulWidget {
  @override
  State<_SegmentedDemo> createState() => _SegmentedDemoState();
}

class _SegmentedDemoState extends State<_SegmentedDemo> {
  String _selected = 'facile';

  @override
  Widget build(BuildContext context) {
    return YkSegmented<String>(
      segments: const [
        YkSegment(value: 'facile', label: 'Facile'),
        YkSegment(value: 'moyen', label: 'Moyen'),
        YkSegment(value: 'difficile', label: 'Difficile'),
      ],
      selected: _selected,
      onChanged: (v) => setState(() => _selected = v),
    );
  }
}

class _DropdownDemo extends StatefulWidget {
  @override
  State<_DropdownDemo> createState() => _DropdownDemoState();
}

class _DropdownDemoState extends State<_DropdownDemo> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    return YkDropdown<String>(
      label: 'Niveau',
      value: _value,
      items: const [
        YkDropdownItem(value: '6e', label: '6e'),
        YkDropdownItem(value: '5e', label: '5e'),
        YkDropdownItem(value: '4e', label: '4e'),
        YkDropdownItem(value: '3e', label: '3e'),
      ],
      onChanged: (v) => setState(() => _value = v),
    );
  }
}

class _MultiSelectDemo extends StatefulWidget {
  @override
  State<_MultiSelectDemo> createState() => _MultiSelectDemoState();
}

class _MultiSelectDemoState extends State<_MultiSelectDemo> {
  Set<String> _selected = {'6e'};

  @override
  Widget build(BuildContext context) {
    return YkMultiSelect<String>(
      label: 'Niveaux accessibles',
      items: const [
        YkMultiSelectItem(value: '6e', label: '6e'),
        YkMultiSelectItem(value: '5e', label: '5e'),
        YkMultiSelectItem(value: '4e', label: '4e'),
        YkMultiSelectItem(value: '3e', label: '3e'),
      ],
      selectedValues: _selected,
      onChanged: (v) => setState(() => _selected = v),
    );
  }
}

class _SliderDemo extends StatefulWidget {
  @override
  State<_SliderDemo> createState() => _SliderDemoState();
}

class _SliderDemoState extends State<_SliderDemo> {
  double _value = 14;

  @override
  Widget build(BuildContext context) {
    return YkSlider(
      label: 'Note (barème /20, pas de 0,25)',
      value: _value,
      min: 0,
      max: 20,
      step: 0.25,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}

class _StepperDemo extends StatefulWidget {
  @override
  State<_StepperDemo> createState() => _StepperDemoState();
}

class _StepperDemoState extends State<_StepperDemo> {
  double _value = 3;

  @override
  Widget build(BuildContext context) {
    return YkStepper(
      label: 'Tentatives autorisées',
      value: _value,
      min: 1,
      max: 10,
      step: 1,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}

class _DateTimePickerDemo extends StatefulWidget {
  @override
  State<_DateTimePickerDemo> createState() => _DateTimePickerDemoState();
}

class _DateTimePickerDemoState extends State<_DateTimePickerDemo> {
  DateTime? _date;
  DateTime? _time;
  DateTime? _dateTime;
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        YkDateTimePicker(
          mode: YkDateTimePickerMode.date,
          label: 'Date (échéance)',
          value: _date,
          onChanged: (v) => setState(() => _date = v),
        ),
        SizedBox(height: YkSpacing.sm),
        YkDateTimePicker(
          mode: YkDateTimePickerMode.time,
          label: 'Heure',
          value: _time,
          onChanged: (v) => setState(() => _time = v),
        ),
        SizedBox(height: YkSpacing.sm),
        YkDateTimePicker(
          mode: YkDateTimePickerMode.dateTime,
          label: 'Date et heure (Africa/Douala)',
          value: _dateTime,
          onChanged: (v) => setState(() => _dateTime = v),
        ),
        SizedBox(height: YkSpacing.sm),
        YkDateTimePicker(
          mode: YkDateTimePickerMode.range,
          label: 'Plage (olympiade)',
          rangeValue: _range,
          onRangeChanged: (v) => setState(() => _range = v),
        ),
      ],
    );
  }
}

class _ColorPickerDemo extends StatefulWidget {
  @override
  State<_ColorPickerDemo> createState() => _ColorPickerDemoState();
}

class _ColorPickerDemoState extends State<_ColorPickerDemo> {
  String? _hex = '#008080';

  @override
  Widget build(BuildContext context) {
    return YkColorPicker(
      label: 'Couleur du cours',
      selectedHex: _hex,
      onChanged: (hex) => setState(() => _hex = hex),
    );
  }
}

class _IconPickerDemo extends StatefulWidget {
  @override
  State<_IconPickerDemo> createState() => _IconPickerDemoState();
}

class _IconPickerDemoState extends State<_IconPickerDemo> {
  IconData? _selected = Icons.school;

  static const _icons = [
    Icons.school,
    Icons.book,
    Icons.science,
    Icons.calculate,
    Icons.language,
  ];

  @override
  Widget build(BuildContext context) {
    return YkIconPicker(
      label: 'Icône du cours',
      icons: _icons,
      selected: _selected,
      onChanged: (icon) => setState(() => _selected = icon),
    );
  }
}

class _TabsDemo extends StatefulWidget {
  @override
  State<_TabsDemo> createState() => _TabsDemoState();
}

class _TabsDemoState extends State<_TabsDemo> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        YkTabs(
          controller: _controller,
          tabs: const [
            YkTabItem(label: 'Leçons'),
            YkTabItem(label: 'Exercices', badge: 3),
            YkTabItem(label: 'Devoirs', badge: 1),
            YkTabItem(label: 'Forum'),
          ],
        ),
        SizedBox(
          height: 100,
          child: TabBarView(
            controller: _controller,
            children: [
              Center(child: Text('Leçons', style: YkTypography.bodyMd(context))),
              Center(child: Text('Exercices', style: YkTypography.bodyMd(context))),
              Center(child: Text('Devoirs', style: YkTypography.bodyMd(context))),
              Center(child: Text('Forum', style: YkTypography.bodyMd(context))),
            ],
          ),
        ),
      ],
    );
  }
}

class _RatingDemo extends StatefulWidget {
  @override
  State<_RatingDemo> createState() => _RatingDemoState();
}

class _RatingDemoState extends State<_RatingDemo> {
  int _value = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const YkRating(value: 2, max: 3),
        SizedBox(height: YkSpacing.sm),
        YkRating(value: _value, onChanged: (v) => setState(() => _value = v)),
      ],
    );
  }
}

class _CountdownDemo extends StatefulWidget {
  @override
  State<_CountdownDemo> createState() => _CountdownDemoState();
}

class _CountdownDemoState extends State<_CountdownDemo> {
  int _runId = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        YkCountdown(
          key: ValueKey(_runId),
          duration: const Duration(seconds: 20),
          onExpired: () {},
        ),
        SizedBox(width: YkSpacing.sm),
        YkButton(
          label: 'Relancer (20 s)',
          size: YkButtonSize.sm,
          variant: YkButtonVariant.secondary,
          onPressed: () => setState(() => _runId++),
        ),
      ],
    );
  }
}

class _OfflineBannerDemo extends StatefulWidget {
  @override
  State<_OfflineBannerDemo> createState() => _OfflineBannerDemoState();
}

class _OfflineBannerDemoState extends State<_OfflineBannerDemo> {
  bool _offline = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(YkRadius.md),
          child: YkOfflineBanner(isOffline: _offline, pendingSyncCount: 2),
        ),
        SizedBox(height: YkSpacing.sm),
        YkButton(
          label: _offline ? 'Simuler retour en ligne' : 'Simuler perte de connexion',
          size: YkButtonSize.sm,
          variant: YkButtonVariant.secondary,
          onPressed: () => setState(() => _offline = !_offline),
        ),
      ],
    );
  }
}

class _PopoverDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) => YkButton(
        label: 'Ouvrir le popover',
        onPressed: () => YkPopover.show(
          context: buttonContext,
          contentBuilder: (ctx) => Text(
            'Contenu libre du popover.',
            style: YkTypography.bodySm(ctx).copyWith(color: YkColors.textPrimary(ctx)),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSpotDemo extends StatefulWidget {
  @override
  State<_OnboardingSpotDemo> createState() => _OnboardingSpotDemoState();
}

class _OnboardingSpotDemoState extends State<_OnboardingSpotDemo> {
  final GlobalKey _targetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: _targetKey,
          padding: EdgeInsets.all(YkSpacing.sm),
          decoration: BoxDecoration(
            color: YkColors.accent(context).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(YkRadius.md),
          ),
          child: Icon(Icons.emoji_events_outlined, color: YkColors.accent(context)),
        ),
        SizedBox(width: YkSpacing.sm),
        YkButton(
          label: 'Mettre en avant',
          size: YkButtonSize.sm,
          onPressed: () => YkOnboardingSpot.show(
            context: context,
            targetKey: _targetKey,
            title: 'Votre classement',
            message: 'Suivez ici votre rang au sein du département.',
          ),
        ),
      ],
    );
  }
}
