import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/profile_controller.dart';
import '../utils/profile_link_utils.dart';
import '../widgets/page_scaffold.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({required this.profileController, super.key});

  final ProfileController profileController;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  bool _fieldsInitialized = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profileController.profile;
    _fields = {
      'fullName': TextEditingController(text: profile.fullName),
      'jobTitle': TextEditingController(text: profile.jobTitle),
      'company': TextEditingController(text: profile.company),
      'bio': TextEditingController(text: profile.bio),
      'email': TextEditingController(text: profile.email),
      'phone': TextEditingController(text: profile.phone),
      'location': TextEditingController(text: profile.location),
      'portfolioUrl': TextEditingController(text: profile.portfolioUrl),
      'whatsappNumber': TextEditingController(text: profile.whatsappNumber),
      'facebookUrl': TextEditingController(text: profile.facebookUrl),
      'linkedinUrl': TextEditingController(text: profile.linkedinUrl),
      'instagramUrl': TextEditingController(text: profile.instagramUrl),
      'skills': TextEditingController(text: profile.skills.join(', ')),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Edit profile',
      child: AnimatedBuilder(
        animation: widget.profileController,
        builder: (context, _) {
          if (widget.profileController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_fieldsInitialized) _syncFieldsFromProfile();

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeading(
                    title: 'Your details',
                    subtitle: 'Keep your contact card up to date.',
                  ),
                  const SizedBox(height: 20),
                  _field(
                    'fullName',
                    'Full name',
                    icon: Icons.person_outline_rounded,
                    required: true,
                  ),
                  _field('jobTitle', 'Job title', icon: Icons.work_outline),
                  _field(
                    'company',
                    'Company or organization',
                    icon: Icons.business_outlined,
                  ),
                  _field(
                    'bio',
                    'Short introduction',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  _field(
                    'email',
                    'Email address',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validateEmail: true,
                  ),
                  _field(
                    'phone',
                    'Phone number',
                    icon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  _field(
                    'location',
                    'Location',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 8),
                  const SectionHeading(
                    title: 'Links',
                    subtitle: 'These fields are optional.',
                  ),
                  const SizedBox(height: 14),
                  _field(
                    'portfolioUrl',
                    'Portfolio URL',
                    icon: Icons.language_rounded,
                    keyboardType: TextInputType.url,
                    validateUrl: true,
                  ),
                  _field(
                    'whatsappNumber',
                    'WhatsApp number (international format)',
                    icon: Icons.chat_outlined,
                    keyboardType: TextInputType.phone,
                    validatePhone: true,
                  ),
                  _field(
                    'facebookUrl',
                    'Facebook profile URL',
                    icon: Icons.public_rounded,
                    keyboardType: TextInputType.url,
                    validateUrl: true,
                  ),
                  _field(
                    'linkedinUrl',
                    'LinkedIn profile URL',
                    icon: Icons.work_outline_rounded,
                    keyboardType: TextInputType.url,
                    validateUrl: true,
                  ),
                  _field(
                    'instagramUrl',
                    'Instagram profile URL',
                    icon: Icons.camera_alt_outlined,
                    keyboardType: TextInputType.url,
                    validateUrl: true,
                  ),
                  _field(
                    'skills',
                    'Skills, separated by commas',
                    icon: Icons.auto_awesome_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: widget.profileController.isSaving ? null : _save,
                    icon: widget.profileController.isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      widget.profileController.isSaving
                          ? 'Saving...'
                          : 'Save profile',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _syncFieldsFromProfile() {
    final profile = widget.profileController.profile;
    _fields['fullName']!.text = profile.fullName;
    _fields['jobTitle']!.text = profile.jobTitle;
    _fields['company']!.text = profile.company;
    _fields['bio']!.text = profile.bio;
    _fields['email']!.text = profile.email;
    _fields['phone']!.text = profile.phone;
    _fields['location']!.text = profile.location;
    _fields['portfolioUrl']!.text = profile.portfolioUrl;
    _fields['whatsappNumber']!.text = profile.whatsappNumber;
    _fields['facebookUrl']!.text = profile.facebookUrl;
    _fields['linkedinUrl']!.text = profile.linkedinUrl;
    _fields['instagramUrl']!.text = profile.instagramUrl;
    _fields['skills']!.text = profile.skills.join(', ');
    _fieldsInitialized = true;
  }

  Widget _field(
    String key,
    String label, {
    required IconData icon,
    bool required = false,
    bool validateEmail = false,
    bool validateUrl = false,
    bool validatePhone = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _fields[key],
        keyboardType: keyboardType,
        maxLines: maxLines,
        textCapitalization: validateEmail || validateUrl
            ? TextCapitalization.none
            : TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return 'This field is required.';
          if (validateEmail && text.isNotEmpty && !_isValidEmail(text)) {
            return 'Enter a valid email address.';
          }
          if (validateUrl && text.isNotEmpty && profileWebUri(text) == null) {
            return 'Enter a valid URL beginning with https://.';
          }
          if (validatePhone &&
              text.isNotEmpty &&
              !_isValidInternationalPhone(text)) {
            return 'Enter a phone number with its country code.';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final current = widget.profileController.profile;
    final updatedProfile = current.copyWith(
      fullName: _value('fullName'),
      jobTitle: _value('jobTitle'),
      company: _value('company'),
      bio: _value('bio'),
      email: _value('email'),
      phone: _value('phone'),
      location: _value('location'),
      portfolioUrl: _value('portfolioUrl'),
      whatsappNumber: _value('whatsappNumber'),
      facebookUrl: _value('facebookUrl'),
      linkedinUrl: _value('linkedinUrl'),
      instagramUrl: _value('instagramUrl'),
      skills: _value('skills')
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toList(growable: false),
    );

    try {
      await widget.profileController.save(updatedProfile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved on this device.')),
      );
      context.pop();
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your profile: $error')),
      );
    }
  }

  String _value(String key) => _fields[key]!.text.trim();

  bool _isValidEmail(String value) {
    return value.length <= 254 &&
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  bool _isValidInternationalPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return value.trim().startsWith('+') &&
        digits.length >= 8 &&
        digits.length <= 15;
  }
}
