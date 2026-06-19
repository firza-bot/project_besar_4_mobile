import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/custom_button.dart';

class SendDataScreen extends StatefulWidget {
  const SendDataScreen({super.key});

  @override
  State<SendDataScreen> createState() => _SendDataScreenState();
}

class _SendDataScreenState extends State<SendDataScreen> {
  final List<Map<String, dynamic>> _models = [
    {
      'nama': 'Model Prediksi Penjualan v2.1',
      'akurasi': '94.2%',
      'ukuran': '45.2 MB',
      'versi': 'v2.1.0',
      'status': 'siap',
      'terakhirDilatih': '12 Jun 2026',
    },
    {
      'nama': 'Model Klasifikasi Sentimen v1.8',
      'akurasi': '91.5%',
      'ukuran': '32.8 MB',
      'versi': 'v1.8.3',
      'status': 'siap',
      'terakhirDilatih': '10 Jun 2026',
    },
    {
      'nama': 'Model Deteksi Anomali v3.0',
      'akurasi': '89.7%',
      'ukuran': '67.1 MB',
      'versi': 'v3.0.0',
      'status': 'terkirim',
      'terakhirDilatih': '08 Jun 2026',
    },
    {
      'nama': 'Model Rekomendasi Produk v1.2',
      'akurasi': '87.3%',
      'ukuran': '28.5 MB',
      'versi': 'v1.2.1',
      'status': 'gagal',
      'terakhirDilatih': '05 Jun 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kirim ke Implementasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _models.length,
        itemBuilder: (context, index) {
          final model = _models[index];
          return _buildModelCard(model);
        },
      ),
    );
  }

  Widget _buildModelCard(Map<String, dynamic> model) {
    BadgeType badgeType;
    String statusLabel;
    bool canSend = false;

    switch (model['status']) {
      case 'siap':
        badgeType = BadgeType.info;
        statusLabel = 'Siap Kirim';
        canSend = true;
        break;
      case 'terkirim':
        badgeType = BadgeType.success;
        statusLabel = 'Terkirim';
        break;
      case 'gagal':
        badgeType = BadgeType.error;
        statusLabel = 'Gagal';
        canSend = true;
        break;
      default:
        badgeType = BadgeType.neutral;
        statusLabel = '-';
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
                  color: const Color(0xFFE879F9).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Color(0xFFE879F9), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model['nama'],
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${model['versi']} • ${model['ukuran']}',
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
          Row(
            children: [
              _infoItem('Akurasi', model['akurasi']),
              const SizedBox(width: 24),
              _infoItem('Terakhir Dilatih', model['terakhirDilatih']),
            ],
          ),
          if (canSend) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: CustomButton(
                label: model['status'] == 'gagal' ? 'Kirim Ulang' : 'Kirim ke Implementasi',
                icon: Icons.send_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${model["nama"]} sedang dikirim...'),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
