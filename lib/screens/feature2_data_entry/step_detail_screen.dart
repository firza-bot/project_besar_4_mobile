import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/api_service.dart';

class StepDetailScreen extends StatefulWidget {
  final int submissionId;
  final int nomor; // Legacy parameter, we will display step dynamically
  final String judul;
  final String deskripsi;
  final dynamic status; // Legacy parameter
  final Map<String, dynamic> pipelineData; // Legacy parameter
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
  int _currentStep = 1;
  List<int> _completedSteps = [];
  Map<String, dynamic> _wizardState = {};
  String? _datasetId;
  List<String> _columns = [];
  List<Map<String, dynamic>> _previewHead = [];
  List<Map<String, dynamic>> _previewTail = [];
  int _rowCount = 0;
  int _duplicateCount = 0;
  List<Map<String, dynamic>> _processedRows = [];
  List<String> _processedColumns = [];
  Map<String, dynamic> _processStats = {};
  String? _jobId;
  String _trainingStatus = 'idle';
  double _trainingProgress = 0.0;
  Map<String, dynamic> _trainingResult = {};

  bool _isLoading = true;
  bool _isActionLoading = false;
  Timer? _pollingTimer;

  // Controllers for text fields
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initWizard();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  TextEditingController _getController(String key, String initialValue) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialValue);
      _controllers[key]!.addListener(() {
        if (key.startsWith('fd_')) {
          final colName = key.substring(3);
          if (_wizardState['featureDescriptions'] == null) {
            _wizardState['featureDescriptions'] = <String, dynamic>{};
          }
          _wizardState['featureDescriptions'][colName] = _controllers[key]!.text;
        } else {
          _wizardState[key] = _controllers[key]!.text;
        }
      });
    }
    return _controllers[key]!;
  }

  Future<void> _initWizard() async {
    setState(() => _isLoading = true);
    try {
      // 1. Try to load draft from API
      try {
        final draft = await ApiService().loadDraft(widget.submissionId.toString());
        setState(() {
          _currentStep = draft['currentStep'] ?? 1;
          _completedSteps = List<int>.from(draft['completedSteps'] ?? []);
          _wizardState = Map<String, dynamic>.from(draft['wizardState'] ?? {});
          _datasetId = draft['datasetId'];
          _columns = List<String>.from(draft['columns'] ?? []);
          _previewHead = List<Map<String, dynamic>>.from((draft['previewHead'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
          _previewTail = List<Map<String, dynamic>>.from((draft['previewTail'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
          _rowCount = draft['rowCount'] ?? 0;
          _duplicateCount = draft['duplicateCount'] ?? 0;
          _processedRows = List<Map<String, dynamic>>.from((draft['processedRows'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
          _processedColumns = List<String>.from(draft['processedColumns'] ?? []);
          _processStats = Map<String, dynamic>.from(draft['processStats'] ?? {});
          _jobId = draft['jobId'];
          _trainingStatus = draft['trainingStatus'] ?? 'idle';
          _trainingProgress = (draft['trainingProgress'] ?? 0).toDouble();
          _trainingResult = Map<String, dynamic>.from(draft['trainingResult'] ?? {});
          
          _isLoading = false;
        });

        // Initialize controllers
        _wizardState.forEach((key, val) {
          if (key != 'featureDescriptions' && key != 'hyperparams') {
            _getController(key, val?.toString() ?? '');
          }
        });
        
        final fd = _wizardState['featureDescriptions'] as Map?;
        fd?.forEach((key, val) {
          _getController('fd_$key', val?.toString() ?? '');
        });

        // If training was running, resume polling
        if (_trainingStatus == 'running' || _trainingStatus == 'pending') {
          if (_jobId != null) _startPolling(_jobId!);
        }
        return;
      } catch (e) {
        print("Draft not found, initializing from submission: $e");
      }

      // 2. Load submission dataset to initialize
      final subData = await ApiService().loadSubmissionDataset(widget.submissionId);
      
      // Initialize wizardState map
      final initialWizardState = {
        'problemType': widget.modality == 'text' ? 'classification' : (subData['problem_type'] ?? 'classification'),
        'systemName': subData['system_name'] ?? '',
        'inputDescription': subData['description'] ?? '',
        'primaryOutcome': subData['target_column'] ?? 'target',
        'datasetName': subData['system_name'] ?? 'Uploaded Dataset',
        'requiredFeatures': subData['columns'] != null ? (subData['columns'] as List).join(', ') : '',
        'targetColumn': subData['target_column'] ?? 'target',
        'jumlahData': subData['row_count'] ?? 2000,
        'datasetSource': 'api',
        'missingValueStrategy': 'Drop blank rows',
        'duplicateStrategy': 'Drop Duplicates',
        'categoricalEncoding': true,
        'applyStandardization': true,
        'algorithm': widget.modality == 'text' ? 'MLP' : 'Logistic Regression',
        'hyperparams': {
          'C': 1,
          'max_iter': 100,
          'penalty': 'l2',
          'solver': 'lbfgs',
          'max_depth': '',
          'min_samples_split': 2,
          'criterion': 'gini',
          'n_estimators': 100,
          'learning_rate': 0.3,
        },
        'featureDescriptions': {},
      };

      final columns = List<String>.from((subData['columns'] as List?)?.map((e) => e.toString()) ?? []);
      final previewHead = List<Map<String, dynamic>>.from((subData['preview_head'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
      final previewTail = List<Map<String, dynamic>>.from((subData['preview_tail'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
      
      final featureDescriptions = <String, String>{};
      if (previewHead.isNotEmpty) {
        final firstRow = previewHead.first;
        for (var col in columns) {
          if (!col.startsWith('_')) {
            featureDescriptions[col] = firstRow[col]?.toString() ?? '';
          }
        }
      }
      initialWizardState['featureDescriptions'] = featureDescriptions;

      setState(() {
        _currentStep = 1;
        _completedSteps = [];
        _wizardState = initialWizardState;
        _datasetId = subData['dataset_id'];
        _columns = columns;
        _previewHead = previewHead;
        _previewTail = previewTail;
        _rowCount = subData['row_count'] ?? 0;
        _duplicateCount = subData['duplicate_count'] ?? 0;
        _processedRows = [];
        _processedColumns = [];
        _processStats = {};
        _jobId = null;
        _trainingStatus = 'idle';
        _trainingProgress = 0.0;
        _trainingResult = {};
        
        _isLoading = false;
      });

      // Initialize text controllers
      initialWizardState.forEach((key, val) {
        if (key != 'featureDescriptions' && key != 'hyperparams') {
          _getController(key, val?.toString() ?? '');
        }
      });
      featureDescriptions.forEach((key, val) {
        _getController('fd_$key', val);
      });

      // Save initial draft to backend
      await _saveDraftBackend();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal inisialisasi wizard: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveDraftBackend() async {
    try {
      await ApiService().saveDraft(widget.submissionId.toString(), {
        'currentStep': _currentStep,
        'completedSteps': _completedSteps,
        'wizardState': _wizardState,
        'datasetId': _datasetId,
        'columns': _columns,
        'previewHead': _previewHead,
        'previewTail': _previewTail,
        'rowCount': _rowCount,
        'duplicateCount': _duplicateCount,
        'processedRows': _processedRows,
        'processedColumns': _processedColumns,
        'processStats': _processStats,
        'jobId': _jobId,
        'trainingStatus': _trainingStatus,
        'trainingProgress': _trainingProgress,
        'trainingResult': _trainingResult,
      });
    } catch (e) {
      print('Gagal menyimpan draf di server: $e');
    }
  }

  void _markStepDone(int step) {
    if (!_completedSteps.contains(step)) {
      setState(() {
        _completedSteps.add(step);
      });
    }
  }

  bool _isStepValid() {
    final s = _wizardState;
    if (_currentStep == 1) {
      final problemType = s['problemType']?.toString() ?? '';
      final systemName = s['systemName']?.toString() ?? '';
      final inputDescription = s['inputDescription']?.toString() ?? '';
      final primaryOutcome = s['primaryOutcome']?.toString() ?? '';
      
      return problemType.isNotEmpty &&
          systemName.trim().isNotEmpty &&
          inputDescription.trim().isNotEmpty &&
          (problemType == 'clustering' || primaryOutcome.trim().isNotEmpty);
    } else if (_currentStep == 2) {
      final datasetName = s['datasetName']?.toString() ?? '';
      final requiredFeatures = s['requiredFeatures']?.toString() ?? '';
      final target = s['problemType'] == 'clustering' ? true : (s['targetColumn']?.toString().trim().isNotEmpty ?? false);
      final jumlahData = int.tryParse(s['jumlahData']?.toString() ?? '0') ?? 0;
      
      if (s['datasetSource'] == 'manual') {
        return datasetName.trim().isNotEmpty &&
            requiredFeatures.trim().isNotEmpty &&
            target &&
            jumlahData > 0 &&
            _datasetId != null;
      }
      return datasetName.trim().isNotEmpty &&
          requiredFeatures.trim().isNotEmpty &&
          target &&
          jumlahData > 0;
    } else if (_currentStep == 3) {
      return _datasetId != null && _processedRows.isNotEmpty;
    } else if (_currentStep == 4) {
      return s['algorithm']?.toString().isNotEmpty ?? false;
    } else if (_currentStep == 5) {
      return _trainingStatus == 'complete';
    }
    return true;
  }

  Future<void> _handleProceed() async {
    if (!_isStepValid()) return;
    
    if (_currentStep == 1) {
      _markStepDone(1);
      setState(() => _currentStep = 2);
      await _saveDraftBackend();
    } else if (_currentStep == 2) {
      _markStepDone(2);
      setState(() => _currentStep = 3);
      await _saveDraftBackend();
    } else if (_currentStep == 3) {
      _markStepDone(3);
      setState(() => _currentStep = 4);
      await _saveDraftBackend();
    } else if (_currentStep == 4) {
      _markStepDone(4);
      setState(() => _currentStep = 5);
      await _saveDraftBackend();
      _startTraining();
    }
  }

  void _handlePrevious() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
      _saveDraftBackend();
    }
  }

  Future<void> _pickManualDatasetFile() async {
    setState(() => _isActionLoading = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls', 'txt', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final name = result.files.single.name;
        
        final res = await ApiService().uploadDatasetFile(file, name);
        setState(() {
          _datasetId = res['dataset_id'];
          _columns = List<String>.from((res['columns'] as List?)?.map((e) => e.toString()) ?? []);
          _previewHead = List<Map<String, dynamic>>.from((res['preview_head'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
          _previewTail = List<Map<String, dynamic>>.from((res['preview_tail'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
          _rowCount = res['row_count'] ?? 0;
          _duplicateCount = res['duplicate_count'] ?? 0;
          
          _wizardState['datasetName'] = name;
          _wizardState['requiredFeatures'] = _columns.join(', ');
          _getController('datasetName', name).text = name;
          _getController('requiredFeatures', _columns.join(', ')).text = _columns.join(', ');
          
          // Reset featureDescriptions
          final featureDescriptions = <String, String>{};
          if (_previewHead.isNotEmpty) {
            final firstRow = _previewHead.first;
            for (var col in _columns) {
              if (!col.startsWith('_')) {
                featureDescriptions[col] = firstRow[col]?.toString() ?? '';
                _getController('fd_$col', firstRow[col]?.toString() ?? '').text = firstRow[col]?.toString() ?? '';
              }
            }
          }
          _wizardState['featureDescriptions'] = featureDescriptions;
          
          _isActionLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dataset berhasil diunggah: $name'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        await _saveDraftBackend();
      } else {
        setState(() => _isActionLoading = false);
      }
    } catch (e) {
      setState(() => _isActionLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah file dataset: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleProcess() async {
    setState(() => _isActionLoading = true);
    try {
      final s = _wizardState;
      final params = {
        'missing_values': s['missingValueStrategy'] ?? 'Drop blank rows',
        'duplicate_strategy': s['duplicateStrategy'] ?? 'Drop Duplicates',
        'categorical_encoding': s['categoricalEncoding'] ?? true,
        'apply_standardization': s['applyStandardization'] ?? true,
      };
      
      final res = await ApiService().runPreprocessing(_datasetId!, params);
      setState(() {
        _processedRows = List<Map<String, dynamic>>.from((res['processed_rows'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
        _processedColumns = List<String>.from((res['columns'] as List?)?.map((e) => e.toString()) ?? []);
        _processStats = Map<String, dynamic>.from(res['stats'] ?? {});
        _isActionLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Dataset berhasil diproses!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _saveDraftBackend();
    } catch (e) {
      setState(() => _isActionLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal preprocessing data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _startTraining() async {
    if (_trainingStatus == 'running' || _trainingStatus == 'pending') return;
    
    setState(() {
      _trainingStatus = 'pending';
      _trainingProgress = 0.0;
    });
    
    try {
      final s = _wizardState;
      final hyperparams = Map<String, dynamic>.from(s['hyperparams'] ?? {});
      final featureDescriptions = Map<String, dynamic>.from(s['featureDescriptions'] ?? {});
      
      final res = await ApiService().startModelTraining(
        datasetId: _datasetId!,
        targetColumn: s['targetColumn'] ?? 'target',
        algorithm: s['algorithm'] ?? 'Logistic Regression',
        hyperparams: hyperparams,
        featureDescriptions: featureDescriptions,
        problemType: s['problemType'] ?? 'classification',
        systemName: s['systemName'] ?? 'Data System',
        requiredFeatures: s['requiredFeatures'] ?? '',
        processingConfig: {
          'missing_values': s['missingValueStrategy'] ?? 'Drop blank rows',
          'duplicate_strategy': s['duplicateStrategy'] ?? 'Drop Duplicates',
          'categorical_encoding': s['categoricalEncoding'] ?? true,
          'standardization': s['applyStandardization'] ?? true,
        },
      );
      
      final jobId = res['job_id'];
      if (jobId != null) {
        setState(() {
          _jobId = jobId;
          _trainingStatus = 'running';
        });
        await _saveDraftBackend();
        _startPolling(jobId);
      }
    } catch (e) {
      setState(() {
        _trainingStatus = 'error';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulai training model: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _startPolling(String jobId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final res = await ApiService().getTrainingStatus(jobId);
        final status = res['status'] ?? 'pending';
        final progress = (res['progress'] ?? 0).toDouble();
        
        setState(() {
          _trainingStatus = status;
          _trainingProgress = progress;
        });

        if (status == 'complete') {
          timer.cancel();
          final result = await ApiService().getTrainingResult(jobId);
          setState(() {
            _trainingResult = result;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Pelatihan model selesai dengan sukses!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          await _saveDraftBackend();
        } else if (status == 'error') {
          timer.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pelatihan model gagal: ${res['error'] ?? "Unknown error"}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          await _saveDraftBackend();
        }
      } catch (e) {
        print("Polling training status failed: $e");
      }
    });
  }

  Future<void> _handleFinish() async {
    setState(() => _isActionLoading = true);
    try {
      await _saveDraftBackend();
      
      await ApiService().updateSubmissionStage(
        submissionId: widget.submissionId,
        stage: 7,
        pipelineData: {
          'stage_0': _wizardState,
          'stage_7': {'success': true},
        },
      );
      
      setState(() => _isActionLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Pipeline AI telah berhasil diselesaikan!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      setState(() => _isActionLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan pipeline: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka tautan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final proceedLabel = _currentStep == 2
        ? (_isActionLoading ? 'Loading...' : 'Load Dataset →')
        : (_currentStep == 4 ? 'Start Training →' : 'Proceed →');

    final bool nextDisabled = !_isStepValid() || _isActionLoading || (_currentStep == 5 && _trainingStatus != 'complete');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Wizard Tahap $_currentStep dari 5'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded, color: AppColors.primary),
            onPressed: () async {
              await _saveDraftBackend();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Draf tersimpan di server!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            tooltip: 'Simpan Draf',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // STEP PROGRESS INDICATOR
            _buildStepIndicator(),
            const Divider(color: AppColors.border, height: 1),
            
            // STEP CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildStepContent(),
              ),
            ),

            // NAVIGATION BAR
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomButton(
                    label: '← Previous',
                    isOutlined: true,
                    width: 120,
                    onPressed: _currentStep > 1 ? _handlePrevious : null,
                  ),
                  _currentStep < 5
                      ? CustomButton(
                          label: proceedLabel,
                          width: 150,
                          onPressed: nextDisabled ? null : _handleProceed,
                        )
                      : CustomButton(
                          label: 'Selesai ✓',
                          width: 150,
                          isLoading: _isActionLoading,
                          onPressed: _trainingStatus == 'complete' ? _handleFinish : null,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          final stepNum = index + 1;
          final isCompleted = _completedSteps.contains(stepNum);
          final isActive = _currentStep == stepNum;
          
          Color circleColor = AppColors.textMuted;
          Color textColor = Colors.white70;
          if (isCompleted) {
            circleColor = AppColors.success;
          } else if (isActive) {
            circleColor = AppColors.primary;
            textColor = Colors.white;
          }

          return Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: circleColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: circleColor, width: 1.5),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: AppColors.success)
                      : Text(
                          '$stepNum',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (index < 4) ...[
                const SizedBox(width: 8),
                Container(
                  width: MediaQuery.of(context).size.width * 0.08,
                  height: 1.5,
                  color: isCompleted ? AppColors.success : AppColors.border,
                ),
                const SizedBox(width: 8),
              ]
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Content();
      case 2:
        return _buildStep2Content();
      case 3:
        return _buildStep3Content();
      case 4:
        return _buildStep4Content();
      case 5:
        return _buildStep5Content();
      default:
        return Container();
    }
  }

  // ==========================================
  // STEP 1 - PROBLEM FRAMING
  // ==========================================
  Widget _buildStep1Content() {
    final s = _wizardState;
    final selectedType = s['problemType'] ?? 'classification';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '01 PROBLEM FRAMING',
          style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        const Text(
          'SELECT PROBLEM TYPE',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildProblemTypeSelector(selectedType),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'SYSTEM NAME',
          hint: 'e.g. Customer Churn Predictor',
          controller: _getController('systemName', s['systemName'] ?? ''),
          prefixIcon: Icons.computer_rounded,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'INPUT DATA DESCRIPTION',
          hint: 'Describe your input data, source, and context...',
          controller: _getController('inputDescription', s['inputDescription'] ?? ''),
          prefixIcon: Icons.description_outlined,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        if (selectedType != 'clustering') ...[
          CustomTextField(
            label: 'PRIMARY OUTCOME',
            hint: 'e.g. Churn Label',
            controller: _getController('primaryOutcome', s['primaryOutcome'] ?? ''),
            prefixIcon: Icons.flag_rounded,
          ),
          const SizedBox(height: 16),
        ]
      ],
    );
  }

  Widget _buildProblemTypeSelector(String selectedType) {
    final types = [
      {'id': 'classification', 'label': 'Classification', 'desc': 'Predict discrete categories'},
      {'id': 'regression', 'label': 'Regression', 'desc': 'Predict continuous values'},
      {'id': 'clustering', 'label': 'Clustering', 'desc': 'Group similar data points'},
    ];

    return Column(
      children: types.map((t) {
        final isSelected = selectedType == t['id'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _wizardState['problemType'] = t['id'];
              if (t['id'] == 'clustering') {
                _wizardState['primaryOutcome'] = 'N/A (Clustering)';
              } else if (_wizardState['primaryOutcome'] == 'N/A (Clustering)') {
                _wizardState['primaryOutcome'] = '';
                _getController('primaryOutcome', '').clear();
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['label']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(t['desc']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // STEP 2 - DATASET DEFINITION
  // ==========================================
  Widget _buildStep2Content() {
    final s = _wizardState;
    final source = s['datasetSource'] ?? 'api';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '02 DATASET DEFINITION',
          style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        const Text(
          'DATASET SOURCE',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSourceTab('api', 'API Ingestion', source == 'api')),
            const SizedBox(width: 12),
            Expanded(child: _buildSourceTab('manual', 'Manual File Upload', source == 'manual')),
          ],
        ),
        const SizedBox(height: 20),
        if (source == 'manual') ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('UPLOAD FILE DATASET (.csv, .xlsx, .txt, .pdf)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _datasetId != null ? (s['datasetName'] ?? 'Uploaded CSV') : 'Belum ada file terunggah',
                          style: TextStyle(color: _datasetId != null ? Colors.white : AppColors.textSecondary, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  label: _datasetId != null ? 'Ganti File Dataset' : 'Pilih & Unggah File',
                  isOutlined: true,
                  icon: Icons.upload_file_rounded,
                  onPressed: _pickManualDatasetFile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        CustomTextField(
          label: 'DATASET NAME',
          controller: _getController('datasetName', s['datasetName'] ?? ''),
          prefixIcon: Icons.storage_rounded,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'REQUIRED FEATURES',
          hint: 'Comma-separated columns, e.g. age, gender, salary',
          controller: _getController('requiredFeatures', s['requiredFeatures'] ?? ''),
          prefixIcon: Icons.list_rounded,
        ),
        const SizedBox(height: 16),
        if (s['problemType'] != 'clustering') ...[
          CustomTextField(
            label: 'TARGET COLUMN',
            hint: 'e.g. churned',
            controller: _getController('targetColumn', s['targetColumn'] ?? ''),
            prefixIcon: Icons.label_important_outline_rounded,
          ),
          const SizedBox(height: 16),
        ],
        CustomTextField(
          label: 'EXPECTED ROW COUNT',
          keyboardType: TextInputType.number,
          controller: _getController('jumlahData', s['jumlahData']?.toString() ?? '2000'),
          prefixIcon: Icons.tag_rounded,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSourceTab(String id, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _wizardState['datasetSource'] = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 3 - PROCESSING
  // ==========================================
  Widget _buildStep3Content() {
    final s = _wizardState;
    final hasProcessed = _processedRows.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '03 PROCESSING',
          style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        
        // Requirement Summary
        _buildSummaryCard(),
        const SizedBox(height: 20),

        // RAW Data Preview
        if (_previewHead.isNotEmpty) ...[
          _buildDataTableWidget(
            columns: _processedColumns.isNotEmpty ? _processedColumns : _columns,
            head: _previewHead,
            tail: _previewTail,
            label: 'DATA PREVIEW — RAW (BEFORE PROCESSING)',
          ),
          const SizedBox(height: 24),
        ],

        // FEATURE DESCRIPTIONS (Tabel pengisian deskripsi)
        if (_previewHead.isNotEmpty) ...[
          _buildFeatureDescriptionsForm(),
          const SizedBox(height: 24),
        ],

        // PROCESSING DECISIONS
        _buildProcessingDecisionsForm(),
        const SizedBox(height: 24),

        // PROCESSED Data Preview (After Run Processing)
        if (hasProcessed) ...[
          _buildDataTableWidget(
            columns: _processedColumns,
            head: _processedRows.take(5).toList(),
            tail: _processedRows.skip(_processedRows.length > 5 ? _processedRows.length - 5 : 0).toList(),
            label: 'DATA PREVIEW — AFTER PROCESSING',
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildSummaryCard() {
    final s = _wizardState;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REQUIREMENT SUMMARY', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Jumlah Data', s['jumlahData']?.toString() ?? '—'),
              _buildSummaryItem('Target Column', s['targetColumn'] ?? '—'),
              _buildSummaryItem('Required Features', s['requiredFeatures'] ?? '—'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String key, String val) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(key, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDataTableWidget({
    required List<String> columns,
    required List<Map<String, dynamic>> head,
    required List<Map<String, dynamic>> tail,
    required String label,
  }) {
    final filteredCols = columns.where((c) => !c.startsWith('_')).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surface),
              dataRowMinHeight: 30,
              dataRowMaxHeight: 45,
              columnSpacing: 16,
              columns: filteredCols.map((col) {
                return DataColumn(
                  label: Text(
                    col.toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
              rows: head.map((row) {
                return DataRow(
                  cells: filteredCols.map((col) {
                    return DataCell(
                      Text(
                        row[col]?.toString() ?? '—',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          if (tail.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: Text('• • •', style: TextStyle(color: AppColors.textMuted))),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.surface),
                dataRowMinHeight: 30,
                dataRowMaxHeight: 45,
                columnSpacing: 16,
                columns: filteredCols.map((col) {
                  return DataColumn(
                    label: Text(
                      col.toUpperCase(),
                      style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                rows: tail.map((row) {
                  return DataRow(
                    cells: filteredCols.map((col) {
                      return DataCell(
                        Text(
                          row[col]?.toString() ?? '—',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildFeatureDescriptionsForm() {
    final filteredCols = _columns.where((c) => !c.startsWith('_')).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FEATURE DESCRIPTIONS / DESKRIPSI FITUR', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Sesuaikan deskripsi atau contoh nilai untuk masing-masing fitur di bawah ini. Deskripsi ini akan dicantumkan pada laporan akhir.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          ...filteredCols.map((col) {
            final defaultVal = _wizardState['featureDescriptions']?[col] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: CustomTextField(
                label: col.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' '),
                hint: 'Contoh atau deskripsi untuk $col...',
                controller: _getController('fd_$col', defaultVal),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProcessingDecisionsForm() {
    final s = _wizardState;
    final missingStrategy = s['missingValueStrategy'] ?? 'Drop blank rows';
    final duplicateStrategy = s['duplicateStrategy'] ?? 'Drop Duplicates';
    final categoricalEncoding = s['categoricalEncoding'] ?? true;
    final applyStandardization = s['applyStandardization'] ?? true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROCESSING DECISIONS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // MISSING VALUES DROPDOWN
          const Text('MISSING VALUES', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: missingStrategy,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: const [
              DropdownMenuItem(value: 'Drop blank rows', child: Text('Drop blank rows')),
              DropdownMenuItem(value: 'Fill with mean', child: Text('Fill with mean')),
              DropdownMenuItem(value: 'Fill with median', child: Text('Fill with median')),
              DropdownMenuItem(value: 'Fill with mode', child: Text('Fill with mode')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _wizardState['missingValueStrategy'] = val);
            },
          ),
          const SizedBox(height: 16),

          // DUPLICATE STRATEGY DROPDOWN
          const Text('DUPLICATE STRATEGY', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: duplicateStrategy,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: const [
              DropdownMenuItem(value: 'Keep Duplicates', child: Text('Keep Duplicates')),
              DropdownMenuItem(value: 'Drop Duplicates', child: Text('Drop Duplicates')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _wizardState['duplicateStrategy'] = val);
            },
          ),
          const SizedBox(height: 16),

          // CATEGORICAL ENCODING SWITCH
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CATEGORICAL ENCODING', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Convert text to numerical vectors', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Switch(
                value: categoricalEncoding,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _wizardState['categoricalEncoding'] = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // STANDARDIZATION SWITCH
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('APPLY STANDARDIZATION', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Recommended for distance-based models', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Switch(
                value: applyStandardization,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _wizardState['applyStandardization'] = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          CustomButton(
            label: _isActionLoading ? 'Processing...' : 'Run Processing',
            isLoading: _isActionLoading,
            icon: Icons.play_arrow_rounded,
            onPressed: _isActionLoading ? null : _handleProcess,
          )
        ],
      ),
    );
  }

  // ==========================================
  // STEP 4 - MODEL PLANNING
  // ==========================================
  Widget _buildStep4Content() {
    final s = _wizardState;
    final currentAlgo = s['algorithm'] ?? (widget.modality == 'text' ? 'MLP' : 'Logistic Regression');

    final List<String> algos = widget.modality == 'text'
        ? ['BiLSTM', 'CNN-Text', 'MLP']
        : ['Logistic Regression', 'Decision Tree', 'Random Forest', 'Linear SVM', 'Gradient Boosting Regressor', 'Ridge Regression'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '04 MODEL PLANNING',
          style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        const Text('ALGORITMA MODEL PILIHAN', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: algos.contains(currentAlgo) ? currentAlgo : algos.first,
          dropdownColor: AppColors.card,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: algos.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _wizardState['algorithm'] = val;
              });
            }
          },
        ),
        const SizedBox(height: 24),
        const Text('HYPERPARAMETERS', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildHyperparamsForm(currentAlgo),
      ],
    );
  }

  Widget _buildHyperparamsForm(String algo) {
    if (_wizardState['hyperparams'] == null) {
      _wizardState['hyperparams'] = <String, dynamic>{};
    }
    final h = _wizardState['hyperparams'] as Map<String, dynamic>;

    if (algo == 'Logistic Regression') {
      return Column(
        children: [
          _buildNumericHyperparamField('C', 'Regularization strength (e.g. 1.0)', h, defaultValue: 1.0),
          const SizedBox(height: 16),
          _buildNumericHyperparamField('max_iter', 'Maximum iterations (e.g. 100)', h, isInteger: true, defaultValue: 100),
          const SizedBox(height: 16),
          _buildDropdownHyperparamField('penalty', 'Penalty term', h, ['l2', 'l1', 'none'], defaultValue: 'l2'),
          const SizedBox(height: 16),
          _buildDropdownHyperparamField('solver', 'Optimization solver', h, ['lbfgs', 'liblinear', 'saga'], defaultValue: 'lbfgs'),
        ],
      );
    } else if (algo == 'Decision Tree') {
      return Column(
        children: [
          _buildNumericHyperparamField('max_depth', 'Max tree depth (empty for infinite)', h, isInteger: true),
          const SizedBox(height: 16),
          _buildNumericHyperparamField('min_samples_split', 'Min samples to split (e.g. 2)', h, isInteger: true, defaultValue: 2),
          const SizedBox(height: 16),
          _buildDropdownHyperparamField('criterion', 'Splitting quality metric', h, ['gini', 'entropy'], defaultValue: 'gini'),
        ],
      );
    } else if (algo == 'Random Forest') {
      return Column(
        children: [
          _buildNumericHyperparamField('n_estimators', 'Number of trees (e.g. 100)', h, isInteger: true, defaultValue: 100),
          const SizedBox(height: 16),
          _buildNumericHyperparamField('max_depth', 'Max tree depth (empty for infinite)', h, isInteger: true),
          const SizedBox(height: 16),
          _buildNumericHyperparamField('min_samples_split', 'Min samples to split (e.g. 2)', h, isInteger: true, defaultValue: 2),
          const SizedBox(height: 16),
          _buildDropdownHyperparamField('criterion', 'Splitting quality metric', h, ['gini', 'entropy'], defaultValue: 'gini'),
        ],
      );
    } else {
      return Column(
        children: [
          _buildNumericHyperparamField('learning_rate', 'Learning rate (e.g. 0.3)', h, defaultValue: 0.3),
          const SizedBox(height: 16),
          _buildNumericHyperparamField('max_iter', 'Training epochs (e.g. 100)', h, isInteger: true, defaultValue: 100),
        ],
      );
    }
  }

  Widget _buildNumericHyperparamField(String key, String hint, Map<String, dynamic> hyperparams, {bool isInteger = false, dynamic defaultValue}) {
    if (!hyperparams.containsKey(key)) {
      hyperparams[key] = defaultValue;
    }
    
    return CustomTextField(
      label: key.replaceAll('_', ' ').toUpperCase(),
      hint: hint,
      keyboardType: TextInputType.number,
      controller: _getController('hp_$key', hyperparams[key]?.toString() ?? ''),
      onChanged: (text) {
        if (text.trim().isEmpty) {
          hyperparams[key] = null;
        } else {
          hyperparams[key] = isInteger ? (int.tryParse(text) ?? defaultValue) : (double.tryParse(text) ?? defaultValue);
        }
      },
    );
  }

  Widget _buildDropdownHyperparamField(String key, String label, Map<String, dynamic> hyperparams, List<String> options, {required String defaultValue}) {
    if (!hyperparams.containsKey(key)) {
      hyperparams[key] = defaultValue;
    }
    final currentVal = hyperparams[key]?.toString() ?? defaultValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: options.contains(currentVal) ? currentVal : options.first,
          dropdownColor: AppColors.card,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                hyperparams[key] = val;
              });
            }
          },
        ),
      ],
    );
  }

  // ==========================================
  // STEP 5 - ENGINE EXECUTION
  // ==========================================
  Widget _buildStep5Content() {
    final isPending = _trainingStatus == 'pending' || _trainingStatus == 'running';
    final isComplete = _trainingStatus == 'complete';
    final isError = _trainingStatus == 'error';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '05 ENGINE EXECUTION',
          style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 24),
        if (isPending) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Melatih Model AI...',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Awaiting dataset ingestion... Please do not navigate away.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                if (_trainingProgress > 0) ...[
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: _trainingProgress / 100.0,
                      minHeight: 6,
                      backgroundColor: AppColors.surface,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${_trainingProgress.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ]
              ],
            ),
          )
        ],
        if (isError) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.error, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pelatihan model gagal. Silakan periksa kembali parameter Anda dan coba lagi.',
                    style: TextStyle(color: AppColors.error.withValues(alpha: 0.9), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Mulai Ulang Training',
            icon: Icons.refresh_rounded,
            onPressed: _startTraining,
          )
        ],
        if (isComplete && _trainingResult.isNotEmpty) ...[
          _buildExecutiveDashboard(),
          const SizedBox(height: 24),
          _buildModelSummaryReport(),
          const SizedBox(height: 24),
          _buildDataQualityReport(),
        ],
        if (_trainingStatus == 'idle') ...[
          const Center(
            child: Text(
              'Menunggu eksekusi latihan...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        ]
      ],
    );
  }

  Widget _buildExecutiveDashboard() {
    final res = _trainingResult;
    final probType = res['model_summary']?['problem_type'] ?? 'classification';
    final double? acc = res['accuracy'] != null ? (res['accuracy'] as num).toDouble() : null;
    final accuracyText = acc != null ? '${acc.toStringAsFixed(1)}%' : '—';
    final performanceText = acc != null ? (acc > 90 ? 'Excellent' : (acc > 75 ? 'Good' : 'Needs Tuning')) : '—';
    final performanceColor = performanceText == 'Excellent' ? AppColors.success : (performanceText == 'Good' ? AppColors.primary : AppColors.warning);

    final healthRating = res['data_quality_report']?['health_rating'] ?? 'Good';
    final healthColor = healthRating == 'Excellent' ? AppColors.success : (healthRating == 'Good' ? AppColors.primary : AppColors.warning);

    final topFeature = (res['feature_importances'] as List?)?.isNotEmpty == true ? res['feature_importances'][0]['feature'] : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EXECUTIVE SUMMARY', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          children: [
            _buildExecutiveCard('Model Performance', performanceText, performanceColor),
            _buildExecutiveCard(probType == 'clustering' ? 'Silhouette' : (probType == 'regression' ? 'R² Score' : 'Accuracy'), accuracyText, Colors.white),
            _buildExecutiveCard('Dataset Health', healthRating, healthColor),
            _buildExecutiveCard('Top Driver Feature', topFeature, AppColors.primary),
          ],
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'Unduh Model (.pkl)',
                icon: Icons.download_rounded,
                isOutlined: true,
                onPressed: () => _launchUrl('${ApiService().baseUrl}/api/train/download/$_jobId'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'Laporan PDF',
                icon: Icons.picture_as_pdf_rounded,
                onPressed: () => _launchUrl('${ApiService().baseUrl}/api/train/pdf-report/$_jobId'),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildExecutiveCard(String label, String value, Color valColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: valColor, fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModelSummaryReport() {
    final res = _trainingResult;
    final summary = res['model_summary'] ?? {};
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1. MODEL SUMMARY', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _buildReportRow('Selected Algorithm', summary['algorithm']?.toString() ?? '—'),
          _buildReportRow('Problem Type', summary['problem_type']?.toString() ?? '—'),
          _buildReportRow('Training Records', summary['training_records']?.toString() ?? '—'),
          _buildReportRow('Number of Features', summary['features_count']?.toString() ?? '—'),
          _buildReportRow('Training Time', '${summary['training_time_sec']?.toString() ?? '—'} sec'),
        ],
      ),
    );
  }

  Widget _buildDataQualityReport() {
    final res = _trainingResult;
    final dq = res['data_quality_report'] ?? {};
    final double missingValPct = (dq['missing_values_pct'] ?? 0).toDouble();
    final double duplicateValPct = (dq['duplicate_rows_pct'] ?? 0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('2. DATA QUALITY REPORT', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _buildReportRow('Total Records', dq['total_records']?.toString() ?? '—'),
          _buildReportRow('Missing Values Count', '${dq['missing_values_count']?.toString() ?? '—'} ($missingValPct%)'),
          _buildReportRow('Duplicate Rows Count', '${dq['duplicate_rows_count']?.toString() ?? '—'} ($duplicateValPct%)'),
          _buildReportRow('Numerical Features', dq['numerical_features_count']?.toString() ?? '—'),
          _buildReportRow('Categorical Features', dq['categorical_features_count']?.toString() ?? '—'),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}