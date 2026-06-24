import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/constants.dart';
import '../../widgets/status_badge.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ApiDataScreen extends StatefulWidget {
  const ApiDataScreen({super.key});

  @override
  State<ApiDataScreen> createState() => _ApiDataScreenState();
}

class _ApiDataScreenState extends State<ApiDataScreen> {
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _kontakController = TextEditingController();
  String _urgensi = 'Medium Priority';
  List<Map<String, dynamic>> _apiData = [];
  bool _isLoading = true;
  int? _selectedSubmissionId;
  bool _isActionLoading = false;
  String? _selectedFileName;
  String? _selectedFilePath;
  String? _selectedFileTitle;
  String? _selectedFileTeam;

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _kontakController.dispose();
    super.dispose();
  }

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
      setState(() {
        _apiData = subs.map((s) {
          return {
            'id': 'SUB-${s['id']}',
            'dbId': s['id'] as int,
            'nama': s['title'] ?? 'Tanpa Judul',
            'sumber': '${s['sender_name']} (${s['sender_team']})',
            'ukuran': '${s['file_size_mb'] ?? 0} MB',
            'tanggal': s['time_relative'] ?? 'Baru saja',
            'status': s['status'] ?? 'pending',
            'format': (s['data_type'] as String? ?? 'unknown').toUpperCase(),
            'file_name': s['file_name'] ?? '-',
            'file_path': s['file_path'] ?? '',
            'file_url': s['file_url'] ?? '',
          };
        }).toList();
        
        // Reset selection if the selected submission is no longer pending or is missing
        if (_selectedSubmissionId != null) {
          final stillPending = _apiData.any((s) => s['dbId'] == _selectedSubmissionId && s['status'] == 'pending');
          if (!stillPending) {
            _selectedSubmissionId = null;
          }
        }
        
        _isLoading = false;
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

  Future<void> _refresh() async {
    await _loadSubmissions();
  }

  int get _totalMasukCount => _apiData.where((s) => s['status'] == 'pending').length;
  int get _pendingCount => _apiData.where((s) => s['status'] == 'pending').length;
  int get _processedCount => _apiData.where((s) => s['status'] == 'in_progress' || s['status'] == 'completed' || s['status'] == 'sent').length;

  Future<void> _pickRealFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls', 'txt', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final name = result.files.single.name;
        setState(() {
          _selectedFilePath = path;
          _selectedFileName = name;
          _selectedFileTitle = name.split('.').first;
          _selectedFileTeam = 'Mobile Upload';
          
          if (_judulController.text.trim().isEmpty) {
            _judulController.text = _selectedFileTitle!;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File terpilih: $name'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih file: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _submitManualForm() async {
    if (_selectedFilePath == null) return;
    
    final String judul = _judulController.text.trim();
    if (judul.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan isi Judul terlebih dahulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      final String kontak = _kontakController.text.trim();
      final res = await ApiService().uploadRealFile(
        filePath: _selectedFilePath!,
        title: judul,
        senderName: kontak.isNotEmpty ? kontak : 'Mobile User',
        senderTeam: _selectedFileTeam ?? 'Mobile Upload',
      );

      final int newId = res['id'] as int;
      
      // Auto-approve new submission to Grid 3
      await ApiService().approveSubmission(newId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Form dan $_selectedFileName berhasil dikirim ke Grid 3!'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      setState(() {
        _selectedFilePath = null;
        _selectedFileName = null;
        _selectedFileTitle = null;
        _selectedFileTeam = null;
        _judulController.clear();
        _deskripsiController.clear();
        _kontakController.clear();
        _urgensi = 'Medium Priority';
        _isActionLoading = false;
      });
      await _loadSubmissions();
    } catch (e) {
      setState(() => _isActionLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim form: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleKirimKeProses() {
    if (_selectedSubmissionId != null) {
      _sendToProcess();
    } else if (_selectedFileName != null) {
      _submitManualForm();
    }
  }

  Future<void> _sendToProcess() async {
    if (_selectedSubmissionId == null) return;
    setState(() => _isActionLoading = true);
    try {
      await ApiService().approveSubmission(_selectedSubmissionId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Data berhasil dikirim ke Grid 3!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      setState(() {
        _selectedSubmissionId = null;
        _isActionLoading = false;
      });
      await _loadSubmissions();
    } catch (e) {
      setState(() => _isActionLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim ke proses: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penerimaan Data API'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildStatsRow(),
                  _buildManualForm(),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, thickness: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'RECENT SUBMISSIONS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_apiData.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          'Tidak ada data masuk dari server.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._apiData.map((data) => _buildDataCard(data)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsRow() {
    final total = _totalMasukCount;
    final pending = _pendingCount;
    final processed = _processedCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Total Masuk', '$total', Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard('Pending', '$pending', const Color(0xFFFBBF24)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard('Diproses', '$processed', const Color(0xFF6EE7B7)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color valColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildManualForm() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INPUT DATA MANUAL',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Judul',
            hint: 'Contoh: Data Penjualan Q3 2026',
            controller: _judulController,
            prefixIcon: Icons.title_rounded,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Deskripsi',
            hint: 'Jelaskan kebutuhan data, kolom yang diperlukan, dan wilayah terkait...',
            controller: _deskripsiController,
            prefixIcon: Icons.description_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Kontak',
            hint: 'email@tim.com',
            controller: _kontakController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Urgensi',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _urgensi,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.warning_amber_rounded, color: AppColors.textMuted, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                ),
                items: const [
                  DropdownMenuItem(value: 'High Priority', child: Text('High Priority')),
                  DropdownMenuItem(value: 'Medium Priority', child: Text('Medium Priority')),
                  DropdownMenuItem(value: 'Low Priority', child: Text('Low Priority')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _urgensi = val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'File untuk Diproses',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: _selectedFileName != null ? AppColors.primary : AppColors.border,
                    width: _selectedFileName != null ? 1.0 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_rounded,
                      color: _selectedFileName != null ? AppColors.primary : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedFileName ?? 'Belum ada file yang diunggah',
                        style: TextStyle(
                          color: _selectedFileName != null ? Colors.white : AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_selectedFileName != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedFileName = null;
                            _selectedFilePath = null;
                            _selectedFileTitle = null;
                            _selectedFileTeam = null;
                          });
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Unggah File',
                  isOutlined: true,
                  icon: Icons.folder_open_rounded,
                  onPressed: _pickRealFile,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Kirim ke Proses → ${(_selectedSubmissionId != null || _selectedFileName != null) ? 1 : 0}',
                  isLoading: _isActionLoading,
                  onPressed: (_selectedSubmissionId != null || _selectedFileName != null) ? _handleKirimKeProses : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(Map<String, dynamic> data) {
    BadgeType badgeType;
    String statusLabel;
    switch (data['status']) {
      case 'diterima':
      case 'completed':
      case 'sent':
        badgeType = BadgeType.success;
        statusLabel = 'Diterima';
        break;
      case 'menunggu':
      case 'pending':
      case 'in_progress':
        badgeType = BadgeType.warning;
        statusLabel = 'Menunggu';
        break;
      case 'gagal':
      case 'rejected':
        badgeType = BadgeType.error;
        statusLabel = 'Gagal';
        break;
      default:
        badgeType = BadgeType.neutral;
        statusLabel = 'Tidak Diketahui';
    }

    final bool isSelected = _selectedSubmissionId == data['dbId'];
    final bool isPending = data['status'] == 'pending';

    return GestureDetector(
      onTap: isPending
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedSubmissionId = null;
                } else {
                  _selectedSubmissionId = data['dbId'];
                }
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cloud_download_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nama'],
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['sumber'],
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(label: statusLabel, type: badgeType, small: true),
              ],
            ),
            if (data['file_path'] != null && data['file_path'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.folder_open_rounded, color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Penyimpanan: ${data['file_path']}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip(Icons.tag, data['id']),
                const SizedBox(width: 16),
                _infoChip(Icons.description_outlined, data['format']),
                const SizedBox(width: 16),
                _infoChip(Icons.storage_rounded, data['ukuran']),
                const Spacer(),
                Text(
                  data['tanggal'],
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
