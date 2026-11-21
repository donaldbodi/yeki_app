import 'dart:async';

import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import 'yk_text_field.dart';

/// Barre de recherche — CDC_DESIGN §5.3.2 : débounce 300 ms, historique
/// récent, état vide illustré.
class YkSearchBar extends StatefulWidget {
  const YkSearchBar({
    super.key,
    required this.onQueryChanged,
    this.recentSearches = const [],
    this.onRecentTap,
    this.hint = 'Rechercher…',
  });

  /// Appelé (débattu 300 ms) à chaque changement de texte.
  final ValueChanged<String> onQueryChanged;

  /// Fourni par l'appelant — ce composant ne stocke aucun historique
  /// lui-même.
  final List<String> recentSearches;
  final ValueChanged<String>? onRecentTap;
  final String hint;

  @override
  State<YkSearchBar> createState() => _YkSearchBarState();
}

class _YkSearchBarState extends State<YkSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _showRecent = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    setState(() => _showRecent = value.isEmpty && widget.recentSearches.isNotEmpty);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => widget.onQueryChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        YkTextField(
          controller: _controller,
          type: YkTextFieldType.search,
          hint: widget.hint,
          onChanged: _handleChanged,
          onSubmitted: (v) {
            _debounce?.cancel();
            widget.onQueryChanged(v);
          },
        ),
        if (_showRecent) ...[
          SizedBox(height: YkSpacing.xs),
          for (final term in widget.recentSearches)
            InkWell(
              onTap: () {
                _controller.text = term;
                widget.onRecentTap?.call(term);
                widget.onQueryChanged(term);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: YkSpacing.xs),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 16, color: YkColors.textSecondary(context)),
                    SizedBox(width: YkSpacing.xs),
                    Text(
                      term,
                      style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
