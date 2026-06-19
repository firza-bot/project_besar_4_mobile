import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/api_service.dart';
import 'data_entry_screen.dart';

class StepDetailScreen extends StatefulWidget {
  final int submissionId;
  final int nomor;
  final String judul;
  final String deskripsi;
  final StepStatus status;
  final Map<String, dynamic> pipelineData;
  final VoidCallback onSaved;
  final String modality;

  const StepDetailScreen({
    super.key,
    required this.submissionId,
    required this.nomor,
    required this.judul,
    required this.deskripsi,
    required this.status,
    required this.pipelineData,
    required this.onSaved,
    required this.modality,
  });

  @override
  State<StepDetailScreen> createState() => _StepDetailScreenState();
}

class _StepDetailScreenState extends State<StepDetailScreen> {
  final _catatanController = TextEditingController();
  bool _isSaving = false;
  final Map<String, TextEditingController> _controllers = {};
  String _selectedTaskType = 'classification';
  String _selectedModel = 'Random Forest Classifier';

  @override
  void initState() {
    super.initState();
    final stageKey = 'stage_${widget.nomor - 1}';
    final stageData = widget.pipelineData[stageKey] as Map<String, dynamic>? ?? {};
    final mod = widget.modality;

    if (widget.nomor == 1) {
      String defTarget = 'target_status';
      String defInput = 'Data Tabular (CSV). Dimensi: 5000 baris, 12 kolom.';
      String defProcess = 'Pembersihan data (handling missing value, scale numerical features), Train-test split (80/20), cross-validation.';
      String defOutput = 'Prediksi label kelas target secara presisi.';
      String defTask = 'classification';

      if (mod == 'text') {
        defTarget = 'sentiment';
        defInput = 'Data Unstructured Text (TXT). Berisi 2500 baris dokumen teks.';
        defProcess = 'Text preprocessing (lowercasing, tokenization, TF-IDF vectorization), Naive Bayes classification.';
        defOutput = 'Kategorisasi teks dan analisis sentimen (Positif/Negatif).';
        defTask = 'classification';
      } else if (mod == 'image') {
        defTarget = 'label_gambar';
        defInput = 'Data Visual (Image). Dimensi: 3000 file gambar, 3 kelas (Apel, Jeruk, Pisang).';
        defProcess = 'Pre-processing gambar (resize ke 224x224, normalisasi warna), transfer learning menggunakan arsitektur ResNet-50.';
        defOutput = 'Prediksi label kategori objek di dalam gambar.';
        defTask = 'classification';
      }

      _controllers['suggested_target'] = TextEditingController(text: stageData['suggested_target'] ?? defTarget);
      _controllers['ipo_input'] = TextEditingController(text: stageData['ipo']?['input'] ?? defInput);
      _controllers['ipo_process'] = TextEditingController(text: stageData['ipo']?['process'] ?? defProcess);
      _controllers['ipo_output'] = TextEditingController(text: stageData['ipo']?['output'] ?? defOutput);
      
      String rawTaskType = stageData['task_type'] ?? defTask;
      if (rawTaskType == 'text_classification' || rawTaskType == 'image_classification') {
        _selectedTaskType = 'classification';
      } else {
        _selectedTaskType = rawTaskType;
      }
    } else if (widget.nomor == 2) {
      int defQual = 95;
      String defTarget = 'target_status';
      String defCols = 'id int, umur int, pendapatan float, status_pernikahan string, target_status int';

      if (mod == 'text') {
        defQual = 92;
        defTarget = 'sentiment';
        defCols = 'text_content text, sentiment string';
      } else if (mod == 'image') {
        defQual = 97;
        defTarget = 'label_gambar';
        defCols = 'file_path string, label_gambar string';
      }

      _controllers['quality_score'] = TextEditingController(text: (stageData['quality_score'] ?? defQual).toString());
      _controllers['target_column'] = TextEditingController(text: stageData['target_column'] ?? defTarget);
      final cols = stageData['columns_info'] as List<dynamic>?;
      _controllers['columns_info'] = TextEditingController(text: cols != null ? cols.map((c) => "${c['name']} ${c['type']}").join(', ') : defCols);
    } else if (widget.nomor == 3) {
      int defRowsB = 5000;
      int defRowsA = 4850;
      int defColsN = 3;
      int defColsC = 2;
      int defColsD = 1;
      int defTrain = 3880;
      int defTest = 970;

      if (mod == 'text') {
        defRowsB = 2500;
        defRowsA = 2480;
        defColsN = 0;
        defColsC = 1;
        defColsD = 0;
        defTrain = 1984;
        defTest = 496;
      } else if (mod == 'image') {
        defRowsB = 3000;
        defRowsA = 3000;
        defColsN = 0;
        defColsC = 1;
        defColsD = 0;
        defTrain = 2400;
        defTest = 600;
      }

      final cleaning = stageData['cleaning_report'] as Map<String, dynamic>? ?? {};
      _controllers['rows_before'] = TextEditingController(text: (cleaning['rows_before'] ?? defRowsB).toString());
      _controllers['rows_after'] = TextEditingController(text: (cleaning['rows_after'] ?? defRowsA).toString());
      _controllers['cols_num'] = TextEditingController(text: (cleaning['columns_processed_numeric'] ?? defColsN).toString());
      _controllers['cols_cat'] = TextEditingController(text: (cleaning['columns_processed_categorical'] ?? defColsC).toString());
      _controllers['cols_dropped'] = TextEditingController(text: (cleaning['columns_dropped_missing_pct'] ?? defColsD).toString());
      _controllers['cols_card'] = TextEditingController(text: (cleaning['columns_dropped_high_cardinality'] ?? 0).toString());
      _controllers['train_size'] = TextEditingController(text: (stageData['train_size'] ?? defTrain).toString());
      _controllers['test_size'] = TextEditingController(text: (stageData['test_size'] ?? defTest).toString());
    } else if (widget.nomor == 4) {
      String defModel = 'Random Forest Classifier';
      if (mod == 'text') {
        defModel = 'Naive Bayes Classifier';
      } else if (mod == 'image') {
        defModel = 'Convolutional Neural Network (CNN)';
      }
      _selectedModel = stageData['selected_model'] ?? defModel;
    } else if (widget.nomor == 5) {
      double defAcc = 94.5;
      double defPrec = 93.8;
      double defRec = 94.2;
      double defF1 = 94.0;

      if (mod == 'text') {
        defAcc = 89.2;
        defPrec = 88.5;
        defRec = 89.0;
        defF1 = 88.7;
      } else if (mod == 'image') {
        defAcc = 92.4;
        defPrec = 91.8;
        defRec = 92.0;
        defF1 = 91.9;
      }

      final metrics = stageData['metrics'] as Map<String, dynamic>? ?? {};
      _controllers['accuracy'] = TextEditingController(text: (metrics['accuracy'] != null ? (metrics['accuracy'] * 100).toStringAsFixed(1) : defAcc.toStringAsFixed(1)));
      _controllers['precision'] = TextEditingController(text: (metrics['precision'] != null ? (metrics['precision'] * 100).toStringAsFixed(1) : defPrec.toStringAsFixed(1)));
      _controllers['recall'] = TextEditingController(text: (metrics['recall'] != null ? (metrics['recall'] * 100).toStringAsFixed(1) : defRec.toStringAsFixed(1)));
      _controllers['f1'] = TextEditingController(text: (metrics['f1_score'] != null ? (metrics['f1_score'] * 100).toStringAsFixed(1) : defF1.toStringAsFixed(1)));
    } else if (widget.nomor == 6) {
      double defRef = 95.8;
      String defParams = '{"n_estimators": 200, "max_depth": 15, "min_samples_split": 2}';

      if (mod == 'text') {
        defRef = 91.2;
        defParams = '{"alpha": 0.1, "fit_prior": true}';
      } else if (mod == 'image') {
        defRef = 94.6;
        defParams = '{"learning_rate": 0.001, "batch_size": 32, "epochs": 15}';
      }

      final ref = stageData['refined_metrics'] as Map<String, dynamic>? ?? {};
      _controllers['refined_acc'] = TextEditingController(text: (ref['accuracy'] != null ? (ref['accuracy'] * 100).toStringAsFixed(1) : defRef.toStringAsFixed(1)));
      _controllers['best_params'] = TextEditingController(text: stageData['best_params'] != null ? jsonEncode(stageData['best_params']) : defParams);
    } else if (widget.nomor == 7) {
      String defTech = 'Model Random Forest Classifier berhasil dilatih pada data tabular dengan akurasi 95.8%. Model stabil dan siap deploy.';
      if (mod == 'text') {
        defTech = 'Model Naive Bayes berhasil dioptimasi dengan akurasi akhir 91.2% untuk klasifikasi sentimen teks.';
      } else if (mod == 'image') {
        defTech = 'Model Convolutional Neural Network (CNN - ResNet50) berhasil dilatih untuk klasifikasi gambar dengan tingkat akurasi final 94.6%.';
      }
      _controllers['tech_summary'] = TextEditingController(text: stageData['technical_report']?['summary'] ?? defTech);
    } else if (widget.nomor == 8) {
      String defMgmt = 'Sistem berhasil menganalisis data penjualan dan siap memprediksi target dengan tingkat keakuratan 95.8%.';
      String defR1 = 'Terapkan model untuk memfilter prospek pelanggan.';
      String defR2 = 'Lakukan evaluasi berkala setiap bulan.';
      String defR3 = 'Tambahkan lokasi geografis.';

      if (mod == 'text') {
        defMgmt = 'Model klasifikasi teks siap memilah sentimen secara otomatis dengan keakuratan 91.2%.';
        defR1 = 'Gunakan model untuk memantau ulasan negatif.';
        defR2 = 'Tambahkan kamus stop-words bahasa Indonesia.';
        defR3 = 'Lakukan retraining berkala.';
      } else if (mod == 'image') {
        defMgmt = 'Sistem klasifikasi gambar siap memproses dan membedakan jenis buah dengan akurasi 94.6%.';
        defR1 = 'Gunakan model pada kamera pemilah otomatis di lapangan.';
        defR2 = 'Tambahkan variasi data gambar dengan pencahayaan yang berbeda.';
        defR3 = 'Retrain model secara otomatis jika mendeteksi buah jenis baru.';
      }

      _controllers['mgmt_summary'] = TextEditingController(text: stageData['management_report']?['summary'] ?? defMgmt);
      final recs = stageData['management_report']?['recommendations'] as List<dynamic>?;
      _controllers['rec_1'] = TextEditingController(text: recs != null && recs.isNotEmpty ? recs[0] : defR1);
      _controllers['rec_2'] = TextEditingController(text: recs != null && recs.length > 1 ? recs[1] : defR2);
      _controllers['rec_3'] = TextEditingController(text: recs != null && recs.length > 2 ? recs[2] : defR3);
    }

    _catatanController.text = stageData['notes'] ?? '';
  }

  @override
  void dispose() {
    _catatanController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    switch (widget.status) {
      case StepStatus.selesai:
        statusColor = AppColors.success;
        statusLabel = 'Selesai';
        break;
      case StepStatus.berlangsung:
        statusColor = AppColors.warning;
        statusLabel = 'Berlangsung';
        break;
      case StepStatus.belumMulai:
        statusColor = AppColors.textMuted;
        statusLabel = 'Belum Mulai';
        break;
    }

    final bool isEditable = widget.status == StepStatus.berlangsung;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tahap ${widget.nomor}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tahap ${widget.nomor} dari 8',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.judul,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.deskripsi,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Form Fields
            Text(
              'Input Parameter Tahap',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            IgnorePointer(
              ignoring: !isEditable,
              child: Opacity(
                opacity: isEditable ? 1.0 : 0.85,
                child: Column(
                  children: [
                    _buildDynamicFormFields(),
                    const SizedBox(height: 24),
                    CustomTextField(
                      label: 'Catatan Tahap',
                      hint: 'Tambahkan catatan...',
                      controller: _catatanController,
                      maxLines: 3,
                      prefixIcon: Icons.note_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Save button
            if (isEditable)
              CustomButton(
                label: widget.nomor == 8 ? 'Selesaikan Pipeline ✓' : 'Simpan & Lanjut →',
                icon: Icons.save_rounded,
                isLoading: _isSaving,
                onPressed: () async {
                  setState(() => _isSaving = true);
                  try {
                    final stageKey = 'stage_${widget.nomor - 1}';
                    final updatedPipelineData = Map<String, dynamic>.from(widget.pipelineData);
                    
                    Map<String, dynamic> stageData = {};
                    
                    if (widget.nomor == 1) {
                      stageData = {
                        'track': widget.pipelineData['stage_0']?['track'] ?? 'csv',
                        'task_type': _selectedTaskType,
                        'suggested_target': _controllers['suggested_target']!.text,
                        'ipo': {
                          'input': _controllers['ipo_input']!.text,
                          'process': _controllers['ipo_process']!.text,
                          'output': _controllers['ipo_output']!.text,
                        }
                      };
                    } else if (widget.nomor == 2) {
                      stageData = {
                        'quality_score': double.tryParse(_controllers['quality_score']!.text) ?? 95.0,
                        'target_column': _controllers['target_column']!.text,
                        'columns_info': _controllers['columns_info']!.text.split(',').map((s) {
                          final parts = s.trim().split(' ');
                          return {'name': parts[0], 'type': parts.length > 1 ? parts[1] : 'string', 'missing': 0.0};
                        }).toList(),
                      };
                    } else if (widget.nomor == 3) {
                      stageData = {
                        'success': true,
                        'cleaning_report': {
                          'rows_before': int.tryParse(_controllers['rows_before']!.text) ?? 0,
                          'rows_after': int.tryParse(_controllers['rows_after']!.text) ?? 0,
                          'columns_processed_numeric': int.tryParse(_controllers['cols_num']!.text) ?? 0,
                          'columns_processed_categorical': int.tryParse(_controllers['cols_cat']!.text) ?? 0,
                          'columns_dropped_missing_pct': int.tryParse(_controllers['cols_dropped']!.text) ?? 0,
                          'columns_dropped_high_cardinality': int.tryParse(_controllers['cols_card']!.text) ?? 0,
                        },
                        'train_size': int.tryParse(_controllers['train_size']!.text) ?? 0,
                        'test_size': int.tryParse(_controllers['test_size']!.text) ?? 0,
                      };
                    } else if (widget.nomor == 4) {
                      stageData = {
                        'selected_model': _selectedModel,
                        'recommendations': [
                          {
                            'model_name': _selectedModel,
                            'score': 0.95,
                            'metric': 'accuracy',
                            'description': 'Model pilihan manual user.'
                          }
                        ]
                      };
                    } else if (widget.nomor == 5) {
                      stageData = {
                        'success': true,
                        'model_name': widget.pipelineData['stage_3']?['selected_model'] ?? 'Random Forest',
                        'metrics': {
                          'accuracy': (double.tryParse(_controllers['accuracy']!.text) ?? 95.0) / 100.0,
                          'precision': (double.tryParse(_controllers['precision']!.text) ?? 94.0) / 100.0,
                          'recall': (double.tryParse(_controllers['recall']!.text) ?? 94.0) / 100.0,
                          'f1_score': (double.tryParse(_controllers['f1']!.text) ?? 94.0) / 100.0,
                        }
                      };
                    } else if (widget.nomor == 6) {
                      final double refAcc = (double.tryParse(_controllers['refined_acc']!.text) ?? 96.0) / 100.0;
                      final double baseAcc = widget.pipelineData['stage_4']?['metrics']?['accuracy'] ?? 0.94;
                      Map<String, dynamic> params = {};
                      try {
                        params = jsonDecode(_controllers['best_params']!.text);
                      } catch (_) {}
                      stageData = {
                        'success': true,
                        'baseline_metrics': {'accuracy': baseAcc},
                        'refined_metrics': {'accuracy': refAcc},
                        'metric_name': 'accuracy',
                        'performance_improvement_pct': (refAcc - baseAcc) * 100.0,
                        'best_params': params,
                      };
                    } else if (widget.nomor == 7) {
                      stageData = {
                        'success': true,
                        'technical_report': {
                          'pipeline_summary': {
                            'selected_model': widget.pipelineData['stage_3']?['selected_model'] ?? 'Random Forest',
                            'track': widget.pipelineData['stage_0']?['track'] ?? 'csv',
                            'task_type': widget.pipelineData['stage_0']?['task_type'] ?? 'classification',
                          },
                          'performance_comparison': {
                            'refined_metrics': {
                              'accuracy': widget.pipelineData['stage_5']?['refined_metrics']?['accuracy'] ?? 0.96
                            }
                          },
                          'summary': _controllers['tech_summary']!.text,
                        }
                      };
                    } else {
                      stageData = {
                        'success': true,
                        'management_report': {
                          'summary': _controllers['mgmt_summary']!.text,
                          'recommendations': [
                            _controllers['rec_1']!.text.trim(),
                            _controllers['rec_2']!.text.trim(),
                            _controllers['rec_3']!.text.trim(),
                          ].where((r) => r.isNotEmpty).toList(),
                        }
                      };
                    }

                    stageData['notes'] = _catatanController.text;
                    updatedPipelineData[stageKey] = stageData;

                    await ApiService().updateSubmissionStage(
                      submissionId: widget.submissionId,
                      stage: widget.nomor - 1,
                      pipelineData: updatedPipelineData,
                    );

                    if (!mounted) return;
                    setState(() => _isSaving = false);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tahap berhasil disimpan ke server!'),
                        backgroundColor: AppColors.success,
                      ),
                    );

                    widget.onSaved();
                    Navigator.pop(context);
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menyimpan: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ),
          if (!isEditable)
            CustomButton(
              label: 'Tutup Detail',
              icon: Icons.close_rounded,
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
    ),
  );
}

  Widget _buildDynamicFormFields() {
    if (widget.nomor == 1) {
      final isClustering = _selectedTaskType == 'clustering';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tipe Tugas AI', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTaskType,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: Colors.white),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'classification', child: Text('Classification')),
                  DropdownMenuItem(value: 'regression', child: Text('Regression')),
                  DropdownMenuItem(value: 'clustering', child: Text('Clustering')),
                ],
                onChanged: widget.status == StepStatus.berlangsung ? (val) {
                  if (val != null) {
                    setState(() {
                      _selectedTaskType = val;
                      if (val == 'clustering') {
                        _controllers['suggested_target']!.text = 'N/A (Clustering)';
                      } else if (_controllers['suggested_target']!.text == 'N/A (Clustering)') {
                        _controllers['suggested_target']!.text = '';
                      }
                    });
                  }
                } : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!isClustering) ...[
            CustomTextField(
              label: 'Target Prediksi',
              hint: 'Ketik kolom target...',
              controller: _controllers['suggested_target']!,
              prefixIcon: Icons.insights_rounded,
            ),
            const SizedBox(height: 16),
          ],
          CustomTextField(
            label: 'Bagan Input',
            hint: 'Ketik input...',
            controller: _controllers['ipo_input']!,
            prefixIcon: Icons.input_rounded,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Bagan Proses',
            hint: 'Ketik proses...',
            controller: _controllers['ipo_process']!,
            prefixIcon: Icons.settings_rounded,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Bagan Output',
            hint: 'Ketik output...',
            controller: _controllers['ipo_output']!,
            prefixIcon: Icons.output_rounded,
          ),
        ],
      );
    } else if (widget.nomor == 2) {
      return Column(
        children: [
          CustomTextField(
            label: 'Kualitas Data (%)',
            hint: '0-100',
            keyboardType: TextInputType.number,
            controller: _controllers['quality_score']!,
            prefixIcon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Nama Kolom Target',
            hint: 'Ketik target...',
            controller: _controllers['target_column']!,
            prefixIcon: Icons.label_important_outline_rounded,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Daftar Kolom (nama tipe, pisahkan koma)',
            hint: 'id int, nama string',
            controller: _controllers['columns_info']!,
            prefixIcon: Icons.list_alt_rounded,
          ),
        ],
      );
    } else if (widget.nomor == 3) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Baris Sebelum',
                  keyboardType: TextInputType.number,
                  controller: _controllers['rows_before']!,
                  prefixIcon: Icons.view_headline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Baris Sesudah',
                  keyboardType: TextInputType.number,
                  controller: _controllers['rows_after']!,
                  prefixIcon: Icons.table_rows_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Kolom Numerik',
                  keyboardType: TextInputType.number,
                  controller: _controllers['cols_num']!,
                  prefixIcon: Icons.numbers_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Kolom Kategori',
                  keyboardType: TextInputType.number,
                  controller: _controllers['cols_cat']!,
                  prefixIcon: Icons.category_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Missing Dibuang',
                  keyboardType: TextInputType.number,
                  controller: _controllers['cols_dropped']!,
                  prefixIcon: Icons.delete_sweep_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Kardinalitas Dibuang',
                  keyboardType: TextInputType.number,
                  controller: _controllers['cols_card']!,
                  prefixIcon: Icons.cancel_presentation_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Data Train Size',
                  keyboardType: TextInputType.number,
                  controller: _controllers['train_size']!,
                  prefixIcon: Icons.psychology_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Data Test Size',
                  keyboardType: TextInputType.number,
                  controller: _controllers['test_size']!,
                  prefixIcon: Icons.assignment_turned_in_rounded,
                ),
              ),
            ],
          ),
        ],
      );
    } else if (widget.nomor == 4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Algoritma Model Terpilih', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedModel,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: Colors.white),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Random Forest Classifier', child: Text('Random Forest Classifier')),
                  DropdownMenuItem(value: 'Logistic Regression', child: Text('Logistic Regression')),
                  DropdownMenuItem(value: 'Naive Bayes Classifier', child: Text('Naive Bayes Classifier')),
                  DropdownMenuItem(value: 'Linear SVM', child: Text('Linear SVM')),
                  DropdownMenuItem(value: 'Gradient Boosting Regressor', child: Text('Gradient Boosting Regressor')),
                  DropdownMenuItem(value: 'Ridge Regression', child: Text('Ridge Regression')),
                  DropdownMenuItem(value: 'Convolutional Neural Network (CNN)', child: Text('Convolutional Neural Network (CNN)')),
                ],
                onChanged: widget.status == StepStatus.berlangsung ? (val) {
                  if (val != null) setState(() => _selectedModel = val);
                } : null,
              ),
            ),
          ),
        ],
      );
    } else if (widget.nomor == 5) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Accuracy / R2 (%)',
                  keyboardType: TextInputType.number,
                  controller: _controllers['accuracy']!,
                  prefixIcon: Icons.score_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Precision (%)',
                  keyboardType: TextInputType.number,
                  controller: _controllers['precision']!,
                  prefixIcon: Icons.star_border_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Recall (%)',
                  keyboardType: TextInputType.number,
                  controller: _controllers['recall']!,
                  prefixIcon: Icons.history_edu_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'F1-Score (%)',
                  keyboardType: TextInputType.number,
                  controller: _controllers['f1']!,
                  prefixIcon: Icons.flash_on_rounded,
                ),
              ),
            ],
          ),
        ],
      );
    } else if (widget.nomor == 6) {
      return Column(
        children: [
          CustomTextField(
            label: 'Akurasi Setelah Tuning (%)',
            keyboardType: TextInputType.number,
            controller: _controllers['refined_acc']!,
            prefixIcon: Icons.offline_bolt_rounded,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Parameter Optimal (JSON Format)',
            hint: '{"n_estimators": 200}',
            controller: _controllers['best_params']!,
            prefixIcon: Icons.settings_ethernet_rounded,
          ),
        ],
      );
    } else if (widget.nomor == 7) {
      return CustomTextField(
        label: 'Ringkasan Laporan Teknis',
        hint: 'Tuliskan laporan...',
        maxLines: 5,
        controller: _controllers['tech_summary']!,
        prefixIcon: Icons.menu_book_rounded,
      );
    } else {
      return Column(
        children: [
          CustomTextField(
            label: 'Narasi Bisnis Manajemen',
            hint: 'Tuliskan ringkasan bisnis...',
            maxLines: 3,
            controller: _controllers['mgmt_summary']!,
            prefixIcon: Icons.business_center_rounded,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Rekomendasi Bisnis 1',
            controller: _controllers['rec_1']!,
            prefixIcon: Icons.arrow_right_rounded,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Rekomendasi Bisnis 2',
            controller: _controllers['rec_2']!,
            prefixIcon: Icons.arrow_right_rounded,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Rekomendasi Bisnis 3',
            controller: _controllers['rec_3']!,
            prefixIcon: Icons.arrow_right_rounded,
          ),
        ],
      );
    }
  }
}
