import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/status_badge.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final models = [
      {'nama': 'Prediksi Penjualan v2.1', 'akurasi': 94.2, 'presisi': 92.8, 'recall': 95.1, 'f1': 93.9, 'status': 'lulus', 'tanggal': '12 Jun 2026'},
      {'nama': 'Klasifikasi Sentimen v1.8', 'akurasi': 91.5, 'presisi': 90.3, 'recall': 92.7, 'f1': 91.5, 'status': 'lulus', 'tanggal': '10 Jun 2026'},
      {'nama': 'Deteksi Anomali v3.0', 'akurasi': 89.7, 'presisi': 88.2, 'recall': 91.3, 'f1': 89.7, 'status': 'lulus', 'tanggal': '08 Jun 2026'},
      {'nama': 'Rekomendasi Produk v1.2', 'akurasi': 72.3, 'presisi': 70.1, 'recall': 74.5, 'f1': 72.3, 'status': 'gagal', 'tanggal': '05 Jun 2026'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Hasil & Pengujian'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: models.length,
        itemBuilder: (context, index) {
          final m = models[index];
          final passed = m['status'] == 'lulus';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border, width: 0.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFA78BFA).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.science_rounded, color: Color(0xFFA78BFA), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['nama'] as String, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(m['tanggal'] as String, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ])),
                StatusBadge(label: passed ? 'Lulus' : 'Gagal', type: passed ? BadgeType.success : BadgeType.error, small: true),
              ]),
              const SizedBox(height: 16),
              // Metrics Grid
              Row(children: [
                _metric('Akurasi', '${m['akurasi']}%', AppColors.success),
                _metric('Presisi', '${m['presisi']}%', AppColors.info),
                _metric('Recall', '${m['recall']}%', AppColors.secondary),
                _metric('F1 Score', '${m['f1']}%', AppColors.warning),
              ]),
              const SizedBox(height: 12),
              // Visual bar
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: (m['akurasi'] as double) / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation(passed ? AppColors.success : AppColors.error),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Expanded(
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ]),
    );
  }
}
