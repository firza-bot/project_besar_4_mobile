import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'system_monitor_screen.dart';

class EnvironmentScreen extends StatelessWidget {
  const EnvironmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Lingkungan'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.monitor_heart_rounded),
            tooltip: 'System Monitor',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SystemMonitorScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _buildEnvCard(context, 'Development', 'dev', AppColors.info, true, {'CPU': 0.35, 'RAM': 0.52, 'GPU': 0.28, 'Disk': 0.41}),
            const SizedBox(height: 12),
            _buildEnvCard(context, 'Staging', 'staging', AppColors.warning, true, {'CPU': 0.62, 'RAM': 0.71, 'GPU': 0.55, 'Disk': 0.63}),
            const SizedBox(height: 12),
            _buildEnvCard(context, 'Production', 'prod', AppColors.success, true, {'CPU': 0.78, 'RAM': 0.85, 'GPU': 0.72, 'Disk': 0.68}),
            const SizedBox(height: 24),
            // Recent Activity
            Align(alignment: Alignment.centerLeft, child: Text('Aktivitas Terbaru', style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 12),
            _buildActivity('Deployment model v2.1 ke production', '2 jam lalu', Icons.rocket_launch_rounded, AppColors.success),
            _buildActivity('Restart server staging', '5 jam lalu', Icons.refresh_rounded, AppColors.warning),
            _buildActivity('Update konfigurasi development', '1 hari lalu', Icons.settings_rounded, AppColors.info),
            _buildActivity('Backup database production', '2 hari lalu', Icons.backup_rounded, AppColors.secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvCard(BuildContext context, String name, String tag, Color color, bool online, Map<String, double> resources) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: online ? AppColors.success : AppColors.error, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)),
            child: Text(tag, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          Text(online ? 'Online' : 'Offline', style: TextStyle(color: online ? AppColors.success : AppColors.error, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 16),
        ...resources.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            SizedBox(width: 40, child: Text(e.key, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
            const SizedBox(width: 8),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(value: e.value, minHeight: 6, backgroundColor: AppColors.surface, valueColor: AlwaysStoppedAnimation(e.value > 0.8 ? AppColors.error : e.value > 0.6 ? AppColors.warning : AppColors.success)),
            )),
            const SizedBox(width: 8),
            SizedBox(width: 36, child: Text('${(e.value * 100).toInt()}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), textAlign: TextAlign.right)),
          ]),
        )),
      ]),
    );
  }

  Widget _buildActivity(String text, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          Text(time, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ])),
      ]),
    );
  }
}
