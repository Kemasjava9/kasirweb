import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Formats a date from various potential types (Timestamp, DateTime, String, etc.)
String formatFlexibleDate(dynamic date, String format, {String fallback = '-'}) {
  if (date == null) {
    return fallback;
  }

  try {
    DateTime? dateTime;

    if (date is DateTime) {
      dateTime = date;
    } else if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is String) {
      // Try to parse common formats, this is flexible
      if (date.contains('/')) {
        try {
          // Handles dd/MM/yyyy
          dateTime = DateFormat('dd/MM/yyyy').parseStrict(date);
        } catch (_) {}
      } 
      if (dateTime == null && date.contains('-')) {
         try {
          // Handles yyyy-MM-dd
          dateTime = DateFormat('yyyy-MM-dd').parseStrict(date);
        } catch (_) {}
      }
      // Fallback for ISO 8601 or other formats DateTime can handle
      dateTime ??= DateTime.tryParse(date);

    } else if (date is int) {
      // Assumes timestamp in milliseconds since epoch
      dateTime = DateTime.fromMillisecondsSinceEpoch(date);
    }

    // If a valid DateTime was obtained, format it
    if (dateTime != null) {
      return DateFormat(format, 'id_ID').format(dateTime);
    }

    // If all parsing fails, return the original value or fallback
    return date.toString();
    
  } catch (e) {
    // In case of any unexpected error during formatting, return fallback
    return fallback;
  }
}
