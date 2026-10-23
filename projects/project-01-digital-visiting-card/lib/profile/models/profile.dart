class Profile {
  const Profile({
    required this.fullName,
    required this.jobTitle,
    required this.company,
    required this.bio,
    required this.email,
    required this.phone,
    required this.location,
    required this.portfolioUrl,
    required this.whatsappNumber,
    required this.facebookUrl,
    required this.linkedinUrl,
    required this.instagramUrl,
    required this.skills,
  });

  static const sample = Profile(
    fullName: 'Alex Morgan',
    jobTitle: 'Flutter Developer',
    company: 'Independent Developer',
    bio:
        'I build thoughtful mobile experiences with clean code and a focus on the people who use them.',
    email: 'alex.morgan@example.com',
    phone: '+1 555 010 2040',
    location: 'London, United Kingdom',
    portfolioUrl: 'https://example.com',
    whatsappNumber: '+15550102040',
    facebookUrl: '',
    linkedinUrl: 'https://www.linkedin.com/in/alex-morgan',
    instagramUrl: '',
    skills: [
      'Flutter',
      'Dart',
      'Mobile UI',
      'REST APIs',
      'Git',
      'Problem solving',
    ],
  );

  final String fullName;
  final String jobTitle;
  final String company;
  final String bio;
  final String email;
  final String phone;
  final String location;
  final String portfolioUrl;
  final String whatsappNumber;
  final String facebookUrl;
  final String linkedinUrl;
  final String instagramUrl;
  final List<String> skills;

  Profile copyWith({
    String? fullName,
    String? jobTitle,
    String? company,
    String? bio,
    String? email,
    String? phone,
    String? location,
    String? portfolioUrl,
    String? whatsappNumber,
    String? facebookUrl,
    String? linkedinUrl,
    String? instagramUrl,
    List<String>? skills,
  }) {
    return Profile(
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      skills: skills ?? this.skills,
    );
  }

  Map<String, Object?> toJson() => {
    'fullName': fullName,
    'jobTitle': jobTitle,
    'company': company,
    'bio': bio,
    'email': email,
    'phone': phone,
    'location': location,
    'portfolioUrl': portfolioUrl,
    'whatsappNumber': whatsappNumber,
    'facebookUrl': facebookUrl,
    'linkedinUrl': linkedinUrl,
    'instagramUrl': instagramUrl,
    'skills': skills,
  };

  factory Profile.fromJson(Map<String, Object?> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String) {
        throw FormatException('The stored profile field "$key" is invalid.');
      }
      return value;
    }

    String optionalString(String key) {
      final value = json[key];
      if (value == null) return '';
      if (value is! String) {
        throw FormatException('The stored profile field "$key" is invalid.');
      }
      return value;
    }

    final rawSkills = json['skills'];
    final List<String> skills;
    if (rawSkills == null) {
      skills = const [];
    } else if (rawSkills is List) {
      if (rawSkills.any((item) => item is! String)) {
        throw const FormatException('The stored profile skills are invalid.');
      }
      skills = List<String>.unmodifiable(rawSkills.whereType<String>());
    } else {
      throw const FormatException('The stored profile skills are invalid.');
    }

    final fullName = requiredString('fullName').trim();
    if (fullName.isEmpty) {
      throw const FormatException('The stored profile name is required.');
    }

    return Profile(
      fullName: fullName,
      jobTitle: optionalString('jobTitle'),
      company: optionalString('company'),
      bio: optionalString('bio'),
      email: optionalString('email'),
      phone: optionalString('phone'),
      location: optionalString('location'),
      portfolioUrl: optionalString('portfolioUrl'),
      whatsappNumber: optionalString('whatsappNumber'),
      facebookUrl: optionalString('facebookUrl'),
      linkedinUrl: optionalString('linkedinUrl'),
      instagramUrl: optionalString('instagramUrl'),
      skills: skills,
    );
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final firstInitial = parts.first.substring(0, 1);
    if (parts.length == 1) return firstInitial.toUpperCase();
    return '$firstInitial${parts.last.substring(0, 1)}'.toUpperCase();
  }
}
