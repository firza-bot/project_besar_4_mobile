import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../utils/constants.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Dynamic state for datasets
  late List<Map<String, dynamic>> _datasets;

  @override
  void initState() {
    super.initState();
    _initMockData();
  }

  void _initMockData() {
    _datasets = [
      {
        'title': 'Data Pasien Jantung Surabaya',
        'file_name': 'pasien_jantung_surabaya_2026.csv',
        'source': 'CSV Upload',
        'quality_score': 94.2,
        'prev_quality_score': 90.9,
        'total_issues': 5,
        'critical_count': 1,
        'total_records': 150000,
        'valid_records': 148500,
        'created_at': '2026-06-15T08:30:00Z',
      },
      {
        'title': 'Data Kriminalitas DKI Jakarta',
        'file_name': 'kriminalitas_dki_juni.json',
        'source': 'API Stream',
        'quality_score': 88.5,
        'prev_quality_score': 89.2,
        'total_issues': 12,
        'critical_count': 3,
        'total_records': 85000,
        'valid_records': 81200,
        'created_at': '2026-06-16T10:15:00Z',
      },
      {
        'title': 'Dataset Kepuasan Pelanggan 2026',
        'file_name': 'customer_satisfaction_v1.xlsx',
        'source': 'Manual Entry',
        'quality_score': 95.8,
        'prev_quality_score': 92.5,
        'total_issues': 2,
        'critical_count': 0,
        'total_records': 12000,
        'valid_records': 11950,
        'created_at': '2026-06-17T14:45:00Z',
      },
      {
        'title': 'Data Log Transaksi Finansial',
        'file_name': 'trx_logs_q2.csv',
        'source': 'Database Link',
        'quality_score': 91.0,
        'prev_quality_score': 88.0,
        'total_issues': 18,
        'critical_count': 0,
        'total_records': 2400000,
        'valid_records': 2382000,
        'created_at': '2026-06-17T18:00:00Z',
      },
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Calculate platform averages
  double get _avgQualityScore {
    if (_datasets.isEmpty) return 0;
    return _datasets.map((d) => d['quality_score'] as double).reduce((a, b) => a + b) / _datasets.length;
  }

  int get _totalRecords {
    if (_datasets.isEmpty) return 0;
    return _datasets.map((d) => d['total_records'] as int).reduce((a, b) => a + b);
  }



  int get _criticalIssues {
    if (_datasets.isEmpty) return 0;
    return _datasets.map((d) => d['critical_count'] as int).reduce((a, b) => a + b);
  }

  // Filtered list
  List<Map<String, dynamic>> get _filteredDatasets {
    if (_searchQuery.isEmpty) return _datasets;
    return _datasets.where((d) {
      final title = d['title'].toString().toLowerCase();
      final source = d['source'].toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase()) || source.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Delete Action
  void _deleteDataset(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: const Text('Hapus Data', style: TextStyle(color: Colors.white)),
        content: Text(
          'Apakah Anda yakin ingin menghapus data "${_filteredDatasets[index]['title']}" dari daftar pipeline monitoring?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              final actualItem = _filteredDatasets[index];
              setState(() {
                _datasets.remove(actualItem);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dataset "${actualItem['title']}" berhasil dihapus'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Monitor Grafik & Kualitas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: KPI Stats Grid
            Row(
              children: [
                _buildStatCard('Platform Quality', '${_avgQualityScore.toStringAsFixed(1)}%', AppColors.success, Icons.star_rounded),
                const SizedBox(width: 12),
                _buildStatCard('Total Records', _formatRecordCount(_totalRecords), AppColors.info, Icons.storage_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard('Active Pipelines', '${_datasets.length}', AppColors.warning, Icons.bubble_chart_rounded),
                const SizedBox(width: 12),
                _buildStatCard('Critical Issues', '$_criticalIssues', AppColors.error, Icons.warning_amber_rounded),
              ],
            ),
            const SizedBox(height: 24),

            // Section 2: Search Box
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan nama dataset atau sumber...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Dataset Terproses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: ${_filteredDatasets.length}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Section 4: Dataset List/Cards
            if (_filteredDatasets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.layers_clear_rounded, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text('Tidak ada data ditemukan', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredDatasets.length,
                itemBuilder: (context, index) {
                  return _buildDatasetCard(_filteredDatasets[index], index);
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Stat Card Widget
  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Row Card Widget representing a Row in Grid 4 Web Table
  Widget _buildDatasetCard(Map<String, dynamic> item, int index) {
    final double score = item['quality_score'];
    final double prevScore = item['prev_quality_score'];
    final double diff = score - prevScore;
    final bool isUp = diff >= 0;
    final String trendStr = '${isUp ? '+' : ''}${diff.toStringAsFixed(1)}%';
    final Color scoreColor = score >= 92
        ? AppColors.success
        : score >= 85
            ? AppColors.warning
            : AppColors.error;

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
          // Row 1: Icon, Title & Source
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sumber: ${item['source']}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),

          // Row 2: Metrics (Quality Score, Issues, Records)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Metric 1: Quality Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('QUALITY SCORE', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${score.toStringAsFixed(1)}%',
                        style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isUp ? '↑' : '↓'} $trendStr',
                        style: TextStyle(color: isUp ? AppColors.success : AppColors.error, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),

              // Metric 2: Issues
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ISSUES', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.bug_report_rounded,
                          size: 16,
                          color: item['critical_count'] > 0 ? AppColors.error : AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        '${item['total_issues']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (item['critical_count'] > 0)
                        Text(
                          ' (${item['critical_count']} Crit)',
                          style: const TextStyle(color: AppColors.error, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ],
              ),

              // Metric 3: Records
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RECORDS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    _formatRecordCount(item['total_records']),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Row 3: Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Button 1: Lihat Grafik
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25), width: 1),
                  ),
                ),
                icon: const Icon(Icons.analytics_rounded, size: 16),
                label: const Text('Lihat Grafik', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: () => _showAnalysisCharts(item),
              ),
              const SizedBox(width: 8),

              // Button 2: Cetak Laporan
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                  foregroundColor: AppColors.secondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.25), width: 1),
                  ),
                ),
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text('Cetak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: () => _printReport(item),
              ),
              const SizedBox(width: 8),

              // Button 3: Hapus Data
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.15),
                  foregroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.2), width: 1),
                  ),
                ),
                icon: const Icon(Icons.delete_rounded, size: 16),
                onPressed: () => _deleteDataset(index),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Formatting large record numbers: e.g. 150000 -> 150K, 2400000 -> 2.4M
  String _formatRecordCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(0)}K';
    }
    return count.toString();
  }

  // ==========================================
  // CHART MODAL BOTTOM SHEET (4 CHARTS)
  // ==========================================
  void _showAnalysisCharts(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.88,
            color: const Color(0xFF0D0D1E),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),

                // Modal Title & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Grafik Analisis Kualitas',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['title'],
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // Horizontal Stats summary inside Modal
                Row(
                  children: [
                    _buildModalSummaryItem('Score', '${(item['quality_score'] as double).toStringAsFixed(1)}%', AppColors.success),
                    const SizedBox(width: 8),
                    _buildModalSummaryItem('Valid Recs', _formatRecordCount(item['valid_records']), AppColors.primary),
                    const SizedBox(width: 8),
                    _buildModalSummaryItem('Issues', '${item['total_issues']}', AppColors.warning),
                    const SizedBox(width: 8),
                    _buildModalSummaryItem('Critical', '${item['critical_count']}', AppColors.error),
                  ],
                ),
                const SizedBox(height: 18),

                // Scrollable Container for 4 Charts
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Chart 1: Data Issues by Category Stacked Bar Chart
                        _buildChartCard(
                          title: 'Data Issues by Category & Severity',
                          subtitle: 'Kategori: Missing, Duplicates, Format, Outliers, Schema',
                          height: 220,
                          chart: _buildBarChartIssues(item),
                          legend: _buildIssuesLegend(),
                        ),
                        const SizedBox(height: 16),

                        // Chart 2: Overall Quality Score Trend Line Chart
                        _buildChartCard(
                          title: 'Overall Quality Score Trend',
                          subtitle: 'Perkembangan kualitas data historis 7 hari',
                          height: 200,
                          chart: _buildTrendLineChart(item),
                        ),
                        const SizedBox(height: 16),

                        // Chart 3: Quality Dimensions Trend Multi-Line Chart
                        _buildChartCard(
                          title: 'Quality Dimensions Trend',
                          subtitle: 'Dimensi: Completeness, Accuracy, Consistency, Validity, Uniqueness',
                          height: 200,
                          chart: _buildDimensionsLineChart(item),
                          legend: _buildDimensionsLegend(),
                        ),
                        const SizedBox(height: 16),

                        // Chart 4: Data Freshness Status Area Chart
                        _buildChartCard(
                          title: 'Data Freshness Status',
                          subtitle: 'Status persentase Fresh vs Stale sepanjang hari',
                          height: 200,
                          chart: _buildFreshnessLineChart(item),
                          legend: _buildFreshnessLegend(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper inside modal
  Widget _buildModalSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 0.8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }

  // Wrapper for each chart
  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required double height,
    required Widget chart,
    Widget? legend,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
          const SizedBox(height: 16),
          SizedBox(height: height, child: chart),
          if (legend != null) ...[
            const SizedBox(height: 12),
            legend,
          ]
        ],
      ),
    );
  }

  // ==========================================
  // CHART BUILDERS (fl_chart)
  // ==========================================

  // Chart 1: Stacked Bar Chart for Data Issues
  Widget _buildBarChartIssues(Map<String, dynamic> item) {
    final int totalIssues = item['total_issues'];
    final int crit = item['critical_count'];
    final int base = max(1, (totalIssues / 5).round());

    // Generate estimates per category
    final List<double> criticals = [crit.toDouble() / 5, crit.toDouble() / 5, crit.toDouble() / 5, crit.toDouble() / 5, crit.toDouble() / 5];
    final List<double> highs = [base.toDouble() * 1.2, base.toDouble() * 0.8, base.toDouble() * 1.5, base.toDouble() * 0.5, base.toDouble()];
    final List<double> mediums = [base.toDouble() * 0.8, base.toDouble() * 1.2, base.toDouble() * 0.6, base.toDouble() * 1.1, base.toDouble() * 0.9];
    final List<double> lows = [1.0, 1.0, 1.0, 1.0, 1.0];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (base * 4).toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: AppColors.textSecondary, fontSize: 9);
                switch (value.toInt()) {
                  case 0: return SideTitleWidget(meta: meta, child: const Text('Missing', style: style));
                  case 1: return SideTitleWidget(meta: meta, child: const Text('Duplicate', style: style));
                  case 2: return SideTitleWidget(meta: meta, child: const Text('Format', style: style));
                  case 3: return SideTitleWidget(meta: meta, child: const Text('Outliers', style: style));
                  case 4: return SideTitleWidget(meta: meta, child: const Text('Schema', style: style));
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(5, (i) {
          final cVal = criticals[i];
          final hVal = highs[i];
          final mVal = mediums[i];
          final lVal = lows[i];
          final total = cVal + hVal + mVal + lVal;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: total,
                color: Colors.transparent,
                width: 14,
                borderRadius: BorderRadius.circular(3),
                rodStackItems: [
                  BarChartRodStackItem(0, lVal, AppColors.success),
                  BarChartRodStackItem(lVal, lVal + mVal, AppColors.info),
                  BarChartRodStackItem(lVal + mVal, lVal + mVal + hVal, AppColors.warning),
                  BarChartRodStackItem(lVal + mVal + hVal, total, AppColors.error),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildIssuesLegend() {
    return Wrap(
      spacing: 16,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem('Critical', AppColors.error),
        _buildLegendItem('High', AppColors.warning),
        _buildLegendItem('Medium', AppColors.info),
        _buildLegendItem('Low', AppColors.success),
      ],
    );
  }

  // Chart 2: 7-Day Quality Score Trend
  Widget _buildTrendLineChart(Map<String, dynamic> item) {
    final double currentScore = item['quality_score'];
    final double prevScore = item['prev_quality_score'];
    final double step = (currentScore - prevScore) / 6;

    // Last 7 days labels
    final today = DateTime.now();
    final List<String> dates = List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      return '${date.day} ${_getMonthName(date.month)}';
    });

    final List<FlSpot> spots = List.generate(7, (i) {
      final baseVal = prevScore + (step * i);
      // add a small fluctuation
      final val = i == 6 ? currentScore : baseVal + (sin(i) * 1.1);
      return FlSpot(i.toDouble(), double.parse(val.toStringAsFixed(1)));
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < 7) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(dates[idx], style: const TextStyle(color: AppColors.textSecondary, fontSize: 8.5)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 60,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: AppColors.primaryGradient,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.success,
                strokeWidth: 1.5,
                strokeColor: const Color(0xFF0D0D1E),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppColors.success.withValues(alpha: 0.15), AppColors.success.withValues(alpha: 0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Chart 3: Quality Dimensions Trend (Completeness, Accuracy, Consistency, Validity, Uniqueness)
  Widget _buildDimensionsLineChart(Map<String, dynamic> item) {
    final double q = item['quality_score'];
    final List<Color> colors = [Colors.blue, Colors.orange, Colors.red, Colors.purple, Colors.green];

    // Build data line for each dimension with small random deviations
    final List<List<FlSpot>> lines = List.generate(5, (i) {
      final base = q - 3 - (i * 2);
      return List.generate(5, (j) {
        final val = base + sin(j + i) * 2;
        return FlSpot(j.toDouble(), double.parse(val.clamp(50, 100).toStringAsFixed(1)));
      });
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                const style = TextStyle(color: AppColors.textSecondary, fontSize: 8.5);
                switch (idx) {
                  case 0: return SideTitleWidget(meta: meta, child: const Text('Sen', style: style));
                  case 1: return SideTitleWidget(meta: meta, child: const Text('Sel', style: style));
                  case 2: return SideTitleWidget(meta: meta, child: const Text('Rab', style: style));
                  case 3: return SideTitleWidget(meta: meta, child: const Text('Kam', style: style));
                  case 4: return SideTitleWidget(meta: meta, child: const Text('Jum', style: style));
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 4,
        minY: 60,
        maxY: 100,
        lineBarsData: List.generate(5, (i) {
          return LineChartBarData(
            spots: lines[i],
            isCurved: true,
            color: colors[i],
            barWidth: 2,
            dotData: const FlDotData(show: false),
          );
        }),
      ),
    );
  }

  Widget _buildDimensionsLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem('Completeness', Colors.blue),
        _buildLegendItem('Accuracy', Colors.orange),
        _buildLegendItem('Consistency', Colors.red),
        _buildLegendItem('Validity', Colors.purple),
        _buildLegendItem('Uniqueness', Colors.green),
      ],
    );
  }

  // Chart 4: Fresh vs Stale Data Over the Day
  Widget _buildFreshnessLineChart(Map<String, dynamic> item) {
    final double score = item['quality_score'];
    final double freshBase = score > 90 ? 94.0 : 86.0;

    final List<FlSpot> freshSpots = [
      FlSpot(0, freshBase - 1.2),
      FlSpot(1, freshBase + 1.5),
      FlSpot(2, freshBase - 0.8),
      FlSpot(3, freshBase + 2.1),
      FlSpot(4, freshBase - 1.4),
      FlSpot(5, freshBase),
    ];

    final List<FlSpot> staleSpots = freshSpots.map((spot) {
      final y = 100.0 - spot.y - 1.5; // leaving some room
      return FlSpot(spot.x, double.parse(max(0.0, y).toStringAsFixed(1)));
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                const style = TextStyle(color: AppColors.textSecondary, fontSize: 8.5);
                switch (idx) {
                  case 0: return SideTitleWidget(meta: meta, child: const Text('00:00', style: style));
                  case 1: return SideTitleWidget(meta: meta, child: const Text('04:00', style: style));
                  case 2: return SideTitleWidget(meta: meta, child: const Text('08:00', style: style));
                  case 3: return SideTitleWidget(meta: meta, child: const Text('12:00', style: style));
                  case 4: return SideTitleWidget(meta: meta, child: const Text('16:00', style: style));
                  case 5: return SideTitleWidget(meta: meta, child: const Text('20:00', style: style));
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: 120,
        lineBarsData: [
          // Fresh Line
          LineChartBarData(
            spots: freshSpots,
            isCurved: true,
            color: AppColors.success,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppColors.success.withValues(alpha: 0.12), AppColors.success.withValues(alpha: 0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Stale Line
          LineChartBarData(
            spots: staleSpots,
            isCurved: true,
            color: AppColors.error,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppColors.error.withValues(alpha: 0.08), AppColors.error.withValues(alpha: 0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreshnessLegend() {
    return Wrap(
      spacing: 16,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem('Fresh (%)', AppColors.success),
        _buildLegendItem('Stale (%)', AppColors.error),
      ],
    );
  }

  // Common legend item
  Widget _buildLegendItem(String name, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(name, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  // ==========================================
  // COMPREHENSIVE PDF/REPORT PREVIEW DIALOG
  // ==========================================
  void _printReport(Map<String, dynamic> item) {
    final score = item['quality_score'] as double;
    final totalRec = item['total_records'] as int;
    final totalIssues = item['total_issues'] as int;
    final crit = item['critical_count'] as int;
    final diff = score - (item['prev_quality_score'] as double);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFFBFBFD),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Mimicking PDF Layout)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INSIGHT DATA QUALITY PLATFORM • REPORT',
                            style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'LAPORAN DATA QUALITY & PIPELINE',
                            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            item['title'],
                            style: TextStyle(color: Colors.indigo.shade800, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1.5, color: Colors.grey.shade300),
                const SizedBox(height: 12),

                // Meta Info Box (Fixed overflow using Expanded)
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Text('Versi: 1.0', style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
                      const SizedBox(width: 12),
                      Text('Sumber: ${item['source']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'File: ${item['file_name']}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // KPI Grid Row
                Row(
                  children: [
                    _buildReportKpiItem('Avg Quality Score', '${score.toStringAsFixed(1)}%', Colors.green.shade700),
                    const SizedBox(width: 8),
                    _buildReportKpiItem('Quality Trend', '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}%', Colors.green.shade700),
                    const SizedBox(width: 8),
                    _buildReportKpiItem('Data Issues', '$totalIssues', Colors.orange.shade700),
                    const SizedBox(width: 8),
                    _buildReportKpiItem('Critical Issues', '$crit', Colors.red.shade700),
                  ],
                ),
                const SizedBox(height: 20),

                // Details Section Table and Charts
                const Text('DETAIL DIMENSI KUALITAS', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      _buildReportTableRow('Completeness', '${(score * 0.97).toStringAsFixed(0)}%', 'Lulus (Baik)'),
                      _buildReportTableRow('Accuracy', '${(score * 0.94).toStringAsFixed(0)}%', 'Lulus (Baik)'),
                      _buildReportTableRow('Validity', '${(score * 0.95).toStringAsFixed(0)}%', 'Lulus (Baik)'),
                      _buildReportTableRow('Consistency', '${(score * 0.91).toStringAsFixed(0)}%', 'Lulus (Baik)'),
                      _buildReportTableRow('Timeliness', '89.9%', 'Perlu Review'),
                      _buildReportTableRow('Total Records', _formatRecordCount(totalRec), 'Diterima'),
                      _buildReportTableRow('Valid Records', _formatRecordCount(item['valid_records']), 'Disimpan'),
                      
                      const SizedBox(height: 24),
                      const Text(
                        'GRAFIK ANALISIS PIPELINE',
                        style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 12),
                      _buildReportChartCard(
                        title: 'Data Issues by Category',
                        height: 160,
                        chart: _buildReportBarChart(item),
                      ),
                      const SizedBox(height: 16),
                      _buildReportChartCard(
                        title: 'Quality Score Trend',
                        height: 150,
                        chart: _buildReportLineChart(item),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Container(height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 12),

                // Bottom actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Insight Data Quality Platform 2026',
                      style: TextStyle(color: Colors.grey, fontSize: 8.5, fontStyle: FontStyle.italic),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                      label: const Text('Unduh PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(context);
                        _generateAndSavePDF(item);
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportKpiItem(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 8, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTableRow(String label, String value, String status) {
    final bool isWarning = status.contains('Review');
    final Color textColor = isWarning ? Colors.orange.shade800 : Colors.green.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 12.5, fontWeight: FontWeight.w500)),
          Row(
            children: [
              Text(value, style: const TextStyle(color: Colors.black, fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Text(
                status,
                style: TextStyle(color: textColor, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildReportChartCard({
    required String title,
    required double height,
    required Widget chart,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(height: height, child: chart),
        ],
      ),
    );
  }

  Widget _buildReportBarChart(Map<String, dynamic> item) {
    final int totalIssues = item['total_issues'];
    final int crit = item['critical_count'];
    final int base = max(1, (totalIssues / 5).round());

    final List<double> criticals = [crit.toDouble() / 5, crit.toDouble() / 5, crit.toDouble() / 5, crit.toDouble() / 5, crit.toDouble() / 5];
    final List<double> highs = [base.toDouble() * 1.2, base.toDouble() * 0.8, base.toDouble() * 1.5, base.toDouble() * 0.5, base.toDouble()];
    final List<double> mediums = [base.toDouble() * 0.8, base.toDouble() * 1.2, base.toDouble() * 0.6, base.toDouble() * 1.1, base.toDouble() * 0.9];
    final List<double> lows = [1.0, 1.0, 1.0, 1.0, 1.0];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (base * 4).toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: Colors.black54, fontSize: 8.5, fontWeight: FontWeight.bold);
                switch (value.toInt()) {
                  case 0: return SideTitleWidget(meta: meta, child: const Text('Missing', style: style));
                  case 1: return SideTitleWidget(meta: meta, child: const Text('Duplicate', style: style));
                  case 2: return SideTitleWidget(meta: meta, child: const Text('Format', style: style));
                  case 3: return SideTitleWidget(meta: meta, child: const Text('Outliers', style: style));
                  case 4: return SideTitleWidget(meta: meta, child: const Text('Schema', style: style));
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.black45, fontSize: 8.5)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(5, (i) {
          final cVal = criticals[i];
          final hVal = highs[i];
          final mVal = mediums[i];
          final lVal = lows[i];
          final total = cVal + hVal + mVal + lVal;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: total,
                color: Colors.transparent,
                width: 14,
                borderRadius: BorderRadius.circular(3),
                rodStackItems: [
                  BarChartRodStackItem(0, lVal, Colors.green.shade400),
                  BarChartRodStackItem(lVal, lVal + mVal, Colors.blue.shade400),
                  BarChartRodStackItem(lVal + mVal, lVal + mVal + hVal, Colors.orange.shade400),
                  BarChartRodStackItem(lVal + mVal + hVal, total, Colors.red.shade400),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildReportLineChart(Map<String, dynamic> item) {
    final double currentScore = item['quality_score'];
    final double prevScore = item['prev_quality_score'];
    final double step = (currentScore - prevScore) / 6;

    final today = DateTime.now();
    final List<String> dates = List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      return '${date.day} ${_getMonthName(date.month)}';
    });

    final List<FlSpot> spots = List.generate(7, (i) {
      final baseVal = prevScore + (step * i);
      final val = i == 6 ? currentScore : baseVal + (sin(i) * 1.1);
      return FlSpot(i.toDouble(), double.parse(val.toStringAsFixed(1)));
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < 7) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(dates[idx], style: const TextStyle(color: Colors.black54, fontSize: 8, fontWeight: FontWeight.bold)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: const TextStyle(color: Colors.black45, fontSize: 8.5)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 60,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.green.shade600,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: Colors.green.shade600,
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.shade600.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSavePDF(Map<String, dynamic> item) async {
    final pdf = pw.Document();
    final score = item['quality_score'] as double;
    final totalRec = item['total_records'] as int;
    final totalIssues = item['total_issues'] as int;
    final crit = item['critical_count'] as int;
    final diff = score - (item['prev_quality_score'] as double);

    final int base = max(1, (totalIssues / 5).round());
    final List<double> criticals = [crit.toDouble() / 5, crit.toDouble() / 5, crit.toDouble() / 5, crit.toDouble() / 5, crit.toDouble() / 5];
    final List<double> highs = [base.toDouble() * 1.2, base.toDouble() * 0.8, base.toDouble() * 1.5, base.toDouble() * 0.5, base.toDouble()];
    final List<double> mediums = [base.toDouble() * 0.8, base.toDouble() * 1.2, base.toDouble() * 0.6, base.toDouble() * 1.1, base.toDouble() * 0.9];
    final List<double> lows = [1.0, 1.0, 1.0, 1.0, 1.0];
    final List<String> categories = ['Missing', 'Duplicate', 'Format', 'Outliers', 'Schema'];

    final today = DateTime.now();
    final List<String> dates = List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      return '${date.day} ${_getMonthName(date.month)}';
    });
    final List<double> trendData = List.generate(7, (i) {
      final baseVal = (item['prev_quality_score'] as double) + (score - (item['prev_quality_score'] as double)) / 6 * i;
      return i == 6 ? score : baseVal + (sin(i) * 1.1);
    });

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INSIGHT DATA QUALITY PLATFORM • REPORT',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'LAPORAN DATA QUALITY & PIPELINE',
                        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        item['title'],
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 10),

              // Meta Info Box
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                color: PdfColors.grey100,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Versi: 1.0', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    pw.Text('Sumber: ${item['source']}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    pw.Text('File: ${item['file_name']}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // KPI Row
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.green300), color: PdfColors.green50),
                    child: pw.Column(children: [
                      pw.Text('${score.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                      pw.Text('Avg Quality Score', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    ]),
                  )),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.green300), color: PdfColors.green50),
                    child: pw.Column(children: [
                      pw.Text('${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                      pw.Text('Quality Trend', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    ]),
                  )),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.orange300), color: PdfColors.orange50),
                    child: pw.Column(children: [
                      pw.Text('$totalIssues', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                      pw.Text('Data Issues', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    ]),
                  )),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red300), color: PdfColors.red50),
                    child: pw.Column(children: [
                      pw.Text('$crit', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                      pw.Text('Critical Issues', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    ]),
                  )),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Text('DETAIL DIMENSI KUALITAS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),

              // Table
              pw.Table(
                border: const pw.TableBorder(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
                children: [
                  _buildPdfTableRow('Completeness', '${(score * 0.97).toStringAsFixed(0)}%', 'Lulus (Baik)'),
                  _buildPdfTableRow('Accuracy', '${(score * 0.94).toStringAsFixed(0)}%', 'Lulus (Baik)'),
                  _buildPdfTableRow('Validity', '${(score * 0.95).toStringAsFixed(0)}%', 'Lulus (Baik)'),
                  _buildPdfTableRow('Consistency', '${(score * 0.91).toStringAsFixed(0)}%', 'Lulus (Baik)'),
                  _buildPdfTableRow('Timeliness', '89.9%', 'Perlu Review'),
                  _buildPdfTableRow('Total Records', _formatRecordCount(totalRec), 'Diterima'),
                  _buildPdfTableRow('Valid Records', _formatRecordCount(item['valid_records']), 'Disimpan'),
                ],
              ),
              pw.SizedBox(height: 18),

              pw.Text('GRAFIK ANALISIS PIPELINE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),

              // Render graphics inside PDF
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      height: 120,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey200), color: PdfColors.white),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Data Issues by Category', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 8),
                          pw.Expanded(
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: List.generate(5, (i) {
                                final total = criticals[i] + highs[i] + mediums[i] + lows[i];
                                final maxH = base * 4;
                                final pct = (total / maxH).clamp(0.05, 0.95);
                                return pw.Column(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Container(
                                      width: 12,
                                      height: 60 * pct,
                                      decoration: const pw.BoxDecoration(
                                        color: PdfColors.indigo400,
                                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                                      ),
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Text(categories[i], style: const pw.TextStyle(fontSize: 6)),
                                  ],
                                );
                              }),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  
                  pw.Expanded(
                    child: pw.Container(
                      height: 120,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey200), color: PdfColors.white),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Quality Score Trend', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 8),
                          pw.Expanded(
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: List.generate(7, (i) {
                                final val = trendData[i];
                                final pct = ((val - 60) / 40).clamp(0.1, 0.95);
                                return pw.Column(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Container(
                                      width: 4,
                                      height: 60 * pct,
                                      color: PdfColors.green400,
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Text(dates[i].split(' ').first, style: const pw.TextStyle(fontSize: 6)),
                                  ],
                                );
                              }),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Insight Data Quality Platform 2026', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('Halaman 1 dari 1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    try {
      Directory? downloadsDir;
      if (Platform.isWindows) {
        downloadsDir = await getDownloadsDirectory();
      } else {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      }

      if (downloadsDir == null) {
        throw Exception('Tidak dapat mengakses direktori penyimpanan.');
      }

      final String sanitTitle = item['title'].replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final String filePath = '${downloadsDir.path}/Laporan_Kualitas_$sanitTitle.pdf';
      final file = File(filePath);
      
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF berhasil diunduh ke: $filePath'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  pw.TableRow _buildPdfTableRow(String label, String value, String status) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(status, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: status.contains('Review') ? PdfColors.orange800 : PdfColors.green800)),
        ),
      ],
    );
  }
}
