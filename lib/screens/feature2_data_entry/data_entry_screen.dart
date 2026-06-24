import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import 'step_detail_screen.dart';

class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  List<Map<String, dynamic>> _submissions = [];
  Map<String, dynamic>? _selectedSubmission;
  bool _isLoading = true;

  final List<_StepData> _steps = [
    _StepData(
      nomor: 1,
      judul: 'Problem Framing',
      deskripsi: 'Mendefinisikan masalah, input, proses, dan output yang diharapkan',
      status: StepStatus.belumMulai,
      icon: Icons.crop_free_rounded,
    ),
    _StepData(
      nomor: 2,
      judul: 'Dataset Definition',
      deskripsi: 'Menentukan struktur, sumber, dan format dataset yang akan digunakan',
      status: StepStatus.belumMulai,
      icon: Icons.dataset_rounded,
    ),
    _StepData(
      nomor: 3,
      judul: 'Processing',
      deskripsi: 'Membersihkan, transformasi, dan normalisasi data mentah',
      status: StepStatus.belumMulai,
      icon: Icons.settings_suggest_rounded,
    ),
    _StepData(
      nomor: 4,
      judul: 'Model Planning',
      deskripsi: 'Memilih arsitektur model dan parameter awal',
      status: StepStatus.belumMulai,
      icon: Icons.architecture_rounded,
    ),
    _StepData(
      nomor: 5,
      judul: 'Engine Execution',
      deskripsi: 'Melatih model, evaluasi performa, dan eksekusi engine',
      status: StepStatus.belumMulai,
      icon: Icons.model_training_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getSubmissions();
      final List<dynamic> subs = res['submissions'] ?? [];
      final submissionsList = subs.map((e) => Map<String, dynamic>.from(e)).toList();
      
      setState(() {
        _submissions = submissionsList;
        _isLoading = false;
        
        // Refresh selected submission data if already selected
        if (_selectedSubmission != null) {
          final updated = submissionsList.firstWhere(
            (s) => s['id'] == _selectedSubmission!['id'],
            orElse: () => _selectedSubmission!,
          );
          _selectedSubmission = updated;
          _calculateSteps();
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data dari server: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteSubmission(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Hapus Data', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Apakah Anda yakin ingin menghapus data ini beserta seluruh prosesnya secara permanen?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService().deleteSubmission(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Data beserta seluruh proses berhasil dihapus.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      setState(() {
        _selectedSubmission = null;
      });
      await _loadSubmissions();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _calculateSteps() {
    if (_selectedSubmission == null) return;
    final int currentStage = _selectedSubmission!['current_stage'] ?? 0;
    
    for (int i = 0; i < _steps.length; i++) {
      StepStatus status;
      if (i < currentStage) {
        status = StepStatus.selesai;
      } else if (i == currentStage) {
        status = StepStatus.berlangsung;
      } else {
        status = StepStatus.belumMulai;
      }
      _steps[i] = _StepData(
        nomor: _steps[i].nomor,
        judul: _steps[i].judul,
        deskripsi: _steps[i].deskripsi,
        status: status,
        icon: _steps[i].icon,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_selectedSubmission == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pilih Dataset'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _submissions.isEmpty
            ? const Center(
                child: Text(
                  'Tidak ada data masuk untuk diproses.\nKirim data terlebih dahulu dari web/API.',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _submissions.length,
                itemBuilder: (context, index) {
                  final sub = _submissions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.insights_rounded, color: AppColors.primary),
                      ),
                      title: Text(
                        sub['title'] ?? 'Tanpa Judul',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Pengirim: ${sub['sender_name']} • Stage: ${sub['current_stage']}\nProgres: ${sub['progress']}% • status: ${sub['status']}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 16),
                      onTap: () {
                        setState(() {
                          _selectedSubmission = sub;
                          _calculateSteps();
                        });
                      },
                    ),
                  );
                },
              ),
      );
    }

    final String modality = _selectedSubmission!['detected_data_type'] ?? _selectedSubmission!['data_type'] ?? 'unknown';
    final bool hasModality = modality == 'tabular' || modality == 'text';

    if (!hasModality) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_selectedSubmission!['title']),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              setState(() {
                _selectedSubmission = null;
              });
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Choose Your Modality',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Select the engine that best suits your data type to begin building your custom AI pipeline.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildModalityOptionCard(
                      icon: Icons.table_chart_rounded,
                      title: 'Structured',
                      desc: 'Data Terstruktur / Tabel & Angka',
                      color: AppColors.success,
                      onTap: () => _updateModality('tabular'),
                    ),
                    const SizedBox(height: 16),
                    _buildModalityOptionCard(
                      icon: Icons.text_snippet_rounded,
                      title: 'Unstructured',
                      desc: 'Teks & Dokumen / Bahasa',
                      color: AppColors.primary,
                      onTap: () => _updateModality('text'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final selesai = _steps.where((s) => s.status == StepStatus.selesai).length;
    final total = _steps.length;
    final progress = selesai / total;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedSubmission!['title']),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            setState(() {
              _selectedSubmission = null;
            });
          },
        ),
      ),
      body: Column(
        children: [
          // Selected Sub header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mengolah: ${_selectedSubmission!['title'] ?? _selectedSubmission!['sender_name']}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedSubmission = null;
                    });
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                  child: const Text('Ganti', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                  onPressed: () => _deleteSubmission(_selectedSubmission!['id']),
                  tooltip: 'Hapus Data',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
          ),
          
          // Progress bar
          Container(
            margin: const EdgeInsets.all(AppSpacing.md),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progres Keseluruhan',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$selesai / $total tahap',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                  ),
                ),
              ],
            ),
          ),
          // Steps list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                final isLast = index == _steps.length - 1;
                return _buildStepItem(step, isLast);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(_StepData step, bool isLast) {
    final String modality = _selectedSubmission!['detected_data_type'] ?? _selectedSubmission!['data_type'] ?? 'unknown';
    Color statusColor;
    IconData statusIcon;
    switch (step.status) {
      case StepStatus.selesai:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case StepStatus.berlangsung:
        statusColor = AppColors.warning;
        statusIcon = Icons.play_circle_rounded;
        break;
      case StepStatus.belumMulai:
        statusColor = AppColors.textMuted;
        statusIcon = Icons.radio_button_unchecked_rounded;
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StepDetailScreen(
              submissionId: _selectedSubmission!['id'],
              nomor: step.nomor,
              judul: step.judul,
              deskripsi: step.deskripsi,
              status: step.status,
              pipelineData: _selectedSubmission!['pipeline_data'] ?? {},
              onSaved: () {
                _loadSubmissions();
              },
              modality: modality,
            ),
          ),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Icon(statusIcon, color: statusColor, size: 24),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: step.status == StepStatus.selesai
                            ? AppColors.success.withValues(alpha: 0.4)
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: step.status == StepStatus.berlangsung
                      ? AppColors.warning.withValues(alpha: 0.08)
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: step.status == StepStatus.berlangsung
                        ? AppColors.warning.withValues(alpha: 0.3)
                        : AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(step.icon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tahap ${step.nomor}',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.judul,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.deskripsi,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalityOptionCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _updateModality(String type) async {
    if (_selectedSubmission != null) {
      final fileName = (_selectedSubmission!['file_name'] ?? _selectedSubmission!['title'] ?? '').toString().toLowerCase();
      if (type == 'tabular' && (fileName.endsWith('.json') || fileName.endsWith('.txt') || fileName.endsWith('.log') || fileName.endsWith('.md'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Format file JSON/TXT (${_selectedSubmission!['file_name'] ?? _selectedSubmission!['title']}) tidak cocok dengan tipe Structured (Tabel/Angka).'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (type == 'text' && (fileName.endsWith('.csv') || fileName.endsWith('.xlsx') || fileName.endsWith('.xls'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Format file CSV/Excel (${_selectedSubmission!['file_name'] ?? _selectedSubmission!['title']}) tidak cocok dengan tipe Unstructured (Teks/Bahasa).'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await ApiService().updateSubmissionDataType(
        submissionId: _selectedSubmission!['id'],
        dataType: type,
      );
      await _loadSubmissions();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui tipe data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

enum StepStatus { selesai, berlangsung, belumMulai }

class _StepData {
  final int nomor;
  final String judul;
  final String deskripsi;
  final StepStatus status;
  final IconData icon;

  _StepData({
    required this.nomor,
    required this.judul,
    required this.deskripsi,
    required this.status,
    required this.icon,
  });
}
