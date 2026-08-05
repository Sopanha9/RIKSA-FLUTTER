import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Overview of your learning platform', style: textTheme.bodyMedium),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: _gridCrossCount(context),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _StatCard(
                  title: 'Total Users',
                  value: '—',
                  icon: Icons.people,
                  color: const Color(0xFF1B4332),
                ),
                _StatCard(
                  title: 'Total Lessons',
                  value: '—',
                  icon: Icons.menu_book,
                  color: const Color(0xFF2D6A4F),
                ),
                _StatCard(
                  title: 'Total Exercises',
                  value: '—',
                  icon: Icons.fitness_center,
                  color: const Color(0xFF40916C),
                ),
                _StatCard(
                  title: 'Blog Posts',
                  value: '—',
                  icon: Icons.article,
                  color: const Color(0xFFB5828C),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _gridCrossCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 2;
    return 1;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(value, style: textTheme.headlineLarge?.copyWith(color: color)),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
