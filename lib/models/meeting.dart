class Meeting {
  final String id;
  final String title;
  final DateTime dateTime;
  final String duration;
  final String location;
  final String type; // 'Zoom', 'Google Meet', 'In-person', etc.

  Meeting({
    required this.id,
    required this.title,
    required this.dateTime,
    this.duration = '30 min',
    this.location = 'Online',
    this.type = 'Zoom',
  });
}
