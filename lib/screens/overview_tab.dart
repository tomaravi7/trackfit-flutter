import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_service.dart';
import '../models/weight_log.dart';
import '../widgets/calorie_ring.dart';
import '../widgets/glass_card.dart';
import '../widgets/water_wave.dart';
import '../widgets/snack_evaluator.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({Key? key}) : super(key: key);

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<StateService>(context);

    final double remainingCals = (state.goals.calories - state.totalConsumedCalories).clamp(0.0, double.infinity);
    final weightLog = state.weightLog;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Layout grid for Calorie Ring and Macros
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCalorieRingCard(context, state, remainingCals)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMacrosCard(context, state)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildCalorieRingCard(context, state, remainingCals),
                    const SizedBox(height: 12),
                    _buildMacrosCard(context, state),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 12),

          // Layout grid for Water and Weight Cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildWaterCard(context, state)),
              const SizedBox(width: 12),
              Expanded(child: _buildWeightCard(context, state, weightLog)),
            ],
          ),
          const SizedBox(height: 12),

          // Snack Budget Evaluator
          const SnackEvaluator(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCalorieRingCard(BuildContext context, StateService state, double remaining) {
    return GlassCard(
      child: Column(
        children: [
          CalorieRing(
            current: state.totalConsumedCalories,
            target: state.goals.calories,
            remaining: remaining,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border.fromBorderSide(BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.05),
              )),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xff10b981), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('Consumed', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${state.totalConsumedCalories.round()} kcal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xff6366f1), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('Sets today', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${state.workoutLogs.length} sets', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosCard(BuildContext context, StateService state) {
    final macros = [
      {'label': 'Protein', 'value': state.totalConsumedProtein, 'goal': state.goals.protein, 'color': const Color(0xfff97316)}, // orange
      {'label': 'Carbs', 'value': state.totalConsumedCarbs, 'goal': state.goals.carbs, 'color': const Color(0xff6366f1)},   // indigo
      {'label': 'Fiber', 'value': state.totalConsumedFiber, 'goal': state.goals.fiber, 'color': const Color(0xff14b8a6)},   // teal
      {'label': 'Fat', 'value': state.totalConsumedFat, 'goal': state.goals.fat, 'color': const Color(0xffeab308)},       // yellow
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, size: 16, color: Colors.indigo.shade400),
              const SizedBox(width: 8),
              const Text('Daily Macros', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: macros.map((m) {
              final double pVal = (m['value'] as double);
              final double pGoal = (m['goal'] as double);
              final percentage = pGoal > 0 ? (pVal / pGoal) : 0.0;
              final color = m['color'] as Color;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(m['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text(
                          '${pVal.round()}g / ${pGoal.round()}g',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 6,
                        width: double.infinity,
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xff181822) : Colors.grey.shade100,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: percentage.clamp(0.0, 1.0),
                            child: Container(color: color),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard(BuildContext context, StateService state) {
    final double waterGoalL = state.waterGoalMl / 1000.0;
    final double currentWaterL = state.totalWaterMl / 1000.0;
    final double pct = state.waterGoalMl > 0 ? (state.totalWaterMl / state.waterGoalMl) : 0.0;
    final isDark = state.isDark;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, size: 16, color: Colors.lightBlue.shade400),
              const SizedBox(width: 6),
              const Text('Water', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${currentWaterL.toStringAsFixed(1)}L',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.lightBlue.shade300),
          ),
          Text(
            'of ${waterGoalL.toStringAsFixed(1)}L',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          WaterWave(percentage: pct),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [250, 500, 1000].map((ml) {
              return ElevatedButton(
                onPressed: () => state.logWater(ml),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xff0c2135) : Colors.lightBlue.shade50,
                  foregroundColor: isDark ? const Color(0xff7dd3fc) : Colors.lightBlue.shade800,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(0, 26),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: isDark ? const Color(0xff0369a1).withOpacity(0.4) : Colors.lightBlue.shade200),
                  ),
                ),
                child: Text('+$ml', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightCard(BuildContext context, StateService state, WeightLog? log) {
    final isDark = state.isDark;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_weight, size: 16, color: Colors.purple.shade400),
                  const SizedBox(width: 6),
                  const Text('Weight', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              if (log != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (log.id != null) {
                      state.deleteWeight(log.id!);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (log != null) ...[
            Text(
              '${log.weight} ${state.weightUnit}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.purple.shade300),
            ),
            Text(
              'logged today',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
            ),
            if (log.bodyFat != null)
              Text(
                'Body Fat: ${log.bodyFat}%',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            const SizedBox(height: 8),
            // Weight shift indicator
            if (state.weightHistory.length >= 2) ...[
              () {
                final prev = state.weightHistory[state.weightHistory.length - 2].weight;
                final diff = log.weight - prev;
                return Text(
                  "${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} ${state.weightUnit}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: diff > 0 ? Colors.orange : Colors.green,
                  ),
                );
              }()
            ]
          ] else ...[
            SizedBox(
              height: 28,
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 11),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  hintText: 'Weight (${state.weightUnit})',
                  filled: true,
                  fillColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 28,
              child: TextField(
                controller: _bodyFatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 11),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  hintText: 'Fat % (optional)',
                  filled: true,
                  fillColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: () {
                final w = double.tryParse(_weightController.text);
                final f = double.tryParse(_bodyFatController.text);
                if (w != null) {
                  state.logWeight(w, f);
                  _weightController.clear();
                  _bodyFatController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xff2e1c45) : Colors.purple.shade50,
                foregroundColor: isDark ? const Color(0xffc084fc) : Colors.purple.shade800,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: isDark ? const Color(0xff6b21a8).withOpacity(0.4) : Colors.purple.shade200),
                ),
              ),
              child: const Text('Log Weight', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}
