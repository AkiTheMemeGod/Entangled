import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/theme_provider.dart';
import '../../providers/font_size_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_variants.dart';
import '../../widgets/animated_gradient_bg.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final fontSizeSettings = ref.watch(fontSizeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedGradientBg(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            _buildSectionHeader(context, 'Appearance', fontSizeSettings.multiplier),
            const SizedBox(height: 12),
            _buildSettingTile(
              context,
              icon: Icons.dark_mode_rounded,
              title: 'Obsidian Theme',
              subtitle: 'Toggle dark/light resonance',
              fontSizeMultiplier: fontSizeSettings.multiplier,
              trailing: Switch(
                value: settings.mode == ThemeMode.dark,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) {
                  ref.read(themeSettingsProvider.notifier).toggleTheme();
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildThemeGallery(context, ref, settings),
            const SizedBox(height: 32),
            _buildFontSizeSection(context, ref, fontSizeSettings),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Notifications', fontSizeSettings.multiplier),
            const SizedBox(height: 12),
            _buildSettingTile(
              context,
              icon: Icons.notifications_active_rounded,
              title: 'Push Notifications',
              subtitle: 'Real-time sync alerts',
              fontSizeMultiplier: fontSizeSettings.multiplier,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildSettingTile(
              context,
              icon: Icons.vibration_rounded,
              title: 'Vaptic Feedback',
              subtitle: 'Quantum tactile response',
              fontSizeMultiplier: fontSizeSettings.multiplier,
              onTap: () {},
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Privacy & Security', fontSizeSettings.multiplier),
            const SizedBox(height: 12),
            _buildSettingTile(
              context,
              icon: Icons.security_rounded,
              title: 'Encryption Protocol',
              subtitle: 'Manage E2EE keys',
              fontSizeMultiplier: fontSizeSettings.multiplier,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildSettingTile(
              context,
              icon: Icons.phonelink_lock_rounded,
              title: 'Self-Destruct Timer',
              subtitle: 'Auto-erase message history',
              fontSizeMultiplier: fontSizeSettings.multiplier,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, double fontSizeMultiplier) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12 * fontSizeMultiplier,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildThemeGallery(
    BuildContext context,
    WidgetRef ref,
    ThemeSettings settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12),
          child: Text(
            'COLOR RESONANCE',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AppThemeVariant.values.length,
            itemBuilder: (context, index) {
              final variant = AppThemeVariant.values[index];
              final palette = ThemePalette.getPalette(variant);
              final isSelected = settings.variant == variant;

              return GestureDetector(
                onTap: () => ref
                    .read(themeSettingsProvider.notifier)
                    .setThemeVariant(variant),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? palette.primary
                          : AppColors.glassBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    gradient: LinearGradient(
                      colors: [palette.primary, palette.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (isSelected)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Text(
                          variant.name.substring(0, 1).toUpperCase() +
                              variant.name.substring(1),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeSection(
    BuildContext context,
    WidgetRef ref,
    FontSizeSettings fontSizeSettings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12),
          child: Text(
            'TEXT SIZE',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12 * fontSizeSettings.multiplier,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(30),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Font Size',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * fontSizeSettings.multiplier,
                    ),
                  ),
                  Text(
                    '${(fontSizeSettings.multiplier * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * fontSizeSettings.multiplier,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: fontSizeSettings.multiplier,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                label: '${(fontSizeSettings.multiplier * 100).toStringAsFixed(0)}%',
                onChanged: (value) async {
                  await ref.read(fontSizeProvider.notifier).setFontSizeMultiplier(value);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Preview: The quick brown fox jumps over the lazy dog',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14 * fontSizeSettings.multiplier,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required double fontSizeMultiplier,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(30),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16 * fontSizeMultiplier,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12 * fontSizeMultiplier,
          ),
        ),
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withAlpha(153),
              size: 20,
            ),
      ),
    );
  }
}
