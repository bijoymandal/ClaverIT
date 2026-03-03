import 'package:flutter/material.dart';
import '../models/meeting.dart';
import 'package:uuid/uuid.dart';

class MeetingProvider with ChangeNotifier {
  final List<Meeting> _meetings = [
    // Add some initial dummy data
    Meeting(
      id: '1',
      title: 'Project Sync',
      dateTime: DateTime.now().add(const Duration(hours: 2)),
      duration: '45 min',
      type: 'Google Meet',
    ),
    Meeting(
      id: '2',
      title: 'Design Review',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      duration: '1 hour',
      type: 'Zoom',
    ),
  ];
  final _uuid = const Uuid();

  List<Meeting> get meetings => [..._meetings];

  void addMeeting(String title, DateTime dateTime, {String duration = '30 min', String type = 'Zoom'}) {
    final newMeeting = Meeting(
      id: _uuid.v4(),
      title: title,
      dateTime: dateTime,
      duration: duration,
      type: type,
    );
    _meetings.add(newMeeting);
    _meetings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();
  }

  void removeMeeting(String id) {
    _meetings.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}
