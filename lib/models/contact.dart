class Contact {
  final int? id;
  final String name;
  final String phoneNumber;
  final String designation;
  final String organization;
  final String expertise;
  final String location;
  final String email;
  final String note;
  final String profileImagePath;

  Contact({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.designation = '',
    this.organization = '',
    this.expertise = '',
    this.location = '',
    this.email = '',
    this.note = '',
    this.profileImagePath = '',
  });

  // Convert Contact object to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'designation': designation,
      'organization': organization,
      'expertise': expertise,
      'location': location,
      'email': email,
      'note': note,
      'profileImagePath': profileImagePath,
    };
  }

  // Create Contact object from Map (SQLite query result)
  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as int?,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      designation: map['designation'] as String? ?? '',
      organization: map['organization'] as String? ?? '',
      expertise: map['expertise'] as String? ?? '',
      location: map['location'] as String? ?? '',
      email: map['email'] as String? ?? '',
      note: map['note'] as String? ?? '',
      profileImagePath: map['profileImagePath'] as String? ?? '',
    );
  }

  // Helper method to get initials for avatar display
  String get initials {
    final names = name.trim().split(' ');
    if (names.isEmpty) return '';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  // Helper methods for backward compatibility with existing UI code
  String? get title => designation.isNotEmpty ? designation : null;
  String? get company => organization.isNotEmpty ? organization : null;
  String? get avatar => profileImagePath.isNotEmpty ? profileImagePath : null;
  String? get imageUrl => profileImagePath.isNotEmpty ? profileImagePath : null;

  // CopyWith method for easy updates
  Contact copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    String? designation,
    String? organization,
    String? expertise,
    String? location,
    String? email,
    String? note,
    String? profileImagePath,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      designation: designation ?? this.designation,
      organization: organization ?? this.organization,
      expertise: expertise ?? this.expertise,
      location: location ?? this.location,
      email: email ?? this.email,
      note: note ?? this.note,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }

  @override
  String toString() {
    return 'Contact(id: $id, name: $name, phoneNumber: $phoneNumber, designation: $designation, organization: $organization)';
  }
}
