import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_service.dart';
import '../models/workout_log.dart';
import '../widgets/glass_card.dart';

class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({Key? key}) : super(key: key);

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  final _exerciseSearchController = TextEditingController();
  final _weightController = TextEditingController(text: '60');
  final _repsController = TextEditingController(text: '10');
  
  // Stopwatch Rest Timer States
  Timer? _stopwatchTimer;
  int _secondsElapsed = 0;
  bool _timerRunning = false;

  final List<String> _commonExercises = [
    'Bench Press', 'Squats', 'Deadlift', 'Overhead Press', 'Barbell Row',
    'Bicep Curls', 'Tricep Pushdowns', 'Lateral Raises', 'Pull-ups', 'Leg Press'
  ];

  @override
  void dispose() {
    _exerciseSearchController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    _stopwatchTimer?.cancel();
    super.dispose();
  }

  // Rest Timer Controller methods
  void _toggleTimer() {
    if (_timerRunning) {
      _stopwatchTimer?.cancel();
      setState(() => _timerRunning = false);
    } else {
      setState(() => _timerRunning = true);
      _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _secondsElapsed++);
      });
    }
  }

  void _resetTimer() {
    _stopwatchTimer?.cancel();
    setState(() {
      _secondsElapsed = 0;
      _timerRunning = false;
    });
  }

  String _formatTimer(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  void _showLogSetDialog(StateService state) {
    String selectedExercise = _commonExercises.first;
    final isDark = state.isDark;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xff121219) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Log Exercise Set', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedExercise,
                    dropdownColor: isDark ? const Color(0xff121219) : Colors.white,
                    decoration: const InputDecoration(labelText: 'Select Exercise'),
                    items: _commonExercises
                        .map((ex) => DropdownMenuItem(value: ex, child: Text(ex)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedExercise = v!),
                  ),
                  const SizedBox(height: 12),
                  // Search/Custom entry textfield
                  TextField(
                    controller: _exerciseSearchController,
                    decoration: const InputDecoration(
                      labelText: 'Or Type Custom Name',
                      hintText: 'e.g. Lateral Raise',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Weight (kg)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _repsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Reps'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final String exName = _exerciseSearchController.text.isNotEmpty
                        ? _exerciseSearchController.text
                        : selectedExercise;
                    
                    final double wt = double.tryParse(_weightController.text) ?? 60.0;
                    final int rp = int.tryParse(_repsController.text) ?? 10;

                    // Calculate set number dynamically from existing active logs
                    final existingSets = state.workoutLogs.where((w) => w.exerciseName == exName).toList();
                    final int nextSetNum = existingSets.length + 1;

                    final log = WorkoutLog(
                      date: state.activeDate,
                      exerciseName: exName,
                      weight: wt,
                      reps: rp,
                      setNumber: nextSetNum,
                    );
                    state.logWorkoutSet(log);

                    _exerciseSearchController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Log Set'),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<StateService>(context);
    final isDark = state.isDark;

    // Group workouts dynamically for active date
    final Map<String, List<WorkoutLog>> groupedLogs = {};
    for (var log in state.workoutLogs) {
      if (!groupedLogs.containsKey(log.exerciseName)) {
        groupedLogs[log.exerciseName] = [];
      }
      groupedLogs[log.exerciseName]!.add(log);
    }
    groupedLogs.forEach((k, v) => v.sort((a, b) => a.setNumber.compareTo(b.setNumber)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // REST TIMER CARD
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _timerRunning 
                          ? const Color(0xff10b981).withOpacity(0.1) 
                          : Colors.grey.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.timer, 
                        color: _timerRunning ? const Color(0xff10b981) : Colors.grey,
                        size: 20
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rest Timer / Stopwatch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(
                          _formatTimer(_secondsElapsed),
                          style: TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: _timerRunning ? const Color(0xff10b981) : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_timerRunning ? Icons.pause : Icons.play_arrow),
                        onPressed: _toggleTimer,
                      ),
                      IconButton(
                        icon: const Icon(Icons.replay),
                        onPressed: _resetTimer,
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),

            // LOGGED WORKOUTS LIST
            if (state.workoutLogs.isEmpty)
              GlassCard(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      Icon(Icons.fitness_center, size: 36, color: isDark ? Colors.zinc.shade600 : Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No workouts logged today.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.zinc.shade600 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...groupedLogs.keys.map((exName) {
                final sets = groupedLogs[exName]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                            border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(exName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text(
                                '${sets.length} sets',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.zinc.shade500 : Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sets.length,
                          separatorBuilder: (context, idx) => Divider(
                            height: 1.0,
                            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                          ),
                          itemBuilder: (context, idx) {
                            final log = sets[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Set ${log.setNumber}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff818cf8)),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${log.weight} kg',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('×', style: TextStyle(fontSize: 11, color: isDark ? Colors.zinc.shade600 : Colors.grey.shade500)),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${log.reps} reps',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 16),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          if (log.id != null) {
                                            state.deleteWorkoutSet(log.id!);
                                          }
                                        },
                                      )
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            const SizedBox(height: 60), // padding for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogSetDialog(state),
        backgroundColor: const Color(0xff4f46e5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log Exercise Set', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
