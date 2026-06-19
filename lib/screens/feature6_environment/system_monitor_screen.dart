import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/constants.dart';

class SystemMonitorScreen extends StatefulWidget {
  const SystemMonitorScreen({super.key});

  @override
  State<SystemMonitorScreen> createState() => _SystemMonitorScreenState();
}

class _SystemMonitorScreenState extends State<SystemMonitorScreen> {
  late Timer _timer;
  
  // Real-time resource data lists
  List<double> _cpuHistory = List.generate(15, (index) => 10 + Random().nextDouble() * 10);
  List<double> _ramHistory = List.generate(15, (index) => 80 + Random().nextDouble() * 5);
  List<double> _netHistory = List.generate(12, (index) => 50 + Random().nextDouble() * 100);

  double _cpuUsed = 14.0;
  double _ramUsed = 82.0;
  double _diskUsed = 22.0;
  double _netIn = 100.0;
  double _netOut = 49.0;

  // Disk partitions
  double _sda1 = 71.0;
  double _sdb1 = 53.0;
  double _sdc1 = 12.0;

  String _uptime = '1d 1h';
  late DateTime _startTime;
  String _timeStr = '00:00:00';

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _timeStr = _formatTime(DateTime.now());

    _timer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted) return;

      final random = Random();
      
      // Update values
      final double newCpu = 10 + random.nextDouble() * 15;
      final double newRam = 80 + random.nextDouble() * 4;
      final double newNetIn = 50 + random.nextDouble() * 100;
      final double newNetOut = 20 + random.nextDouble() * 30;

      // Update history lists
      _cpuHistory.removeAt(0);
      _cpuHistory.add(newCpu);

      _ramHistory.removeAt(0);
      _ramHistory.add(newRam);

      _netHistory.removeAt(0);
      _netHistory.add(newNetIn);

      // Randomize partition sizes slightly
      _sda1 = (71.0 + (random.nextDouble() * 2 - 1)).clamp(68.0, 74.0);
      _sdb1 = (53.0 + (random.nextDouble() * 2 - 1)).clamp(50.0, 56.0);
      _sdc1 = (12.0 + (random.nextDouble() * 0.4 - 0.2)).clamp(11.0, 13.0);

      setState(() {
        _cpuUsed = newCpu;
        _ramUsed = newRam;
        _netIn = newNetIn;
        _netOut = newNetOut;
        _timeStr = _formatTime(DateTime.now());
      });
    });
  }

  String _formatTime(DateTime dt) {
    String h = dt.hour.toString().padLeft(2, '0');
    String m = dt.minute.toString().padLeft(2, '0');
    String s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('System Monitor (Prototype 1)'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('LIVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server metadata header card
            _buildMetaHeaderCard(),
            const SizedBox(height: 16),

            // CPU, Memory, Disk Donut Grid
            Row(
              children: [
                _buildDonutCard('🖥️ CPU Usage', _cpuUsed, '#3b82f6', Colors.blue, '24 Cores'),
                const SizedBox(width: 8),
                _buildDonutCard('🖨️ Memory', _ramUsed, '#a855f7', Colors.purple, '${(_ramUsed / 100 * 32).toStringAsFixed(1)} / 32 GB'),
                const SizedBox(width: 8),
                _buildDonutCard('⏱️ Disk', _diskUsed, '#eab308', Colors.amber, '110 / 500 GB'),
              ],
            ),
            const SizedBox(height: 16),

            // Real-time Resource Monitor Line Chart
            _buildRealtimeResourceChart(),
            const SizedBox(height: 16),

            // Row for Network I/O and Disk Breakdown
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildNetworkThroughputChart()),
                const SizedBox(width: 12),
                Expanded(child: _buildDiskBreakdownCard()),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Linux Server', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(_timeStr, style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'monospace', fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetaText('Host', 'dev-server-01'),
              _buildMetaText('OS', 'Ubuntu 22.04'),
              _buildMetaText('Uptime', _uptime),
              _buildMetaText('Status', 'Healthy', color: Colors.green),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMetaText(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color ?? AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDonutCard(String title, double usedPercent, String colorHex, Color color, String footerVal) {
    return Expanded(
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            SizedBox(
              width: 65,
              height: 65,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 26,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          value: usedPercent,
                          color: color,
                          radius: 6,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: 100 - usedPercent,
                          color: Colors.white.withValues(alpha: 0.05),
                          radius: 6,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${usedPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              footerVal,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeResourceChart() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Real-time Resource Monitor', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('CPU & RAM utilization — live stream', style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
                ],
              ),
              Row(
                children: [
                  _buildChartLegendItem('CPU', Colors.blue),
                  const SizedBox(width: 10),
                  _buildChartLegendItem('RAM', Colors.purple),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.03), strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index == 0) return const Text('-14s', style: TextStyle(color: AppColors.textMuted, fontSize: 9));
                        if (index == 7) return const Text('-7s', style: TextStyle(color: AppColors.textMuted, fontSize: 9));
                        if (index == 14) return const Text('now', style: TextStyle(color: AppColors.textMuted, fontSize: 9));
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
                maxX: 14,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(15, (i) => FlSpot(i.toDouble(), _cpuHistory[i])),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: List.generate(15, (i) => FlSpot(i.toDouble(), _ramHistory[i])),
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String name, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(name, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
      ],
    );
  }

  Widget _buildNetworkThroughputChart() {
    return Container(
      height: 195,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('▲ Network Throughput', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '↓ In: ${_netIn.toStringAsFixed(0)} MB/s   ↑ Out: ${_netOut.toStringAsFixed(0)} MB/s',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 11,
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(12, (i) => FlSpot(i.toDouble(), _netHistory[i])),
                    isCurved: true,
                    color: Colors.cyan,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.cyan.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiskBreakdownCard() {
    return Container(
      height: 195,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('▢ Disk Breakdown', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDiskItem('/dev/sda1 (root)', _sda1, Colors.amber),
          const SizedBox(height: 8),
          _buildDiskItem('/dev/sdb1 (data)', _sdb1, Colors.blue),
          const SizedBox(height: 8),
          _buildDiskItem('/dev/sdc1 (backup)', _sdc1, Colors.green),
        ],
      ),
    );
  }

  Widget _buildDiskItem(String name, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5)),
            Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
