import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/app_colors.dart';
import '../models/profile.dart';
import '../state/profile_controller.dart';
import '../utils/external_launcher.dart';
import '../utils/profile_link_utils.dart';
import '../utils/vcard_builder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.profileController, super.key});

  final ProfileController profileController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: profileController,
      builder: (context, _) {
        final profile = profileController.profile;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _HomeHeader(
                      isLoading: profileController.isLoading,
                      onEdit: () => context.push('/edit'),
                    ),
                    if (profileController.loadError != null) ...[
                      const SizedBox(height: 16),
                      _LoadError(message: profileController.loadError!),
                    ],
                    const SizedBox(height: 20),
                    _DigitalCard(
                      profile: profile,
                      onPortfolioTap: profile.portfolioUrl.trim().isEmpty
                          ? null
                          : () {
                              final uri = profileWebUri(profile.portfolioUrl);
                              if (uri != null) {
                                launchExternalLink(context, uri);
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    _QrCard(profile: profile),
                    const SizedBox(height: 24),
                    Text(
                      'EXPLORE',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _NavigationButton(
                          label: 'About',
                          icon: Icons.person_outline_rounded,
                          onPressed: () => context.push('/about'),
                        ),
                        _NavigationButton(
                          label: 'Skills',
                          icon: Icons.auto_awesome_outlined,
                          onPressed: () => context.push('/skills'),
                        ),
                        _NavigationButton(
                          label: 'Contact',
                          icon: Icons.mail_outline_rounded,
                          onPressed: () => context.push('/contact'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'A little introduction, wherever you go.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.isLoading, required this.onEdit});

  final bool isLoading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.lightPurple,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.contact_page_rounded,
            color: AppColors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DIGITAL CARD',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Make a lasting connection',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Edit profile',
          onPressed: isLoading ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    );
  }
}

class _DigitalCard extends StatelessWidget {
  const _DigitalCard({required this.profile, required this.onPortfolioTap});

  final Profile profile;
  final VoidCallback? onPortfolioTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepPurple, AppColors.purple],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -68,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 28,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.deepPurple,
                      child: Text(
                        profile.initials,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            profile.jobTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.yellow,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (profile.company.trim().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              profile.company,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (profile.bio.trim().isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(
                    profile.bio,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.55,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (profile.phone.trim().isNotEmpty)
                      _CardContactChip(
                        icon: Icons.call_outlined,
                        label: profile.phone,
                        onPressed: () => launchExternalLink(
                          context,
                          Uri(scheme: 'tel', path: profile.phone),
                        ),
                      ),
                    if (profile.email.trim().isNotEmpty)
                      _CardContactChip(
                        icon: Icons.mail_outline_rounded,
                        label: profile.email,
                        onPressed: () => launchExternalLink(
                          context,
                          Uri(scheme: 'mailto', path: profile.email),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _SocialLinks(profile: profile),
                if (onPortfolioTap != null) ...[
                  const SizedBox(height: 18),
                  Center(
                    child: FilledButton.icon(
                      onPressed: onPortfolioTap,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('View portfolio'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: AppColors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContactChip extends StatelessWidget {
  const _CardContactChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _SocialLinks extends StatelessWidget {
  const _SocialLinks({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final whatsAppUri = whatsappUri(profile.whatsappNumber);
    final links = <Widget>[
      if (whatsAppUri != null)
        _SocialButton(
          label: 'WhatsApp',
          icon: FontAwesomeIcons.whatsapp,
          uri: whatsAppUri,
        ),
      if (profileWebUri(profile.facebookUrl) case final uri?)
        _SocialButton(
          label: 'Facebook',
          icon: FontAwesomeIcons.facebookF,
          uri: uri,
        ),
      if (profileWebUri(profile.linkedinUrl) case final uri?)
        _SocialButton(
          label: 'LinkedIn',
          icon: FontAwesomeIcons.linkedinIn,
          uri: uri,
        ),
      if (profileWebUri(profile.instagramUrl) case final uri?)
        _SocialButton(
          label: 'Instagram',
          icon: FontAwesomeIcons.instagram,
          uri: uri,
        ),
    ];

    if (links.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: links
          .map(
            (link) =>
                Padding(padding: const EdgeInsets.only(bottom: 2), child: link),
          )
          .toList(growable: false),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.uri,
  });

  final String label;
  final FaIconData icon;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: () => launchExternalLink(context, uri),
      icon: FaIcon(icon, size: 20),
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final qrCode = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAE5F0)),
          ),
          child: QrImageView(
            data: buildVCard(profile),
            version: QrVersions.auto,
            size: 148,
            padding: const EdgeInsets.all(12),
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            semanticsLabel: 'QR code containing ${profile.fullName} contact',
            errorStateBuilder: (context, _) => SizedBox(
              width: 148,
              height: 148,
              child: Center(
                child: Text(
                  'The contact QR code could not be created.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
        );
        final description = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.qr_code_2_rounded,
              color: AppColors.purple,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'Save my contact',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Scan the code to add my details to your contacts.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
          ],
        );
        final content = constraints.maxWidth < 380
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [qrCode, const SizedBox(height: 16), description],
              )
            : Row(
                children: [
                  qrCode,
                  const SizedBox(width: 18),
                  Expanded(child: description),
                ],
              );

        return Card(
          child: Padding(padding: const EdgeInsets.all(20), child: content),
        );
      },
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.purple,
        side: const BorderSide(color: Color(0xFFE3DCEB)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.deepPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }
}
