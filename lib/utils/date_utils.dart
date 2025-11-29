String formatFlexibleDate(dynamic date, String format, {String fallback = '-'}) {
  if (date == null) return fallback;

  try {
    DateTime dateTime;

    if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      // Try parsing various date formats
      try {
        // Try ISO format first
        dateTime = DateTime.parse(date);
      } catch (e) {
        // Try dd/MM/yyyy format
        try {
          final parts = date.split('/');
          if (parts.length == 3) {
            dateTime = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          } else {
            throw FormatException('Invalid date format');
          }
        } catch (e2) {
          // Try yyyy-MM-dd format
          try {
            final parts = date.split('-');
            if (parts.length == 3) {
              dateTime = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
            } else {
              throw FormatException('Invalid date format');
            }
          } catch (e3) {
            throw FormatException('Unable to parse date: $date');
          }
        }
      }
    } else if (date is int) {
      // Assume timestamp in milliseconds
      dateTime = DateTime.fromMillisecondsSinceEpoch(date);
    } else {
      return fallback;
    }

    // Format the date
    switch (format) {
      case 'dd/MM/yyyy':
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      case 'yyyy-MM-dd':
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      case 'dd-MM-yyyy':
        return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
      default:
        return dateTime.toString();
    }
  } catch (e) {
    return fallback;
  }
}
