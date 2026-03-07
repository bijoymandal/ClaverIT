import 'package:flutter/material.dart';

class CallLogEntry {
  final String? name;
  final String? number;
  final int? timestamp;
  final int? duration;
  final String? simDisplayName;
  final CallType? callType;
  final String? cachedMatchedNumber;

  CallLogEntry({
    this.name,
    this.number,
    this.timestamp,
    this.duration,
    this.simDisplayName,
    this.callType,
    this.cachedMatchedNumber,
  });

  /// Create from call_log package's CallLogEntry
  factory CallLogEntry.fromCallLog(dynamic callLogEntry) {
    return CallLogEntry(
      name: callLogEntry.name,
      number: callLogEntry.number,
      timestamp: callLogEntry.timestamp,
      duration: callLogEntry.duration,
      simDisplayName: callLogEntry.simDisplayName,
      // Note: 'callType' coming from the package is usually an enum (CallType)
      // but sometimes it is treated as dynamic. We convert it safely.
      callType: _parseCallType(callLogEntry.callType),
      cachedMatchedNumber: callLogEntry.cachedMatchedNumber,
    );
  }

  static CallType? _parseCallType(dynamic type) {
    if (type == null) return null;

    // Convert the call_log package enum to string for matching
    // or handle if it's already our internal enum
    final typeString = type.toString().toLowerCase();

    // Handle "CallType.incoming" -> "incoming"
    final cleanType = typeString.contains('.')
        ? typeString.split('.').last
        : typeString;

    switch (cleanType) {
      case 'incoming':
        return CallType.incoming;
      case 'outgoing':
        return CallType.outgoing;
      case 'missed':
        return CallType.missed;
      case 'rejected':
        return CallType.rejected;
      case 'blocked':
        return CallType.blocked;
      case 'unknown':
        return CallType.unknown;
      default:
        // Fallback for safety
        return CallType.unknown;
    }
  }

  /// Get formatted date string
  String get formattedDate {
    if (timestamp == null) return 'Unknown';

    final DateTime callDateTime = DateTime.fromMillisecondsSinceEpoch(
      timestamp!,
    );
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(callDateTime);

    if (difference.inDays == 0 && callDateTime.day == now.day) {
      // Today - show time
      final hour = callDateTime.hour;
      final minute = callDateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays < 2 && (now.day - callDateTime.day == 1)) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      // Show actual date
      return '${callDateTime.day}/${callDateTime.month}/${callDateTime.year}';
    }
  }

  /// Get formatted duration string
  String get formattedDuration {
    if (duration == null || duration == 0) return 'Not connected';

    final int hours = duration! ~/ 3600;
    final int minutes = (duration! % 3600) ~/ 60;
    final int seconds = duration! % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Get display name (name or number)
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (number != null && number!.isNotEmpty) return number!;
    return 'Unknown';
  }

  /// Get formatted number
  String get formattedNumber {
    if (number == null || number!.isEmpty) return 'Unknown';
    // TODO: Add proper phone number formatting logic here if needed
    return number!;
  }

  /// Get call type icon
  IconData get icon {
    switch (callType) {
      case CallType.incoming:
        return Icons.call_received;
      case CallType.outgoing:
        // Distinguish between answered and unanswered outgoing calls
        if (duration == 0) {
          return Icons.call_missed_outgoing;
        }
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
      case CallType.rejected:
        return Icons.call_missed_outgoing;
      case CallType.blocked:
        return Icons.block;
      default:
        return Icons.phone;
    }
  }

  /// Get call type color
  Color get color {
    switch (callType) {
      case CallType.incoming:
        return const Color(0xFF2196F3); // Blue for incoming answered
      case CallType.outgoing:
        // Distinguish between answered and unanswered outgoing calls
        if (duration == 0) {
          return Colors.red; // Red for outgoing missed/unanswered
        }
        return const Color(0xFF4CAF50); // Green for outgoing answered
      case CallType.missed:
        return Colors.red; // Red for incoming missed
      case CallType.rejected:
        return Colors.orange; // Orange for rejected
      case CallType.blocked:
        return Colors.grey; // Grey for blocked
      default:
        return Colors.grey;
    }
  }

  @override
  String toString() {
    return 'CallLogEntry(name: $name, number: $number, type: $callType, date: $formattedDate)';
  }
}

/// Enum for call types
enum CallType { incoming, outgoing, missed, rejected, blocked, unknown }
