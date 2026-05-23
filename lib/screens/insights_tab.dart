import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/state_service.dart';
import '../models/weight_log.dart';
import '../models/food_log.dart';
import '../models/water_log.dart';
import '../models/workout_log.dart';
import '../widgets/glass_card.dart';
import '../widgets/body_heatmap.dart';

class InsightsTab extends StatefulWidget {
  const InsightsTab({Key? key}) : super(key: key);

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  String _activeSubTab = 'calories'; // 'calories', 'weight', 'water', 'workouts', 'calendar', 'body'
  String _timeFrame = '7d'; // '7d', '14d', '30d'

  // Consistency Calendar navigation month/year
  int _calendarYear = DateTime.now().year;
  int _calendarMonth = DateTime.now().month;

  void _prevMonth() {
    setState(() {
      if (_calendarMonth == 1) {
        _calendarMonth = 12;
        _calendarYear--;
      } else {
        _calendarMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_calendarMonth == 12) {
        _calendarMonth = 1;
        _calendarYear++;
      } else {
        _calendarMonth++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<StateService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive Sub-tabs + Timeframe Selector
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final subTabs = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSubTabButton('Calories', 'calories'),
                    _buildSubTabButton('Weight', 'weight'),
                    _buildSubTabButton('Water', 'water'),
                    _buildSubTabButton('Consistency', 'calendar'),
                    _buildSubTabButton('Workouts', 'workouts'),
                    _buildSubTabButton('Body Heatmap', 'body'),
                  ],
                ),
              );
              
              if (_activeSubTab == 'body' || _activeSubTab == 'calendar') {
                return subTabs;
              }

              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: subTabs),
                    const SizedBox(width: 8),
                    _buildTimeFrameSelector(),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    subTabs,
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildTimeFrameSelector(),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Main Trend View based on selected sub-tab
          if (_activeSubTab == 'calories')
            _buildCalorieTrends(context, state)
          else if (_activeSubTab == 'weight')
            _buildWeightTrends(context, state)
          else if (_activeSubTab == 'water')
            _buildWaterTrends(context, state)
          else if (_activeSubTab == 'calendar')
            _buildConsistencyCalendar(context, state)
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildTimeFrameSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['7d', '14d', '30d'].map((tf) {
        final active = _timeFrame == tf;
        return Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: InkWell(
            onTap: () => setState(() => _timeFrame = tf),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: active 
                    ? const Color(0xff4f46e5).withOpacity(0.12)
                    : Colors.transparent,
                border: Border.all(
                  color: active ? const Color(0xff4f46e5) : (isDark ? const Color(0xff212130) : Colors.grey.shade300),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tf.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: active ? const Color(0xff818cf8) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getCalorieChartData(StateService state) {
    final List<Map<String, dynamic>> list = [];
    final int days = _timeFrame == '7d' ? 7 : (_timeFrame == '14d' ? 14 : 30);
    final now = DateTime.now();
    
    for (int i = days - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dateString = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      
      double dayCals = state.foodHistory
          .where((f) => f.date == dateString)
          .fold(0.0, (sum, f) => sum + f.calories);
      if (dateString == state.activeDate && dayCals == 0) {
        dayCals = state.totalConsumedCalories;
      }
          
      list.add({
        'index': (days - 1 - i).toDouble(),
        'date': dateString,
        'label': "${d.day}/${d.month}",
        'calories': dayCals,
      });
    }
    return list;
  }

  List<Map<String, dynamic>> _getWeightChartData(StateService state) {
    final List<Map<String, dynamic>> list = [];
    final int days = _timeFrame == '7d' ? 7 : (_timeFrame == '14d' ? 14 : 30);
    final now = DateTime.now();
    
    for (int i = days - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dateString = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      
      final log = state.weightHistory.firstWhere(
        (w) => w.date == dateString,
        orElse: () => WeightLog(date: dateString, weight: 0.0),
      );
      
      double w = log.weight;
      if (dateString == state.activeDate && w == 0.0 && state.weightLog != null) {
        w = state.weightLog!.weight;
      }
      
      list.add({
        'index': (days - 1 - i).toDouble(),
        'date': dateString,
        'label': "${d.day}/${d.month}",
        'weight': w,
      });
    }
    
    double lastValidWeight = 75.0;
    final firstValid = state.weightHistory.firstWhere((element) => element.weight > 0, orElse: () => WeightLog(date: '', weight: 75.0));
    lastValidWeight = firstValid.weight;
    
    for (int i = 0; i < list.length; i++) {
      if (list[i]['weight'] == 0.0) {
        list[i]['weight'] = lastValidWeight;
      } else {
        lastValidWeight = list[i]['weight'];
      }
    }
    return list;
  }

  List<Map<String, dynamic>> _getWaterChartData(StateService state) {
    final List<Map<String, dynamic>> list = [];
    final int days = _timeFrame == '7d' ? 7 : (_timeFrame == '14d' ? 14 : 30);
    final now = DateTime.now();
    
    for (int i = days - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dateString = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      
      double dayWater = state.waterHistory
          .where((w) => w.date == dateString)
          .fold(0.0, (sum, w) => sum + w.amount).toDouble();
      if (dateString == state.activeDate && dayWater == 0) {
        dayWater = state.totalWaterMl.toDouble();
      }
          
      list.add({
        'index': (days - 1 - i).toDouble(),
        'date': dateString,
        'label': "${d.day}/${d.month}",
        'amount': dayWater,
      });
    }
    return list;
  }

  // ─── CALORIE TRENDS ────────────────────────────────────────────────────────
  Widget _buildCalorieTrends(BuildContext context, StateService state) {
    final isDark = state.isDark;
    final chartData = _getCalorieChartData(state);
    
    final List<FlSpot> spots = [];
    for (var data in chartData) {
      spots.add(FlSpot(data['index'], data['calories']));
    }

    if (spots.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final double avgCals = chartData.isNotEmpty
        ? chartData.map((d) => d['calories'] as double).reduce((a, b) => a + b) / chartData.length
        : 0.0;
    final double maxCals = chartData.isNotEmpty
        ? chartData.map((d) => d['calories'] as double).reduce(max)
        : 0.0;

    final double maxVal = spots.isNotEmpty ? spots.map((s) => s.y).reduce(max) : 0;
    final double maxYVal = max(maxVal, state.goals.calories) * 1.15;

    final barChartBarData = LineChartBarData(
      spots: spots,
      isCurved: true,
      color: const Color(0xff10b981),
      barWidth: 3,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: const Color(0xff10b981).withOpacity(0.08),
      ),
    );

    final List<ShowingTooltipIndicators> showingTooltips = [
      ShowingTooltipIndicators([
        LineBarSpot(barChartBarData, 0, spots.last),
      ])
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassCard(
                child: Column(
                  children: [
                    const Text('AVG INTAKE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${avgCals.round()} kcal', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassCard(
                child: Column(
                  children: [
                    const Text('PEAK', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${maxCals.round()} kcal', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                    Text('${state.goals.calories.round()} kcal', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff818cf8))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daily Calories Intake', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxYVal,
                    showingTooltipIndicators: showingTooltips,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) => const Color(0xff10b981).withOpacity(0.9),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.round()} kcal',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final int idx = val.toInt();
                            if (idx >= 0 && idx < chartData.length) {
                              if (chartData.length <= 7 || idx == 0 || idx == chartData.length - 1 || idx == chartData.length ~/ 2) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    chartData[idx]['label'],
                                    style: TextStyle(fontSize: 8, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: state.goals.calories,
                          color: const Color(0xff818cf8).withOpacity(0.5),
                          strokeWidth: 1.5,
                          dashArray: [5, 5],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 8, bottom: 2),
                            style: const TextStyle(
                              color: Color(0xff818cf8),
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                            labelResolver: (line) => 'Goal: ${line.y.round()} kcal',
                          ),
                        ),
                      ],
                    ),
                    lineBarsData: [barChartBarData],
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
    final chartData = _getWeightChartData(state);
    
    final List<FlSpot> spots = [];
    for (var data in chartData) {
      spots.add(FlSpot(data['index'], data['weight']));
    }

    if (spots.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final double avgWeight = chartData.isNotEmpty
        ? chartData.map((d) => d['weight'] as double).reduce((a, b) => a + b) / chartData.length
        : 0.0;
    final double minWeight = chartData.isNotEmpty
        ? chartData.map((d) => d['weight'] as double).reduce(min)
        : 0.0;
    final double maxWeight = chartData.isNotEmpty
        ? chartData.map((d) => d['weight'] as double).reduce(max)
        : 0.0;

    final double minVal = spots.isNotEmpty ? spots.map((s) => s.y).reduce(min) : 50;
    final double maxVal = spots.isNotEmpty ? spots.map((s) => s.y).reduce(max) : 100;
    final double minYVal = max(0.0, minVal - 2);
    final double maxYVal = maxVal + 2;

    final barChartBarData = LineChartBarData(
      spots: spots,
      isCurved: true,
      color: const Color(0xffa78bfa),
      barWidth: 3,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: const Color(0xffa78bfa).withOpacity(0.08),
      ),
    );

    final List<ShowingTooltipIndicators> showingTooltips = [
      ShowingTooltipIndicators([
        LineBarSpot(barChartBarData, 0, spots.last),
      ])
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassCard(
                child: Column(
                  children: [
                    const Text('AVG WEIGHT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${avgWeight.toStringAsFixed(1)} ${state.weightUnit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassCard(
                child: Column(
                  children: [
                    const Text('LOWEST', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${minWeight.toStringAsFixed(1)} ${state.weightUnit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassCard(
                child: Column(
                  children: [
                    const Text('HIGHEST', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${maxWeight.toStringAsFixed(1)} ${state.weightUnit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weight Trend (${state.weightUnit})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: minYVal,
                    maxY: maxYVal,
                    showingTooltipIndicators: showingTooltips,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) => const Color(0xffa78bfa).withOpacity(0.9),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)} ${state.weightUnit}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final int idx = val.toInt();
                            if (idx >= 0 && idx < chartData.length) {
                              if (chartData.length <= 7 || idx == 0 || idx == chartData.length - 1 || idx == chartData.length ~/ 2) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    chartData[idx]['label'],
                                    style: TextStyle(fontSize: 8, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [barChartBarData],
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
    final chartData = _getWaterChartData(state);
    
    final List<FlSpot> spots = [];
    for (var data in chartData) {
      spots.add(FlSpot(data['index'], data['amount']));
    }

    if (spots.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final double avgWater = chartData.isNotEmpty
        ? chartData.map((d) => d['amount'] as double).reduce((a, b) => a + b) / chartData.length
        : 0.0;
    final double maxWater = chartData.isNotEmpty
        ? chartData.map((d) => d['amount'] as double).reduce(max)
        : 0.0;

    final double maxVal = spots.isNotEmpty ? spots.map((s) => s.y).reduce(max) : 0;
    final double maxYVal = max(maxVal, state.waterGoalMl.toDouble()) * 1.15;

    final barChartBarData = LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.lightBlue,
      barWidth: 3,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: Colors.lightBlue.withOpacity(0.08),
      ),
    );

    final List<ShowingTooltipIndicators> showingTooltips = [
      ShowingTooltipIndicators([
        LineBarSpot(barChartBarData, 0, spots.last),
      ])
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassCard(
                child: Column(
                  children: [
                    const Text('AVG HYDRATION', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${avgWater.round()} ml', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassCard(
                child: Column(
                  children: [
                    const Text('PEAK', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${maxWater.round()} ml', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                    Text('${state.waterGoalMl} ml', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.lightBlue)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hydration Trend', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxYVal,
                    showingTooltipIndicators: showingTooltips,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) => Colors.lightBlue.withOpacity(0.9),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.round()} ml',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final int idx = val.toInt();
                            if (idx >= 0 && idx < chartData.length) {
                              if (chartData.length <= 7 || idx == 0 || idx == chartData.length - 1 || idx == chartData.length ~/ 2) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    chartData[idx]['label'],
                                    style: TextStyle(fontSize: 8, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: state.waterGoalMl.toDouble(),
                          color: Colors.lightBlue.withOpacity(0.5),
                          strokeWidth: 1.5,
                          dashArray: [5, 5],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 8, bottom: 2),
                            style: const TextStyle(
                              color: Colors.lightBlue,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                            labelResolver: (line) => 'Goal: ${line.y.round()} ml',
                          ),
                        ),
                      ],
                    ),
                    lineBarsData: [barChartBarData],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── CONSISTENCY CALENDAR ──────────────────────────────────────────────────
  Widget _buildConsistencyCalendar(BuildContext context, StateService state) {
    final isDark = state.isDark;
    
    final DateTime firstDayOfMonth = DateTime(_calendarYear, _calendarMonth, 1);
    final String monthName = DateFormat('MMMM yyyy').format(firstDayOfMonth);
    
    final int firstDayWeekday = firstDayOfMonth.weekday;
    final int prefixNulls = firstDayWeekday == 7 ? 0 : firstDayWeekday; // Sun is 7 in Dart, which should have 0 prefix nulls. Mon is 1 -> offset 1
    
    final int totalDays = DateTime(_calendarYear, _calendarMonth + 1, 0).day;
    
    final List<DateTime?> cells = [];
    for (int i = 0; i < prefixNulls; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= totalDays; d++) {
      cells.add(DateTime(_calendarYear, _calendarMonth, d));
    }
    
    return Column(
      children: [
        GlassCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 14, color: isDark ? Colors.white70 : Colors.black87),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    monthName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white70 : Colors.black87),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('🍏 Diet Goal'),
                  const SizedBox(width: 16),
                  _buildLegendItem('💧 Water Goal'),
                  const SizedBox(width: 16),
                  _buildLegendItem('🏋️ Workout'),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1.0, color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.95,
                ),
                itemCount: cells.length,
                itemBuilder: (context, idx) {
                  final dt = cells[idx];
                  if (dt == null) return const SizedBox.shrink();
                  
                  final dateStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
                  final isSelected = dateStr == state.activeDate;
                  final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;
                  
                  final dayFoodLogs = state.foodHistory.where((f) => f.date == dateStr);
                  final dayCals = dayFoodLogs.fold(0.0, (sum, f) => sum + f.calories);
                  final hasDiet = dayCals > 0 && dayCals <= state.goals.calories;
                  
                  final dayWaterLogs = state.waterHistory.where((w) => w.date == dateStr);
                  final dayWater = dayWaterLogs.fold(0, (sum, w) => sum + w.amount);
                  final hasWater = dayWater >= state.waterGoalMl;
                  
                  final dayWorkoutSets = state.allWorkoutSetsHistory.where((w) => w.date == dateStr).length;
                  final hasSession = state.workoutSessionsHistory.any((s) => s.date == dateStr);
                  final hasWorkout = dayWorkoutSets > 0 || hasSession;

                  return InkWell(
                    onTap: () => state.setSpecificDate(dt),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xff4f46e5).withOpacity(0.12)
                            : (isToday 
                                ? (isDark ? const Color(0xff1e1e2d) : Colors.grey.shade200)
                                : Colors.transparent),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xff4f46e5)
                              : (isToday 
                                  ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400)
                                  : Colors.transparent),
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dt.day.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                              color: isSelected 
                                  ? const Color(0xff818cf8)
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hasDiet) const Text('🍏', style: TextStyle(fontSize: 6.5)),
                              if (hasWater) const Text('💧', style: TextStyle(fontSize: 6.5)),
                              if (hasWorkout) const Text('🏋️', style: TextStyle(fontSize: 6.5)),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildLegendItem(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
    );
  }

  // ─── WORKOUT TRENDS ────────────────────────────────────────────────────────
  Widget _buildWorkoutTrends(BuildContext context, StateService state) {
    final isDark = state.isDark;

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
