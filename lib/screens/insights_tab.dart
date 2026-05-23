import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/state_service.dart';
import '../models/weight_log.dart';
import '../widgets/glass_card.dart';
import '../widgets/body_heatmap.dart';

class InsightsTab extends StatefulWidget {
  const InsightsTab({Key? key}) : super(key: key);

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  String _activeSubTab = 'calories'; // 'calories', 'weight', 'water', 'workouts', 'body'
  String _timeFrame = '7d'; // '7d', '30d'

  Color _getSubTabColor(String tab, String active) {
    if (tab == active) return const Color(0xff4f46e5);
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<StateService>(context);
    final isDark = state.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-tabs Selection bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubTabButton('Calories', 'calories'),
                _buildSubTabButton('Weight', 'weight'),
                _buildSubTabButton('Water', 'water'),
                _buildSubTabButton('Workouts', 'workouts'),
                _buildSubTabButton('Body Heatmap', 'body'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Trend View based on selected sub-tab
          if (_activeSubTab == 'calories')
            _buildCalorieTrends(context, state)
          else if (_activeSubTab == 'weight')
            _buildWeightTrends(context, state)
          else if (_activeSubTab == 'water')
            _buildWaterTrends(context, state)
          else if (_activeSubTab == 'workouts')
            _buildWorkoutTrends(context, state)
          else if (_activeSubTab == 'body')
            _buildBodyHeatmapTab(context, state),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String label, String value) {
    final active = _activeSubTab == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        onTap: () => setState(() => _activeSubTab = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active 
                ? const Color(0xff4f46e5) 
                : (isDark ? const Color(0xff151520).withOpacity(0.4) : Colors.grey.shade100),
            border: Border.all(
              color: active ? const Color(0xff4f46e5) : (isDark ? const Color(0xff212130) : Colors.grey.shade200),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }

  // ─── CALORIE TRENDS ────────────────────────────────────────────────────────
  Widget _buildCalorieTrends(BuildContext context, StateService state) {
    final isDark = state.isDark;
    
    // We mock history if empty or build list
    final List<FlSpot> spots = [
      const FlSpot(0, 1850),
      const FlSpot(1, 2100),
      const FlSpot(2, 1950),
      const FlSpot(3, 1720),
      const FlSpot(4, 2200),
      const FlSpot(5, 1890),
      FlSpot(6, state.totalConsumedCalories),
    ];

    return Column(
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: GlassCard(
                child: Column(
                  children: [
                    const Text('AVG INTAKE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('1,958 kcal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassCard(
                child: Column(
                  children: [
                    const Text('TARGET', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${state.goals.calories.round()} kcal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff818cf8))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Line Chart Card
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daily Calories Intake', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xff10b981),
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xff10b981).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── WEIGHT TRENDS ─────────────────────────────────────────────────────────
  Widget _buildWeightTrends(BuildContext context, StateService state) {
    final isDark = state.isDark;
    
    // Convert history logs to chart spots
    final List<FlSpot> spots = [];
    final List<WeightLog> hist = state.weightHistory;
    
    if (hist.isEmpty) {
      spots.addAll([
        const FlSpot(0, 76.5),
        const FlSpot(1, 76.2),
        const FlSpot(2, 75.9),
        const FlSpot(3, 75.4),
      ]);
    } else {
      for (int i = 0; i < hist.length; i++) {
        spots.add(FlSpot(i.toDouble(), hist[i].weight));
      }
    }

    final double currentW = hist.isNotEmpty ? hist.last.weight : 75.4;
    final double minW = hist.isNotEmpty ? hist.map((e) => e.weight).reduce(min) : 75.4;
    final double maxW = hist.isNotEmpty ? hist.map((e) => e.weight).reduce(max) : 76.5;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassCard(
                child: Column(
                  children: [
                    const Text('CURRENT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${currentW.toStringAsFixed(1)} ${state.weightUnit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GlassCard(
                child: Column(
                  children: [
                    const Text('LOW', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${minW.toStringAsFixed(1)} ${state.weightUnit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GlassCard(
                child: Column(
                  children: [
                    const Text('HIGH', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${maxW.toStringAsFixed(1)} ${state.weightUnit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Weight chart card
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weight Trend (${state.weightUnit})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xffa78bfa), // violet-400
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xffa78bfa).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── WATER TRENDS ──────────────────────────────────────────────────────────
  Widget _buildWaterTrends(BuildContext context, StateService state) {
    final isDark = state.isDark;
    
    // Bar chart points
    final List<BarChartGroupData> barGroups = [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 2000, color: Colors.lightBlue, width: 14, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 2500, color: Colors.lightBlue, width: 14, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 1800, color: Colors.lightBlue, width: 14, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 2200, color: Colors.lightBlue, width: 14, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 3000, color: Colors.lightBlue, width: 14, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 2400, color: Colors.lightBlue, width: 14, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: state.totalWaterMl.toDouble(), color: Colors.lightBlue, width: 14, borderRadius: BorderRadius.circular(4))]),
    ];

    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hydration Trend (ml)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: barGroups,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── WORKOUT TRENDS ────────────────────────────────────────────────────────
  Widget _buildWorkoutTrends(BuildContext context, StateService state) {
    final isDark = state.isDark;

    // Filter exercises logs or display session indicators
    final allWorkoutLogs = state.allWorkoutSetsHistory;
    final Map<String, int> muscleFrequencies = {};

    for (var l in allWorkoutLogs) {
      for (var mg in muscleGroups) {
        if (mg.exerciseNames.any((ex) => l.exerciseName.toLowerCase().contains(ex))) {
          muscleFrequencies[mg.name] = (muscleFrequencies[mg.name] ?? 0) + 1;
        }
      }
    }

    final freqList = muscleFrequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Targeted Muscles Frequencies', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (freqList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No workouts logged in history yet.',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? Colors.grey.shade600 : Colors.grey.shade500),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: min(5, freqList.length),
                  separatorBuilder: (context, idx) => Divider(height: 1.0, color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                  itemBuilder: (context, idx) {
                    final item = freqList[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(
                            '${item.value} sets',
                            style: const TextStyle(fontSize: 11, color: Color(0xff818cf8), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── BODY HEATMAP VIEW ─────────────────────────────────────────────────────
  Widget _buildBodyHeatmapTab(BuildContext context, StateService state) {
    return BodyHeatmap(workoutLogs: state.allWorkoutSetsHistory);
  }
}
