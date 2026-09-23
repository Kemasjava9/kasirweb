import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseReportDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) {
    final parts = value.contains('/') ? value.split('/') : value.split('-');
    if (parts.length == 3) {
      final first = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final last = int.tryParse(parts[2]);
      final day = value.contains('-') && parts[0].length == 4 ? last : first;
      final year = value.contains('-') && parts[0].length == 4 ? first : last;
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(value);
  }
  return null;
}

bool isReportDateInRange(dynamic value, DateTimeRange? range) {
  if (range == null) return true;
  final date = parseReportDate(value);
  if (date == null) return false;
  final day = DateTime(date.year, date.month, date.day);
  final start = DateTime(range.start.year, range.start.month, range.start.day);
  final end = DateTime(range.end.year, range.end.month, range.end.day);
  return !day.isBefore(start) && !day.isAfter(end);
}

class ReportDateRangeFilter extends StatelessWidget {
  const ReportDateRangeFilter({
    super.key,
    required this.range,
    required this.onChanged,
  });

  final DateTimeRange? range;
  final ValueChanged<DateTimeRange?> onChanged;

  Future<void> _pickRange(BuildContext context) async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      currentDate: DateTime.now(),
      initialDateRange: range,
      helpText: 'Pilih rentang tanggal laporan',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final label = range == null
        ? 'Semua tanggal'
        : '${_format(range!.start)} - ${_format(range!.end)}';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pickRange(context),
          icon: const Icon(Icons.date_range),
          label: Text(label),
        ),
        if (range != null)
          IconButton(
            tooltip: 'Hapus rentang tanggal',
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.clear),
          ),
      ],
    );
  }

  String _format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}