import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_log.dart';
import '../models/workout_log.dart';
import '../models/water_log.dart';
import '../models/weight_log.dart';
import '../models/goals.dart';
import 'db_service.dart';

class StateService extends ChangeNotifier {
  final DbService _db = DbService();
  
  String _activeDate = '';
  Goals _goals = Goals.defaultGoals();
  bool _isDark = true;
  String _weightUnit = 'kg';
  int _waterGoalMl = 2500;
  String _postgresConn = '';
  bool _isLoading = false;

  // Active state data
  List<FoodLog> _foodLogs = [];
  List<WorkoutLog> _workoutLogs = [];
  List<WaterLog> _waterLogs = [];
  WeightLog? _weightLog;

  // History state data (for trends)
  List<WeightLog> _weightHistory = [];
  List<WaterLog> _waterHistory = [];
  List<WorkoutLog> _allWorkoutSetsHistory = [];

  StateService() {
    final now = DateTime.now();
    _activeDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _initApp();
  }

  // Getters
  String get activeDate => _activeDate;
  Goals get goals => _goals;
  bool get isDark => _isDark;
  String get weightUnit => _weightUnit;
  int get waterGoalMl => _waterGoalMl;
  String get postgresConn => _postgresConn;
  bool get isLoading => _isLoading;
  bool get isDemoMode => !_db.isPostgresMode;

  List<FoodLog> get foodLogs => _foodLogs;
  List<WorkoutLog> get workoutLogs => _workoutLogs;
  List<WaterLog> get waterLogs => _waterLogs;
  WeightLog? get weightLog => _weightLog;

  List<WeightLog> get weightHistory => _weightHistory;
  List<WaterLog> get waterHistory => _waterHistory;
  List<WorkoutLog> get allWorkoutSetsHistory => _allWorkoutSetsHistory;

  double get totalConsumedCalories => _foodLogs.fold(0, (sum, item) => sum + item.calories);
  double get totalConsumedProtein => _foodLogs.fold(0, (sum, item) => sum + item.protein);
  double get totalConsumedCarbs => _foodLogs.fold(0, (sum, item) => sum + item.carbs);
  double get totalConsumedFat => _foodLogs.fold(0, (sum, item) => sum + item.fat);
  double get totalConsumedFiber => _foodLogs.fold(0, (sum, item) => sum + item.fiber);

  int get totalWaterMl => _waterLogs.fold(0, (sum, item) => sum + item.amount);

  Future<void> _initApp() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    
    // Load simple preferences
    _isDark = prefs.getBool('trackfit_dark_theme') ?? true;
    _weightUnit = prefs.getString('trackfit_weight_unit') ?? 'kg';
    _waterGoalMl = prefs.getInt('trackfit_water_goal') ?? 2500;
    _postgresConn = prefs.getString('trackfit_postgres_conn') ?? '';

    // Load goals
    _goals = Goals(
      calories: prefs.getDouble('trackfit_goal_calories') ?? 2000.0,
      protein: prefs.getDouble('trackfit_goal_protein') ?? 130.0,
      carbs: prefs.getDouble('trackfit_goal_carbs') ?? 220.0,
      fiber: prefs.getDouble('trackfit_goal_fiber') ?? 30.0,
      fat: prefs.getDouble('trackfit_goal_fat') ?? 65.0,
    );

    // Initialize database
    await _db.init();

    // Check if empty, prepopulate demo
    await _checkAndPrepopulateDemo();

    // Load active date data
    await loadActiveDateData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _checkAndPrepopulateDemo() async {
    final prefs = await SharedPreferences.getInstance();
    final isPrepopulated = prefs.getBool('trackfit_prepopulated') ?? false;
    if (isPrepopulated) return;

    final existingFood = await _db.getFoodLogs(_activeDate);
    if (existingFood.isEmpty) {
      // Add some sample foods for today
      await _db.insertFoodLog(FoodLog(
        date: _activeDate,
        foodName: '🥚 Boiled Egg',
        quantity: 2,
        calories: 156,
        protein: 13,
        carbs: 1.1,
        fat: 11,
        fiber: 0,
        mealType: 'Breakfast',
        servingUnit: 'piece',
      ));
      await _db.insertFoodLog(FoodLog(
        date: _activeDate,
        foodName: '🥛 Milk (Toned)',
        quantity: 1,
        calories: 120,
        protein: 6.4,
        carbs: 9.6,
        fat: 6.0,
        fiber: 0,
        mealType: 'Breakfast',
        servingUnit: 'glass',
      ));
      await _db.insertFoodLog(FoodLog(
        date: _activeDate,
        foodName: '🍲 Paneer Bhurji',
        quantity: 150,
        calories: 340,
        protein: 24,
        carbs: 8,
        fat: 26,
        fiber: 2,
        mealType: 'Lunch',
        servingUnit: 'g',
      ));
      await _db.insertFoodLog(FoodLog(
        date: _activeDate,
        foodName: '🫓 Chapati (Plain)',
        quantity: 2,
        calories: 170,
        protein: 6,
        carbs: 34,
        fat: 0.8,
        fiber: 4.4,
        mealType: 'Lunch',
        servingUnit: 'piece',
      ));

      // Add sample workouts
      await _db.insertWorkoutLog(WorkoutLog(
        date: _activeDate,
        exerciseName: 'Bench Press',
        weight: 60,
        reps: 10,
        setNumber: 1,
      ));
      await _db.insertWorkoutLog(WorkoutLog(
        date: _activeDate,
        exerciseName: 'Bench Press',
        weight: 70,
        reps: 8,
        setNumber: 2,
      ));
      await _db.insertWorkoutLog(WorkoutLog(
        date: _activeDate,
        exerciseName: 'Squats',
        weight: 80,
        reps: 10,
        setNumber: 1,
      ));

      // Add sample water
      await _db.insertWaterLog(WaterLog(date: _activeDate, amount: 250));
      await _db.insertWaterLog(WaterLog(date: _activeDate, amount: 500));
      await _db.insertWaterLog(WaterLog(date: _activeDate, amount: 500));

      // Add weight
      await _db.insertWeightLog(WeightLog(date: _activeDate, weight: 75.4, bodyFat: 15.2));

      // Add weight history for charts
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dayBefore = DateTime.now().subtract(const Duration(days: 2));
      final day3 = DateTime.now().subtract(const Duration(days: 3));

      final yDate = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
      final dbDate = "${dayBefore.year}-${dayBefore.month.toString().padLeft(2, '0')}-${dayBefore.day.toString().padLeft(2, '0')}";
      final d3Date = "${day3.year}-${day3.month.toString().padLeft(2, '0')}-${day3.day.toString().padLeft(2, '0')}";

      await _db.insertWeightLog(WeightLog(date: yDate, weight: 75.6, bodyFat: 15.3));
      await _db.insertWeightLog(WeightLog(date: dbDate, weight: 75.8, bodyFat: 15.4));
      await _db.insertWeightLog(WeightLog(date: d3Date, weight: 76.1, bodyFat: 15.5));

      await _db.insertWaterLog(WaterLog(date: yDate, amount: 2000));
      await _db.insertWaterLog(WaterLog(date: dbDate, amount: 1800));

      await prefs.setBool('trackfit_prepopulated', true);
    }
  }

  Future<void> loadActiveDateData() async {
    _foodLogs = await _db.getFoodLogs(_activeDate);
    _workoutLogs = await _db.getWorkoutLogs(_activeDate);
    _waterLogs = await _db.getWaterLogs(_activeDate);
    _weightLog = await _db.getWeightLog(_activeDate);

    // Load histories
    _weightHistory = await _db.getWeightHistory();
    _waterHistory = await _db.getWaterHistory();
    _allWorkoutSetsHistory = await _db.getAllWorkoutSets();

    notifyListeners();
  }

  // Shift current date view
  Future<void> shiftDate(int days) async {
    final current = DateTime.parse("${_activeDate}T00:00:00");
    final next = current.add(Duration(days: days));
    _activeDate = "${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}";
    
    _isLoading = true;
    notifyListeners();
    
    await loadActiveDateData();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setSpecificDate(DateTime dt) async {
    _activeDate = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    _isLoading = true;
    notifyListeners();
    await loadActiveDateData();
    _isLoading = false;
    notifyListeners();
  }

  // ─── ACTIONS ───────────────────────────────────────────────────────────────
  Future<void> logFood(FoodLog log) async {
    await _db.insertFoodLog(log);
    await loadActiveDateData();
  }

  Future<void> deleteFood(int id) async {
    await _db.deleteFoodLog(id);
    await loadActiveDateData();
  }

  Future<void> logWorkoutSet(WorkoutLog log) async {
    await _db.insertWorkoutLog(log);
    await loadActiveDateData();
  }

  Future<void> deleteWorkoutSet(int id) async {
    await _db.deleteWorkoutLog(id);
    await loadActiveDateData();
  }

  Future<void> logWater(int amount) async {
    await _db.insertWaterLog(WaterLog(date: _activeDate, amount: amount));
    await loadActiveDateData();
  }

  Future<void> logWeight(double weight, double? bodyFat) async {
    await _db.insertWeightLog(WeightLog(date: _activeDate, weight: weight, bodyFat: bodyFat));
    await loadActiveDateData();
  }

  // Goals Settings
  Future<void> updateGoals(Goals newGoals) async {
    _goals = newGoals;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('trackfit_goal_calories', newGoals.calories);
    await prefs.setDouble('trackfit_goal_protein', newGoals.protein);
    await prefs.setDouble('trackfit_goal_carbs', newGoals.carbs);
    await prefs.setDouble('trackfit_goal_fiber', newGoals.fiber);
    await prefs.setDouble('trackfit_goal_fat', newGoals.fat);
    notifyListeners();
  }

  // Preferences Settings
  Future<void> updateWellnessSettings(String unit, int waterGoal) async {
    _weightUnit = unit;
    _waterGoalMl = waterGoal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trackfit_weight_unit', unit);
    await prefs.setInt('trackfit_water_goal', waterGoal);
    notifyListeners();
  }

  Future<void> toggleTheme(bool dark) async {
    _isDark = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trackfit_dark_theme', dark);
    notifyListeners();
  }

  // Database credential configurations
  Future<bool> updatePostgresConnection(String connectionString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trackfit_postgres_conn', connectionString);
    _postgresConn = connectionString;
    
    // re-init database
    _isLoading = true;
    notifyListeners();
    
    await _db.close();
    await _db.init();
    
    await loadActiveDateData();
    
    _isLoading = false;
    notifyListeners();
    return _db.isPostgresMode;
  }

  Future<void> disconnectPostgres() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('trackfit_postgres_conn');
    _postgresConn = '';
    
    _isLoading = true;
    notifyListeners();
    
    await _db.close();
    await _db.init();
    
    await loadActiveDateData();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> resetAll() async {
    await _db.resetAllData();
    await loadActiveDateData();
  }
}
