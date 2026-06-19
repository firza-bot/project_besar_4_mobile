import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../widgets/feature_card.dart';
import '../feature0_project/project_screen.dart';
import '../feature1_api_data/api_data_screen.dart';
import '../feature2_data_entry/data_entry_screen.dart';
import '../feature3_monitor/monitor_screen.dart';
import '../feature4_send_data/send_data_screen.dart';
import '../feature5_maintenance/maintenance_screen.dart';
import '../feature6_environment/environment_screen.dart';
import '../feature7_results/results_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String? _profilePhotoPath;
  String _userName = 'Pengguna';
  int _projectCount = 1;

  // Pipeline Features (Grid 1 to 5, and 8)
  List<_FeatureItem> get _pipelineFeatures => [
        _FeatureItem(
          icon: Icons.folder_rounded,
          title: 'Project',
          subtitle: 'Kelola proyek kolaboratif intelijen. Buat proyek baru dan tentukan visi serta anggotanya.',
          color: const Color(0xFF10B981),
          gridBadge: 'GRID 1',
          statusColor: const Color(0xFF10B981),
          statsInfo: '$_projectCount Project • $_projectCount Aktif',
          screen: const ProjectScreen(),
        ),
        _FeatureItem(
          icon: Icons.cloud_download_rounded,
          title: 'Menerima Data Project',
          subtitle: 'File masuk dari Tim Engineer via API. Review dan validasi data sebelum diproses ke tahap berikutnya.',
          color: const Color(0xFF7C3AED),
          gridBadge: 'GRID 2',
          statusColor: const Color(0xFF10B981),
          statsInfo: '5 Data Masuk • 3 Diterima',
          screen: const ApiDataScreen(),
        ),
        _FeatureItem(
          icon: Icons.edit_note_rounded,
          title: 'Proses Data Entry',
          subtitle: 'Jalankan 8 tahap pipeline AI. Problem Framing, Definisi, Pemrosesan, Perencanaan, Training, Refining, hingga Komunikasi Teknikal & Manajemen.',
          color: const Color(0xFF06B6D4),
          gridBadge: 'GRID 3',
          statusColor: const Color(0xFFF59E0B),
          statsInfo: '8 Tahap Pipeline',
          screen: const DataEntryScreen(),
        ),
        _FeatureItem(
          icon: Icons.analytics_rounded,
          title: 'Data Telah Diproses',
          subtitle: 'Daftar dataset yang telah berhasil melewati pipeline. Klik "Lihat Grafik" pada setiap baris untuk melihat analisis grafik.',
          color: const Color(0xFFF59E0B),
          gridBadge: 'GRID 4',
          statusColor: const Color(0xFFF59E0B),
          statsInfo: 'Akurasi Avg: 94.2%',
          screen: const MonitorScreen(),
        ),
        _FeatureItem(
          icon: Icons.send_rounded,
          title: 'Kirim Implementasi',
          subtitle: 'Kirim hasil akhir pipeline ke Tim Kelompok Implementasi. Data yang dikirim sudah melewati 3 tahap validasi.',
          color: const Color(0xFFEC4899),
          gridBadge: 'GRID 5',
          statusColor: const Color(0xFFF59E0B),
          statsInfo: '2 Model Siap Kirim',
          screen: const SendDataScreen(),
        ),
        _FeatureItem(
          icon: Icons.science_rounded,
          title: 'Pusat Hasil & Pengujian',
          subtitle: 'Daftar model yang diuji dan pusat analisis hasil pengujian model-model AI.',
          color: const Color(0xFF8B5CF6),
          gridBadge: 'GRID 8',
          statusColor: const Color(0xFFF59E0B),
          statsInfo: '4 Model Diuji',
          screen: const ResultsScreen(),
        ),
      ];

  // Independent Features (Grid 6 and 7)
  List<_FeatureItem> get _independentFeatures => [
        _FeatureItem(
          icon: Icons.note_alt_rounded,
          title: 'Maintenance Note',
          subtitle: 'Catat penting, issues, dan hal yang perlu diperhatikan selama operasional pipeline.',
          color: const Color(0xFF3B82F6),
          gridBadge: 'GRID 6',
          statusColor: const Color(0xFFF59E0B),
          statsInfo: '5 Catatan Aktif',
          screen: const MaintenanceScreen(),
        ),
        _FeatureItem(
          icon: Icons.dns_rounded,
          title: 'Environment Dashboard',
          subtitle: 'Monitor kondisi server, status layanan, dan kesehatan sistem secara real-time.',
          color: const Color(0xFF06B6D4),
          gridBadge: 'GRID 7',
          statusColor: const Color(0xFFF59E0B),
          statsInfo: 'Server: Online • DB: Connected',
          screen: const EnvironmentScreen(),
        ),
      ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animController.forward();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load projects count
    int pCount = 1;
    final projectsStr = prefs.getString('saved_projects');
    if (projectsStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(projectsStr);
        pCount = decoded.length;
      } catch (_) {}
    }

    setState(() {
      _profilePhotoPath = prefs.getString('profile_photo_path');
      final name = prefs.getString('profile_name') ?? 'Pengguna';
      // ambil nama depan saja
      _userName = name.split(' ').first;
      _projectCount = pCount;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, $_userName 👋',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kelola pipeline AI Anda',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                        // Refresh data profil setelah kembali dari ProfileScreen
                        _loadDashboardData();
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: _profilePhotoPath != null &&
                                  File(_profilePhotoPath!).existsSync()
                              ? Image.file(
                                  File(_profilePhotoPath!),
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Quick Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.secondary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildStat('Model Aktif', '12'),
                      _divider(),
                      _buildStat('Akurasi Avg', '94.2%'),
                      _divider(),
                      _buildStat('Deployment', '8'),
                    ],
                  ),
                ),
              ),
            ),
            
            // Section 1: GRID PIPELINE
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
                ),
                child: Text(
                  'GRID PIPELINE',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ),
            
            // Pipeline Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.15 : 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final feature = _pipelineFeatures[index];
                    final delay = index * 0.08;
                    return AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        final progress = Curves.easeOut.transform(
                          (_animController.value - delay).clamp(0.0, 1.0),
                        );
                        return Opacity(
                          opacity: progress,
                          child: Transform.translate(
                            offset: Offset(0, 16 * (1 - progress)),
                            child: child,
                          ),
                        );
                      },
                      child: FeatureCard(
                        icon: feature.icon,
                        title: feature.title,
                        subtitle: feature.subtitle,
                        accentColor: feature.color,
                        gridBadge: feature.gridBadge,
                        statusColor: feature.statusColor,
                        statsInfo: feature.statsInfo,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => feature.screen,
                            ),
                          ).then((_) {
                            _loadDashboardData();
                          });
                        },
                      ),
                    );
                  },
                  childCount: _pipelineFeatures.length,
                ),
              ),
            ),
            
            // Section 2: ALAT BANTU INDEPENDEN
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
                ),
                child: Text(
                  'ALAT BANTU INDEPENDEN',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ),

            // Independent Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.15 : 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final feature = _independentFeatures[index];
                    final delay = (index + _pipelineFeatures.length) * 0.08;
                    return AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        final progress = Curves.easeOut.transform(
                          (_animController.value - delay).clamp(0.0, 1.0),
                        );
                        return Opacity(
                          opacity: progress,
                          child: Transform.translate(
                            offset: Offset(0, 16 * (1 - progress)),
                            child: child,
                          ),
                        );
                      },
                      child: FeatureCard(
                        icon: feature.icon,
                        title: feature.title,
                        subtitle: feature.subtitle,
                        accentColor: feature.color,
                        gridBadge: feature.gridBadge,
                        statusColor: feature.statusColor,
                        statsInfo: feature.statsInfo,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => feature.screen,
                            ),
                          ).then((_) {
                            _loadDashboardData();
                          });
                        },
                      ),
                    );
                  },
                  childCount: _independentFeatures.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String gridBadge;
  final Color statusColor;
  final String statsInfo;
  final Widget screen;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.gridBadge,
    required this.statusColor,
    required this.statsInfo,
    required this.screen,
  });
}
