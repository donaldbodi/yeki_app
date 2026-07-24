import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../tokens/tokens.dart';

/// Mode de [YkDateTimePicker] — CDC_DESIGN §5.3.2.
enum YkDateTimePickerMode { date, time, dateTime, range }

/// Sélecteur de date/heure — CDC_DESIGN §5.3.2. Localisation fr_CM,
/// fuseau Africa/Douala (`YkDoualaTime`) : la valeur affichée/éditée est
/// toujours interprétée comme une heure locale Douala, jamais l'heure du
/// périphérique de l'utilisateur.
class YkDateTimePicker extends StatelessWidget {
  const YkDateTimePicker({
    super.key,
    required this.mode,
    required this.label,
    this.value,
    this.rangeValue,
    this.onChanged,
    this.onRangeChanged,
    this.firstDate,
    this.lastDate,
  }) : assert(
         mode == YkDateTimePickerMode.range ? onRangeChanged != null : onChanged != null,
         'YkDateTimePicker.range attend onRangeChanged, les autres modes attendent onChanged.',
       );

  final YkDateTimePickerMode mode;
  final String label;
  final DateTime? value;
  final DateTimeRange? rangeValue;
  final ValueChanged<DateTime>? onChanged;
  final ValueChanged<DateTimeRange>? onRangeChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  String _display() {
    switch (mode) {
      case YkDateTimePickerMode.date:
        return value != null ? DateFormat.yMMMMd('fr_FR').format(value!) : 'Choisir une date';
      case YkDateTimePickerMode.time:
        return value != null ? DateFormat.Hm('fr_FR').format(value!) : 'Choisir une heure';
      case YkDateTimePickerMode.dateTime:
        return value != null
            ? '${DateFormat.yMMMMd('fr_FR').format(value!)} à ${DateFormat.Hm('fr_FR').format(value!)}'
            : 'Choisir une date et une heure';
      case YkDateTimePickerMode.range:
        if (rangeValue == null) return 'Choisir une plage';
        final f = DateFormat.yMMMd('fr_FR');
        return '${f.format(rangeValue!.start)} → ${f.format(rangeValue!.end)}';
    }
  }

  Future<void> _pick(BuildContext context) async {
    final first = firstDate ?? DateTime(2020);
    final last = lastDate ?? DateTime(2100);

    switch (mode) {
      case YkDateTimePickerMode.date:
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: first,
          lastDate: last,
          locale: const Locale('fr'),
        );
        if (picked != null) onChanged!(picked);
      case YkDateTimePickerMode.time:
        final picked = await showTimePicker(
          context: context,
          initialTime: value != null ? TimeOfDay.fromDateTime(value!) : TimeOfDay.now(),
        );
        if (picked != null) {
          final base = value ?? DateTime.now();
          onChanged!(DateTime(base.year, base.month, base.day, picked.hour, picked.minute));
        }
      case YkDateTimePickerMode.dateTime:
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: first,
          lastDate: last,
          locale: const Locale('fr'),
        );
        if (pickedDate == null || !context.mounted) return;
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: value != null ? TimeOfDay.fromDateTime(value!) : TimeOfDay.now(),
        );
        if (pickedTime == null) return;
        onChanged!(
          DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute),
        );
      case YkDateTimePickerMode.range:
        final picked = await showDateRangePicker(
          context: context,
          firstDate: first,
          lastDate: last,
          initialDateRange: rangeValue,
          locale: const Locale('fr'),
        );
        if (picked != null) onRangeChanged!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(YkRadius.sm),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: YkColors.surfaceVariant(context),
          suffixIcon: Icon(
            mode == YkDateTimePickerMode.time ? Icons.access_time : Icons.calendar_today_outlined,
            color: YkColors.textSecondary(context),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(YkRadius.sm),
            borderSide: BorderSide(color: YkColors.border(context)),
          ),
        ),
        child: Text(
          _display(),
          style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
        ),
      ),
    );
  }
}
