import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_service.dart';
import 'glass_card.dart';

class SnackEvaluator extends StatefulWidget {
  const SnackEvaluator({Key? key}) : super(key: key);

  @override
  State<SnackEvaluator> createState() => _SnackEvaluatorState();
}

class _SnackEvaluatorState extends State<SnackEvaluator> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController(text: 'Ham & Cheese Sandwich');
  final _caloriesController = TextEditingController(text: '380');
  final _proteinController = TextEditingController(text: '22');
  final _carbsController = TextEditingController(text: '35');
  final _fatController = TextEditingController(text: '14');

  bool _isAnalyzing = false;
  Map<String, dynamic>? _verdict;
  late AnimationController _spinnerController;

  final List<Map<String, dynamic>> _presets = [
    {'emoji': '🥪', 'name': 'Toastie', 'calories': 340, 'protein': 18, 'carbs': 32, 'fat': 12},
    {'emoji': '🍪', 'name': 'Cookie', 'calories': 220, 'protein': 3, 'carbs': 30, 'fat': 10},
    {'emoji': '🥛', 'name': 'Protein Shake', 'calories': 250, 'protein': 35, 'carbs': 15, 'fat': 4},
    {'emoji': '🍫', 'name': 'Snickers', 'calories': 250, 'protein': 4, 'carbs': 33, 'fat': 12},
  ];

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _spinnerController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _nameController.text = "${preset['emoji']} ${preset['name']}";
      _caloriesController.text = preset['calories'].toString();
      _proteinController.text = preset['protein'].toString();
      _carbsController.text = preset['carbs'].toString();
      _fatController.text = preset['fat'].toString();
      _verdict = null;
    });
  }

  void _runAnalysis() {
    final cals = double.tryParse(_caloriesController.text) ?? 0.0;
    final protein = double.tryParse(_proteinController.text) ?? 0.0;
    final fat = double.tryParse(_fatController.text) ?? 0.0;

    final state = Provider.of<StateService>(context, listen: false);
    final remainingCals = state.goals.calories - state.totalConsumedCalories;
    final remainingFat = state.goals.fat - state.totalConsumedFat;
    final remainingProtein = state.goals.protein - state.totalConsumedProtein;

    setState(() {
      _isAnalyzing = true;
      _verdict = null;
    });
    _spinnerController.repeat();

    Timer(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      _spinnerController.stop();

      String status = 'green';
      String text = 'Go Ahead! 🎉';
      String justification = 'Fits comfortably in your remaining daily budget.';

      if (remainingCals < 0) {
        status = 'red';
        text = 'Over Budget Already!';
        justification = 'Already ${remainingCals.abs().round()} kcal over your daily target.';
      } else if (cals > remainingCals) {
        status = 'red';
        text = 'Skip It';
        justification = '${cals.round()} kcal exceeds your ${remainingCals.round()} kcal remaining by ${(cals - remainingCals).round()} kcal.';
      } else if (cals > remainingCals * 0.7) {
        status = 'orange';
        text = 'Maybe Half?';
        justification = 'This uses ${((cals / remainingCals) * 100).round()}% of your remaining budget.';
      } else if (fat > remainingFat * 0.6 || protein > remainingProtein * 0.5) {
        status = 'yellow';
        text = 'Macro Watch';
        justification = 'Calories OK, but heavy on ${fat > remainingFat * 0.6 ? 'fat' : 'protein'}.';
      }

      setState(() {
        _isAnalyzing = false;
        _verdict = {
          'status': status,
          'text': text,
          'justification': justification,
        };
      });
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'red':
        return const Color(0xffef4444);
      case 'orange':
        return const Color(0xfff97316);
      case 'yellow':
        return const Color(0xffeab308);
      default:
        return const Color(0xff10b981);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'red':
        return const Color(0xff7f1d1d).withOpacity(0.2);
      case 'orange':
        return const Color(0xff7c2d12).withOpacity(0.2);
      case 'yellow':
        return const Color(0xff713f12).withOpacity(0.2);
      default:
        return const Color(0xff064e3b).withOpacity(0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance, size: 16, color: isDark ? Colors.orange.shade400 : Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text(
                'Snack Budget Evaluator',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Check a snack against your remaining daily budget.',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.zinc.shade500 : Colors.grey.shade600),
          ),
          const SizedBox(height: 12),

          // Item Name
          Row(
            children: [
              SizedBox(
                width: 45,
                child: Text(
                  'Item',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.zinc.shade400 : Colors.grey.shade700),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      filled: true,
                      fillColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Numeric Fields
          Row(
            children: [
              _buildField('Cal', _caloriesController),
              const SizedBox(width: 6),
              _buildField('Prot', _proteinController),
              const SizedBox(width: 6),
              _buildField('Carb', _carbsController),
              const SizedBox(width: 6),
              _buildField('Fat', _fatController),
            ],
          ),
          const SizedBox(height: 12),

          // Preset Buttons
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _presets.map((preset) {
              return InkWell(
                onTap: () => _applyPreset(preset),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xff171720) : Colors.grey.shade100,
                    border: Border.all(
                      color: isDark ? const Color(0xff242436) : Colors.grey.shade200,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${preset['emoji']} ${preset['name']}",
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.zinc.shade400 : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Verdict & Actions
          if (_isAnalyzing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff6366f1).withOpacity(0.05),
                border: Border.all(color: const Color(0xff6366f1).withOpacity(0.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RotationTransition(
                    turns: _spinnerController,
                    child: Icon(Icons.sync, size: 24, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RUNNING BUDGET CHECK...',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade600,
                    ),
                  )
                ],
              ),
            )
          else if (_verdict != null)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.elasticOut,
              builder: (context, val, child) {
                return Transform.scale(
                  scale: val,
                  child: child,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(_verdict!['status']),
                  border: Border.all(
                    color: _getStatusColor(_verdict!['status']).withOpacity(0.35),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(_verdict!['status']),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _verdict!['text'].toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(_verdict!['status']),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _verdict!['justification'],
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.zinc.shade300 : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setState(() => _verdict = null),
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                          color: isDark ? Colors.zinc.shade500 : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: _runAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xff1e1e2c) : Colors.grey.shade100,
                foregroundColor: isDark ? Colors.zinc.shade300 : Colors.grey.shade800,
                shadowColor: Colors.transparent,
                elevation: 0,
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? const Color(0xff2b2b3f) : Colors.grey.shade300,
                  ),
                ),
              ),
              child: const Text('Quick Analyze', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            )
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9.5, color: isDark ? Colors.zinc.shade500 : Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 32,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
