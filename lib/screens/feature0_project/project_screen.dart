import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../widgets/status_badge.dart';
import '../../services/api_service.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final List<Map<String, dynamic>> _defaultProjects = [
    {
      'id': null,
      'name': 'creation',
      'description': 'ini saya berikan job tentang sistem eskpor impor',
      'isPublic': true,
      'createdAt': '16 Jun 2026',
    }
  ];

  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final serverProjects = await ApiService().getProjects();
      setState(() {
        _projects = serverProjects.map((p) {
          return {
            'id': p['id'],
            'name': p['project_name'] ?? '',
            'description': p['description'] ?? '',
            'isPublic': p['visibility'] == 'public',
            'createdAt': 'Status: ${p['status'] ?? 'Active'}',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to local SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final projectsStr = prefs.getString('saved_projects');
      if (projectsStr != null) {
        try {
          final List<dynamic> decoded = jsonDecode(projectsStr);
          setState(() {
            _projects = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
          return;
        } catch (_) {}
      }
      setState(() {
        _projects = List.from(_defaultProjects);
        _isLoading = false;
      });
    }
  }

  Future<void> _addProject(String name, String desc, bool isPublic) async {
    setState(() => _isLoading = true);
    try {
      await ApiService().createProject(name, desc, isPublic);
      await _loadProjects();
      
      // Save local backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_projects', jsonEncode(_projects));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambah project: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteProject(int index) async {
    final project = _projects[index];
    final id = project['id'];

    if (id == null) {
      setState(() {
        _projects.removeAt(index);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_projects', jsonEncode(_projects));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService().deleteProject(id);
      await _loadProjects();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_projects', jsonEncode(_projects));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus project: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _showAddProjectDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isPublic = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: const Text(
            'Tambah Project Baru',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nama Project', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama project',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Deskripsi', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Masukkan deskripsi project',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Akses Publik',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                    Switch(
                      value: isPublic,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setDialogState(() {
                          isPublic = val;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                _addProject(
                  nameController.text.trim(),
                  descController.text.trim(),
                  isPublic,
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _projects.length; // all are active in this mockup

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Stats Card (matching Grid 1 style)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        _buildStat('TOTAL PROJECT', '${_projects.length}'),
                        _buildDivider(),
                        _buildStat('AKTIF', '$activeCount'),
                      ],
                    ),
                  ),
                ),
                
                // Project list
                Expanded(
                  child: _projects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open_rounded, size: 64, color: AppColors.textMuted),
                              const SizedBox(height: 16),
                              const Text(
                                'Belum ada project.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          itemCount: _projects.length,
                          itemBuilder: (context, index) {
                            final project = _projects[index];
                            return _buildProjectCard(project, index);
                          },
                        ),
                ),

                // Tambah Project Button
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _showAddProjectDialog,
                      icon: const Icon(Icons.folder_shared_rounded, color: Colors.white),
                      label: const Text(
                        'Tambah Project',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED), // Purple matching the web button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder_rounded,
                    color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['name'],
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      project['createdAt'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: project['isPublic'] == true ? 'public' : 'private',
                type: project['isPublic'] == true ? BadgeType.success : BadgeType.neutral,
                small: true,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                onPressed: () => _deleteProject(index),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Text(
            project['description'] ?? '',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
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
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
    );
  }
}
