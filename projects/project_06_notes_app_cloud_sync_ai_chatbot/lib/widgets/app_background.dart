import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.background, AppColors.backgroundDeep],
              ),
            ),
          ),
        ),
        const Positioned(
          top: -110,
          left: -135,
          child: _BackgroundOrb(size: 270),
        ),
        const Positioned(
          top: 230,
          right: -120,
          child: _BackgroundOrb(size: 205),
        ),
        const Positioned(
          bottom: -180,
          right: -115,
          child: _BackgroundOrb(size: 300),
        ),
        child,
      ],
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  const _BackgroundOrb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FAFF), Color(0xFFD3E0FF)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8DA8E8).withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(8, 10),
          ),
        ],
      ),
    );
  }
}

class AppPanel extends StatelessWidget {
  const AppPanel({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8299C9).withValues(alpha: 0.13),
            blurRadius: 20,
            offset: const Offset(8, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.72),
            blurRadius: 16,
            offset: const Offset(-6, -6),
          ),
        ],
      ),
      child: child,
    );
  }
}
