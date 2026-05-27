import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_service.dart';
import '../models/goals.dart';
import '../widgets/glass_card.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _postgresController = TextEditingController();
  final _caloriesGoalController = TextEditingController();
  final _proteinGoalController = TextEditingController();
  final _carbsGoalController = TextEditingController();
  final _fatGoalController = TextEditingController();
  final _fiberGoalController = TextEditingController();
  final _waterGoalController = TextEditingController();

  bool _testingPostgres = false;
  String? _postgresMessage;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<StateService>(context, listen: false);
    _postgresController.text = state.postgresConn;
    _caloriesGoalController.text = state.goals.calories.round().toString();
    _proteinGoalController.text = state.goals.protein.round().toString();
    _carbsGoalController.text = state.goals.carbs.round().toString();
    _fatGoalController.text = state.goals.fat.round().toString();
    _fiberGoalController.text = state.goals.fiber.round().toString();
    _waterGoalController.text = state.waterGoalMl.toString();
  }

  @override
  void dispose() {
    _postgresController.dispose();
    _caloriesGoalController.dispose();
    _proteinGoalController.dispose();
    _carbsGoalController.dispose();
    _fatGoalController.dispose();
    _fiberGoalController.dispose();
    _waterGoalController.dispose();
    super.dispose();
  }

  void _saveGoals(StateService state) {
    final double cal = double.tryParse(_caloriesGoalController.text) ?? 2000.0;
    final double prot = double.tryParse(_proteinGoalController.text) ?? 130.0;
    final double carb = double.tryParse(_carbsGoalController.text) ?? 220.0;
    final double fat = double.tryParse(_fatGoalController.text) ?? 65.0;
    final double fib = double.tryParse(_fiberGoalController.text) ?? 30.0;

    state.updateGoals(Goals(
      calories: cal,
      protein: prot,
      carbs: carb,
      fat: fat,
      fiber: fib,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nutrition goals updated successfully!'), duration: Duration(seconds: 1)),
    );
  }

  void _saveWellness(StateService state) {
    final int water = int.tryParse(_waterGoalController.text) ?? 2500;
    state.updateWellnessSettings(state.weightUnit, water);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wellness preferences saved!'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _testAndSavePostgres(StateService state) async {
    if (_postgresController.text.isEmpty) return;

    setState(() {
      _testingPostgres = true;
      _postgresMessage = null;
    });

    final success = await state.updatePostgresConnection(_postgresController.text);

    setState(() {
      _testingPostgres = false;
      _postgresMessage = success
          ? 'Successfully connected to PostgreSQL! 🚀'
          : 'Database connection failed. Reverted to local mode.';
    });
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
          // 1. APPEARANCE THEME TOGGLE CARD
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode, 
                      size: 16, 
                      color: isDark ? Colors.indigo.shade400 : Colors.amber.shade700
                    ),
                    const SizedBox(width: 8),
                    const Text('Appearance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Switch between dark and light themes.',
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => state.toggleTheme(!isDark),
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 16),
                  label: Text('Use ${isDark ? 'Light' : 'Dark'} Theme'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
                    foregroundColor: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                    minimumSize: const Size(double.infinity, 38),
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isDark ? const Color(0xff242436) : Colors.grey.shade200),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 1.5. APP TUTORIAL CARD
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.help_outline, 
                      size: 16, 
                      color: isDark ? Colors.indigo.shade400 : Colors.indigo.shade700
                    ),
                    const SizedBox(width: 8),
                    const Text('App Tutorial', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Watch the onboarding guide to learn how to navigate and use TrackFit.',
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    state.resetOnboarding();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tutorial reset! Replaying guide...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_circle_outline, size: 16),
                  label: const Text('Replay Onboarding Guide'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
                    foregroundColor: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                    minimumSize: const Size(double.infinity, 38),
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isDark ? const Color(0xff242436) : Colors.grey.shade200),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. WELLNESS PREFERENCES
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.spa, size: 16, color: Colors.lightBlue.shade400),
                    const SizedBox(width: 8),
                    const Text('Wellness Preferences', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weight Unit', style: TextStyle(fontSize: 12)),
                    Row(
                      children: [
                        _buildUnitButton('kg', state.weightUnit == 'kg', () {
                          state.updateWellnessSettings('kg', state.waterGoalMl);
                        }),
                        const SizedBox(width: 6),
                        _buildUnitButton('lbs', state.weightUnit == 'lbs', () {
                          state.updateWellnessSettings('lbs', state.waterGoalMl);
                        }),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Text('Daily Water Goal (ml)', style: TextStyle(fontSize: 12))),
                    SizedBox(
                      width: 80,
                      height: 32,
                      child: TextField(
                        controller: _waterGoalController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _saveWellness(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4f46e5),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Wellness Targets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. NUTRITION TARGETS
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.track_changes, size: 16, color: Colors.indigo.shade400),
                    const SizedBox(width: 8),
                    const Text('Nutrition Targets', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildGoalInput('Daily Calories (kcal)', _caloriesGoalController),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildGoalInput('Protein (g)', _proteinGoalController)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildGoalInput('Carbs (g)', _carbsGoalController)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildGoalInput('Fat (g)', _fatGoalController)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildGoalInput('Fiber (g)', _fiberGoalController)),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _saveGoals(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4f46e5),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Update Nutrition Targets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. POSTGRES CREDENTIALS DATABASE SETUP
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.storage, size: 16, color: Colors.indigo.shade300),
                    const SizedBox(width: 8),
                    const Text('Database Sync', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Synchronize your data with an external PostgreSQL server.',
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: state.isDemoMode 
                        ? Colors.amber.withOpacity(0.08) 
                        : Colors.indigo.withOpacity(0.08),
                    border: Border.all(
                      color: state.isDemoMode 
                          ? Colors.amber.withOpacity(0.3) 
                          : Colors.indigo.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.isDemoMode ? Icons.cloud_off : Icons.cloud_done, 
                        size: 16, 
                        color: state.isDemoMode ? Colors.amber : Colors.indigo
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.isDemoMode ? 'Local Storage Mode' : 'Remote Postgres Sync Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: state.isDemoMode ? Colors.amber.shade300 : Colors.indigo.shade300
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _postgresController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    labelText: 'Postgres Connection String',
                    hintText: 'postgresql://username:password@host:port/database',
                    filled: true,
                    fillColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                if (_postgresMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_postgresMessage!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _testingPostgres ? null : () => _testAndSavePostgres(state),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4f46e5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _testingPostgres 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save & Sync', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (!state.isDemoMode) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            state.disconnectPostgres();
                            _postgresController.clear();
                            setState(() => _postgresMessage = 'Reverted to local SQLite DB.');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.12),
                            foregroundColor: Colors.redAccent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                          ),
                          child: const Text('Disconnect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. MAINTENANCE RESET DATA
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 16, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    const Text('Danger Zone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: isDark ? const Color(0xff121219) : Colors.white,
                          title: const Text('Confirm Database Reset'),
                          content: const Text('This will delete all logged meals, weights, water trackers, and exercise logs. This action is irreversible.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () {
                                state.resetAll();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('All logs deleted.')),
                                );
                              },
                              child: const Text('Reset All Data'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.12),
                    foregroundColor: Colors.redAccent,
                    minimumSize: const Size(double.infinity, 38),
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                  child: const Text('Reset All Datasets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildUnitButton(String unit, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xff4f46e5) : Colors.transparent,
          border: Border.all(
            color: active ? const Color(0xff4f46e5) : Colors.grey.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          unit,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade800),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalInput(String label, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 34,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              filled: true,
              fillColor: isDark ? const Color(0xff181822) : Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),
      ],
    );
  }
}
