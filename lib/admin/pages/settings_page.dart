import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text('Configure platform settings', style: textTheme.bodyMedium),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('General', style: textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _SettingsTile(
                      icon: Icons.language,
                      title: 'Platform Language',
                      subtitle: 'English',
                      onTap: () {},
                    ),
                    const Divider(height: 32),
                    Text('Appearance', style: textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _SettingsTile(
                      icon: Icons.palette_outlined,
                      title: 'Theme',
                      subtitle: 'Light',
                      onTap: () {},
                    ),
                    const Divider(height: 32),
                    Text('Other', style: textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _SettingsTile(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'Riksa Admin v1.0.0',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
