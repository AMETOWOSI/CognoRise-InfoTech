import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../state/profile_controller.dart';
import '../widgets/page_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({required this.profileController, super.key});

  final ProfileController profileController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: profileController,
      builder: (context, _) {
        final profile = profileController.profile;
        return PageScaffold(
          title: 'About',
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const SectionHeading(
                title: 'A little about me',
                subtitle: 'The person behind the work.',
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.lightPurple,
                        foregroundColor: AppColors.purple,
                        child: Text(
                          profile.initials,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        profile.fullName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          profile.jobTitle,
                          if (profile.company.trim().isNotEmpty)
                            profile.company,
                        ].where((value) => value.trim().isNotEmpty).join(' · '),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        profile.bio,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.muted,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.purple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Based in',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: AppColors.muted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.location,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
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
}
