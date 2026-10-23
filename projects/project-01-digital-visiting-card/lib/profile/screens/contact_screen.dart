import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app/app_colors.dart';
import '../models/profile.dart';
import '../state/profile_controller.dart';
import '../utils/external_launcher.dart';
import '../utils/profile_link_utils.dart';
import '../widgets/page_scaffold.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({required this.profileController, super.key});

  final ProfileController profileController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: profileController,
      builder: (context, _) {
        final profile = profileController.profile;
        final links = _contactLinks(context, profile);

        return PageScaffold(
          title: 'Contact',
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const SectionHeading(
                title: 'Let’s connect',
                subtitle: 'Choose the way that works best for you.',
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (links.isEmpty)
                        const Text('Add contact details from Edit profile.')
                      else
                        for (var index = 0; index < links.length; index++) ...[
                          if (index > 0) const Divider(height: 20),
                          links[index],
                        ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _contactLinks(BuildContext context, Profile profile) {
    final links = <Widget>[];
    if (profile.email.trim().isNotEmpty) {
      links.add(
        _ContactTile(
          icon: Icons.mail_outline_rounded,
          title: 'Email',
          subtitle: profile.email,
          onTap: () => launchExternalLink(
            context,
            Uri(scheme: 'mailto', path: profile.email),
          ),
        ),
      );
    }
    if (profile.phone.trim().isNotEmpty) {
      links.add(
        _ContactTile(
          icon: Icons.call_outlined,
          title: 'Phone',
          subtitle: profile.phone,
          onTap: () => launchExternalLink(
            context,
            Uri(scheme: 'tel', path: profile.phone),
          ),
        ),
      );
    }
    final whatsAppUri = whatsappUri(profile.whatsappNumber);
    if (whatsAppUri != null) {
      links.add(
        _ContactTile(
          brandIcon: FontAwesomeIcons.whatsapp,
          title: 'WhatsApp',
          subtitle: profile.whatsappNumber,
          onTap: () => launchExternalLink(context, whatsAppUri),
        ),
      );
    }
    _addSocialLink(
      context,
      links,
      profile.facebookUrl,
      'Facebook',
      FontAwesomeIcons.facebookF,
    );
    _addSocialLink(
      context,
      links,
      profile.linkedinUrl,
      'LinkedIn',
      FontAwesomeIcons.linkedinIn,
    );
    _addSocialLink(
      context,
      links,
      profile.instagramUrl,
      'Instagram',
      FontAwesomeIcons.instagram,
    );
    _addSocialLink(
      context,
      links,
      profile.portfolioUrl,
      'Portfolio',
      FontAwesomeIcons.globe,
    );
    return links;
  }

  void _addSocialLink(
    BuildContext context,
    List<Widget> links,
    String value,
    String label,
    FaIconData icon,
  ) {
    final uri = profileWebUri(value);
    if (uri == null) return;
    links.add(
      _ContactTile(
        brandIcon: icon,
        title: label,
        subtitle: uri.host + uri.path,
        onTap: () => launchExternalLink(context, uri),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
    this.brandIcon,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? icon;
  final FaIconData? brandIcon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.lightPurple,
        foregroundColor: AppColors.purple,
        child: brandIcon != null ? FaIcon(brandIcon, size: 18) : Icon(icon),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.arrow_outward_rounded, size: 18),
      onTap: onTap,
    );
  }
}
