import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_icon_button.dart';

class YkDataColumn {
  const YkDataColumn({required this.label, this.numeric = false});
  final String label;
  final bool numeric;
}

class YkDataRowData {
  const YkDataRowData({required this.cells, this.onTap, this.selected = false});
  final List<Widget> cells;
  final VoidCallback? onTap;
  final bool selected;
}

/// Tableau de données — CDC_DESIGN §5.3.4 : tri, pagination, sélection,
/// **bascule automatique en liste de cartes en `compact`** — jamais de
/// défilement horizontal sur téléphone. Aucun legacy à migrer (aucun
/// `DataTable` natif ni tableau à colonnes multiples n'existait dans le
/// projet avant ce ticket).
class YkDataTable extends StatelessWidget {
  const YkDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.cardBuilder,
    this.onSort,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.showCheckboxColumn = false,
    this.currentPage,
    this.pageCount,
    this.onPageChanged,
  });

  final List<YkDataColumn> columns;
  final List<YkDataRowData> rows;

  /// Rendu carte d'une ligne — **requis** : le composant impose de
  /// définir une fois pour toutes à quoi ressemble une ligne en
  /// `compact`, plutôt que de laisser un tableau déborder horizontalement.
  final Widget Function(BuildContext context, int rowIndex) cardBuilder;

  final void Function(int columnIndex, bool ascending)? onSort;
  final int? sortColumnIndex;
  final bool sortAscending;
  final bool showCheckboxColumn;

  final int? currentPage;
  final int? pageCount;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    final compact = YkBreakpoints.of(context) == YkBreakpoint.compact;

    final content = compact
        ? Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                cardBuilder(context, i),
                if (i < rows.length - 1) SizedBox(height: YkSpacing.sm),
              ],
            ],
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              showCheckboxColumn: showCheckboxColumn,
              headingTextStyle: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
              dataTextStyle: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
              columns: [
                for (var c = 0; c < columns.length; c++)
                  DataColumn(
                    label: Text(columns[c].label),
                    numeric: columns[c].numeric,
                    onSort: onSort != null ? (i, asc) => onSort!(i, asc) : null,
                  ),
              ],
              rows: [
                for (final row in rows)
                  DataRow(
                    selected: row.selected,
                    onSelectChanged: row.onTap != null ? (_) => row.onTap!() : null,
                    cells: [for (final cell in row.cells) DataCell(cell)],
                  ),
              ],
            ),
          );

    if (currentPage == null || pageCount == null || pageCount! <= 1) return content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        SizedBox(height: YkSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            YkIconButton(
              icon: Icons.chevron_left,
              label: 'Page précédente',
              onPressed: currentPage! > 0 ? () => onPageChanged?.call(currentPage! - 1) : null,
            ),
            Text(
              'Page ${currentPage! + 1} / $pageCount',
              style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
            ),
            YkIconButton(
              icon: Icons.chevron_right,
              label: 'Page suivante',
              onPressed: currentPage! < pageCount! - 1 ? () => onPageChanged?.call(currentPage! + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}
