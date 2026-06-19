import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final List<Map<String, dynamic>> _notes = [
    {
      'judul': 'Update library TensorFlow',
      'isi': 'Perlu update TensorFlow ke versi 2.16 untuk kompatibilitas GPU baru.',
      'prioritas': 'tinggi',
      'tanggal': '12 Jun 2026',
      'penulis': 'Ahmad',
    },
    {
      'judul': 'Backup database training',
      'isi': 'Backup database training mingguan telah selesai dilakukan.',
      'prioritas': 'sedang',
      'tanggal': '11 Jun 2026',
      'penulis': 'Budi',
    },
    {
      'judul': 'Optimasi query dataset',
      'isi': 'Query untuk mengambil dataset perlu dioptimasi karena lambat.',
      'prioritas': 'sedang',
      'tanggal': '10 Jun 2026',
      'penulis': 'Citra',
    },
    {
      'judul': 'Perbaikan bug preprocessing',
      'isi': 'Bug pada normalisasi data sudah diperbaiki di pipeline v2.',
      'prioritas': 'rendah',
      'tanggal': '09 Jun 2026',
      'penulis': 'Dewi',
    },
    {
      'judul': 'Monitoring server GPU',
      'isi': 'Server GPU-3 menunjukkan suhu tinggi, perlu pengecekan.',
      'prioritas': 'tinggi',
      'tanggal': '08 Jun 2026',
      'penulis': 'Eko',
    },
  ];

  void _showAddNoteDialog() {
    final judulCtrl = TextEditingController();
    final isiCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Tambah Catatan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(controller: judulCtrl, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(labelText: 'Judul', hintText: 'Masukkan judul')),
            const SizedBox(height: 16),
            TextField(controller: isiCtrl, style: const TextStyle(color: AppColors.textPrimary), maxLines: 3, decoration: const InputDecoration(labelText: 'Isi', hintText: 'Tulis catatan...')),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () {
              if (judulCtrl.text.isNotEmpty) {
                setState(() => _notes.insert(0, {'judul': judulCtrl.text, 'isi': isiCtrl.text, 'prioritas': 'sedang', 'tanggal': '12 Jun 2026', 'penulis': 'Anda'}));
                Navigator.pop(ctx);
              }
            }, child: const Text('Simpan'))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Pemeliharaan'), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context))),
      floatingActionButton: FloatingActionButton(onPressed: _showAddNoteDialog, child: const Icon(Icons.add_rounded)),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final n = _notes[index];
          Color pc; String pl;
          switch (n['prioritas']) { case 'tinggi': pc = AppColors.error; pl = 'Tinggi'; break; case 'sedang': pc = AppColors.warning; pl = 'Sedang'; break; default: pc = AppColors.success; pl = 'Rendah'; }
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border, width: 0.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 4, height: 36, decoration: BoxDecoration(color: pc, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n['judul'], style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('oleh ${n["penulis"]} • ${n["tanggal"]}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: pc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)), child: Text(pl, style: TextStyle(color: pc, fontSize: 10, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 10),
              Text(n['isi'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
            ]),
          );
        },
      ),
    );
  }
}
