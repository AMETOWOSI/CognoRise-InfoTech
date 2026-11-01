import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../state/profile_controller.dart';
import '../widgets/page_scaffold.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({required this.profileController, super.key});

  final ProfileController profileController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: profileController,
      builder: (context, _) {
        final skills = profileController.profile.skills;
        return PageScaffold(
          title: 'Skills',
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const SectionHeading(
                title: 'What I bring',
                subtitle: 'Tools and strengths I enjoy working with.',
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.lightPurple,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Skills & strengths',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A practical mix of technical skills and an eagerness to keep learning.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (skills.isEmpty)
                        const Text('Add your skills from Edit profile.')
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (var index = 0; index < skills.length; index++)
                              Chip(
                                avatar: Icon(
                                  Icons.check_rounded,
                                  size: 17,
                                  color: index.isEven
                                      ? AppColors.purple
                                      : AppColors.deepPurple,
                                ),
                                label: Text(skills[index]),
                                backgroundColor: index.isEven
                                    ? AppColors.lightPurple
                                    : const Color(0xFFFFF7DF),
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                              ),
                          ],
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
