class Event {
  final String id;
  final String title;
  final String? description;
  final String eventType; // personal, work, social, health, other
  final String visibility; // private, public
  final DateTime startTime;
  final DateTime endTime;
  final bool allDay;
  final String? location;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.eventType,
    required this.visibility,
    required this.startTime,
    required this.endTime,
    this.allDay = false,
    this.location,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Event from API response JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      eventType: json['eventType'] ?? 'personal',
      visibility: json['visibility'] ?? 'private',
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'].toString())
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'].toString())
          : DateTime.now().add(const Duration(hours: 1)),
      allDay: json['allDay'] ?? false,
      location: json['location'],
      color: json['color'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  /// Convert Event to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'eventType': eventType,
      'visibility': visibility,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'allDay': allDay,
      'location': location,
      'color': color,
    };
  }

  /// Copy with for easy updates
  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? eventType,
    String? visibility,
    DateTime? startTime,
    DateTime? endTime,
    bool? allDay,
    String? location,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      visibility: visibility ?? this.visibility,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Event(id: $id, title: $title, type: $eventType)';
}
