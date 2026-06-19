import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/status_badge.dart';
import '../../services/api_service.dart';

class ApiDataScreen extends StatefulWidget {
  const ApiDataScreen({super.key});

  @override
  State<ApiDataScreen> createState() => _ApiDataScreenState();
}

class _ApiDataScreenState extends State<ApiDataScreen> {
  List<Map<String, dynamic>> _apiData = [];
  bool _isLoading = true;

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
            'nama': s['title'] ?? 'Tanpa Judul',
            'sumber': '${s['sender_name']} (${s['sender_team']})',
            'ukuran': '${s['file_size_mb'] ?? 0} MB',
            'tanggal': s['time_relative'] ?? 'Baru saja',
            'status': s['status'] ?? 'pending',
            'format': (s['data_type'] as String? ?? 'unknown').toUpperCase(),
          };
        }).toList();
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
              child: _apiData.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada data masuk dari server.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _apiData.length,
                      itemBuilder: (context, index) {
                        final data = _apiData[index];
                        return _buildDataCard(data);
                      },
                    ),
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
