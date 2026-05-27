import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_service.dart';
import '../models/workout_log.dart';
import '../models/workout_session.dart';
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
  
  // Stopwatch Timer States
  Timer? _stopwatchTimer;
  int _secondsElapsed = 0;
  bool _timerRunning = false;

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
    final hours = totalSecs ~/ 3600;
    final mins = (totalSecs % 3600) ~/ 60;
    final secs = totalSecs % 60;
    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    }
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  void _showLogSetDialog(StateService state) {
    final isDark = state.isDark;
    String dialogSelectedExercise = '';
    String searchQuery = '';
    bool showAddCustom = false;

    // Custom exercise controllers
    final customNameController = TextEditingController();
    String customCategory = 'strength';
    List<String> customMuscles = [];

    // Search results list
    List<Map<String, dynamic>> searchResults = state.searchExercises('');
    List<WorkoutLog> exerciseHistory = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dialogTheme = isDark ? const Color(0xff121219) : Colors.white;
            final textThemeColor = isDark ? Colors.white : Colors.black87;

            return AlertDialog(
              backgroundColor: dialogTheme,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                dialogSelectedExercise.isEmpty 
                    ? (showAddCustom ? 'Add Custom Exercise' : 'Search Exercises') 
                    : 'Log Set',
                style: TextStyle(fontWeight: FontWeight.bold, color: textThemeColor, fontSize: 16),
              ),
              content: Container(
                width: min(320.0, MediaQuery.of(context).size.width * 0.95),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dialogSelectedExercise.isEmpty) ...[
                        if (showAddCustom) ...[
                          // Custom Exercise Form
                          TextField(
                            controller: customNameController,
                            style: TextStyle(color: textThemeColor, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Exercise Name',
                              labelStyle: const TextStyle(fontSize: 12),
                              hintText: 'e.g. Incline Bench Press',
                              filled: true,
                              fillColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: customCategory,
                            dropdownColor: isDark ? const Color(0xff121219) : Colors.white,
                            style: TextStyle(color: textThemeColor, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Category',
                              labelStyle: const TextStyle(fontSize: 12),
                              filled: true,
                              fillColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                            items: ['strength', 'cardio', 'stretching', 'plyometrics', 'powerlifting']
                                .map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat[0].toUpperCase() + cat.substring(1)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => customCategory = val);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Primary Muscles',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: ['Chest', 'Back', 'Quads', 'Hamstrings', 'Shoulders', 'Biceps', 'Triceps', 'Abs', 'Calves'].map((muscle) {
                              final isSelected = customMuscles.contains(muscle);
                              return InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    if (isSelected) {
                                      customMuscles.remove(muscle);
                                    } else {
                                      customMuscles.add(muscle);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? const Color(0xff4f46e5).withOpacity(0.15) 
                                        : (isDark ? const Color(0xff181822) : Colors.grey.shade100),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xff4f46e5) : Colors.transparent,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    muscle,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? const Color(0xff818cf8) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ] else ...[
                          // Search Box
                          TextField(
                            onChanged: (val) {
                              setDialogState(() {
                                searchQuery = val;
                                searchResults = state.searchExercises(searchQuery);
                              });
                            },
                            style: TextStyle(color: textThemeColor, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search 800+ exercises...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              filled: true,
                              fillColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Search Results List
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xff151520).withOpacity(0.5) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? const Color(0xff212130) : Colors.grey.shade200),
                            ),
                            child: searchResults.isEmpty
                                ? Center(
                                    child: Text(
                                      'No exercises found.',
                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade600 : Colors.grey.shade500),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: searchResults.length,
                                    separatorBuilder: (context, i) => Divider(height: 1.0, color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                                    itemBuilder: (context, i) {
                                      final ex = searchResults[i];
                                      final name = ex['name'] as String? ?? 'Exercise';
                                      final category = ex['category'] as String? ?? '';
                                      final muscles = List<String>.from(ex['primaryMuscles'] ?? []);
                                      return ListTile(
                                        title: Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textThemeColor)),
                                        subtitle: Text(
                                          '${category[0].toUpperCase() + category.substring(1)} · ${muscles.join(', ')}',
                                          style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                                        ),
                                        dense: true,
                                        onTap: () {
                                          // RECALCULATE HISTORY IN CLICK HANDLER
                                          final history = state.allWorkoutSetsHistory
                                              .where((w) => w.exerciseName.toLowerCase() == name.toLowerCase())
                                              .toList()
                                            ..sort((a, b) => b.date.compareTo(a.date));

                                          setDialogState(() {
                                            dialogSelectedExercise = name;
                                            exerciseHistory = history;
                                            if (exerciseHistory.isNotEmpty) {
                                              _weightController.text = exerciseHistory.first.weight.toString();
                                              _repsController.text = exerciseHistory.first.reps.toString();
                                            } else {
                                              _weightController.text = '60';
                                              _repsController.text = '10';
                                            }
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  showAddCustom = true;
                                  customNameController.clear();
                                  customMuscles.clear();
                                });
                              },
                              child: const Text('Add Custom Exercise', style: TextStyle(fontSize: 12, color: Color(0xff818cf8), decoration: TextDecoration.underline)),
                            ),
                          ),
                        ],
                      ] else ...[
                        // Exercise Selected State
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xff6366f1).withOpacity(0.1),
                            border: Border.all(color: const Color(0xff6366f1).withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('SELECTED EXERCISE', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    Text(
                                      dialogSelectedExercise,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textThemeColor),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setDialogState(() => dialogSelectedExercise = '');
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Display previous sets if available
                        if (exerciseHistory.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xff171722) : Colors.grey.shade50,
                              border: Border.all(color: isDark ? const Color(0xff222235) : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('PREVIOUS SETS HISTORY', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 6),
                                ...exerciseHistory.take(3).map((w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Set ${w.setNumber} (${w.date})', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                                      Text('${w.weight}kg × ${w.reps}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textThemeColor)),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        // Input weight and reps
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: textThemeColor, fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Weight (kg)',
                                  labelStyle: const TextStyle(fontSize: 12),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _repsController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: textThemeColor, fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Reps',
                                  labelStyle: const TextStyle(fontSize: 12),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                if (dialogSelectedExercise.isEmpty && showAddCustom) ...[
                  TextButton(
                    onPressed: () => setDialogState(() => showAddCustom = false),
                    child: const Text('Back'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (customNameController.text.isNotEmpty) {
                        state.addCustomExercise(
                          customNameController.text.trim(),
                          customCategory,
                          customMuscles,
                        );
                        setDialogState(() {
                          dialogSelectedExercise = customNameController.text.trim();
                          showAddCustom = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff4f46e5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save & Select', style: TextStyle(color: Colors.white)),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  if (dialogSelectedExercise.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        final double wt = double.tryParse(_weightController.text) ?? 60.0;
                        final int rp = int.tryParse(_repsController.text) ?? 10;

                        final existingSets = state.workoutLogs
                            .where((w) => w.exerciseName.toLowerCase() == dialogSelectedExercise.toLowerCase())
                            .toList();
                        final int nextSetNum = existingSets.length + 1;

                        final log = WorkoutLog(
                          date: state.activeDate,
                          exerciseName: dialogSelectedExercise,
                          weight: wt,
                          reps: rp,
                          setNumber: nextSetNum,
                        );
                        state.logWorkoutSet(log);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4f46e5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Add Set', style: TextStyle(color: Colors.white)),
                    ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  void _showLogSessionDialog(StateService state, {WorkoutSession? existingSession}) {
    final durationCtrl = TextEditingController(
      text: existingSession?.duration.toString() ?? 
           (_secondsElapsed > 0 ? max(1, _secondsElapsed ~/ 60).toString() : '45')
    );
    final notesCtrl = TextEditingController(text: existingSession?.notes ?? '');
    double energyLevel = existingSession?.energy ?? 4.0;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = state.isDark;
        final inputDecoration = InputDecoration(
          filled: true,
          fillColor: isDark ? const Color(0xff181825) : Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          labelStyle: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        );

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xff121219) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(existingSession != null ? 'Edit Workout Session' : 'Log Workout Session', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Container(
                width: min(350.0, MediaQuery.of(context).size.width * 0.95),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: durationCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13),
                        decoration: inputDecoration.copyWith(labelText: 'Duration (minutes)'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Energy Level: ${energyLevel.round()}/5',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                      ),
                      Slider(
                        value: energyLevel,
                        min: 1.0,
                        max: 5.0,
                        divisions: 4,
                        activeColor: const Color(0xff4f46e5),
                        onChanged: (v) => setDialogState(() => energyLevel = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 3,
                        decoration: inputDecoration.copyWith(labelText: 'Workout Notes (e.g. felt strong, new PRs)'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4f46e5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final session = WorkoutSession(
                      id: existingSession?.id,
                      date: state.activeDate,
                      duration: int.tryParse(durationCtrl.text) ?? 0,
                      energy: energyLevel,
                      notes: notesCtrl.text.trim(),
                    );
                    state.logWorkoutSession(session);
                    Navigator.pop(context);
                  },
                  child: const Text('Save Session'),
                ),
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
            // REST TIMER / STOPWATCH CARD
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
                      if (_secondsElapsed > 0)
                        IconButton(
                          icon: const Icon(Icons.save_outlined, color: Colors.green),
                          tooltip: 'Log workout session from timer',
                          onPressed: () => _showLogSessionDialog(state),
                        ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),

            // WORKOUT SESSION DETAILS CARD
            if (state.workoutSession != null) ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.insights, size: 16, color: Color(0xff818cf8)),
                            SizedBox(width: 8),
                            Text('Session Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blueAccent),
                              onPressed: () => _showLogSessionDialog(state, existingSession: state.workoutSession),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                              onPressed: () {
                                if (state.workoutSession!.id != null) {
                                  state.deleteWorkoutSession(state.workoutSession!.id!);
                                }
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSessionInfoItem('Duration', '${state.workoutSession!.duration} mins'),
                        const SizedBox(width: 24),
                        _buildSessionInfoItem('Energy Level', '${state.workoutSession!.energy.round()}/5'),
                      ],
                    ),
                    if (state.workoutSession!.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Notes: ${state.workoutSession!.notes}',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No Session Summary Logged',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Log duration, energy, and notes for today.',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4f46e5).withOpacity(0.15),
                        foregroundColor: const Color(0xff818cf8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () => _showLogSessionDialog(state),
                      child: const Text('Log Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // LOGGED WORKOUTS LIST
            if (state.workoutLogs.isEmpty)
              GlassCard(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      Icon(Icons.fitness_center, size: 36, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No workouts logged today.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade50,
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
                              Expanded(
                                child: Text(
                                  exName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${sets.length} sets',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
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
                                      Text('×', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade600 : Colors.grey.shade500)),
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
              }),
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

  Widget _buildSessionInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
