import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_log.dart';
import '../models/workout_log.dart';
import '../models/water_log.dart';
import '../models/weight_log.dart';
import '../models/goals.dart';
import '../models/workout_session.dart';
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
  bool _showOnboarding = false;

  // Active state data
  List<FoodLog> _foodLogs = [];
  List<WorkoutLog> _workoutLogs = [];
  List<WaterLog> _waterLogs = [];
  WeightLog? _weightLog;
  WorkoutSession? _workoutSession;

  // History state data (for trends)
  List<WeightLog> _weightHistory = [];
  List<WaterLog> _waterHistory = [];
  List<WorkoutLog> _allWorkoutSetsHistory = [];
  List<FoodLog> _foodHistory = [];
  List<WorkoutSession> _workoutSessionsHistory = [];

  // Offline Exercise Database
  List<dynamic> _exerciseTemplates = [];
  List<Map<String, dynamic>> _customExercises = [];
  List<dynamic> _foodTemplates = [];

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
  bool get showOnboarding => _showOnboarding;
  bool get isDemoMode => !_db.isPostgresMode;

  List<FoodLog> get foodLogs => _foodLogs;
  List<WorkoutLog> get workoutLogs => _workoutLogs;
  List<WaterLog> get waterLogs => _waterLogs;
  WeightLog? get weightLog => _weightLog;
  WorkoutSession? get workoutSession => _workoutSession;

  List<WeightLog> get weightHistory => _weightHistory;
  List<WaterLog> get waterHistory => _waterHistory;
  List<WorkoutLog> get allWorkoutSetsHistory => _allWorkoutSetsHistory;
  List<FoodLog> get foodHistory => _foodHistory;
  List<WorkoutSession> get workoutSessionsHistory => _workoutSessionsHistory;
  List<dynamic> get exerciseTemplates => _exerciseTemplates;
  List<Map<String, dynamic>> get customExercises => _customExercises;

  double get totalConsumedCalories => _foodLogs.fold(0.0, (sum, item) => sum + item.calories);
  double get totalConsumedProtein => _foodLogs.fold(0.0, (sum, item) => sum + item.protein);
  double get totalConsumedCarbs => _foodLogs.fold(0.0, (sum, item) => sum + item.carbs);
  double get totalConsumedFat => _foodLogs.fold(0.0, (sum, item) => sum + item.fat);
  double get totalConsumedFiber => _foodLogs.fold(0.0, (sum, item) => sum + item.fiber);

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
    final onboardingCompleted = prefs.getBool('trackfit_onboarding_completed') ?? false;
    _showOnboarding = !onboardingCompleted;

    // Load goals
    _goals = Goals(
      calories: prefs.getDouble('trackfit_goal_calories') ?? 2000.0,
      protein: prefs.getDouble('trackfit_goal_protein') ?? 130.0,
      carbs: prefs.getDouble('trackfit_goal_carbs') ?? 220.0,
      fiber: prefs.getDouble('trackfit_goal_fiber') ?? 30.0,
      fat: prefs.getDouble('trackfit_goal_fat') ?? 65.0,
    );

    // Initialize database and load data
    try {
      await _db.init();
      await _checkAndPrepopulateDemo();
      await loadActiveDateData();
    } catch (e) {
      debugPrint('Database initialization or loading failed: $e');
    }

    // Load offline templates
    await _loadExerciseTemplates();
    await _loadCustomExercises();
    await _loadFoodTemplates();

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
    _workoutSession = await _db.getWorkoutSession(_activeDate);

    // Load histories
    _weightHistory = await _db.getWeightHistory();
    _waterHistory = await _db.getWaterHistory();
    _allWorkoutSetsHistory = await _db.getAllWorkoutSets();
    _foodHistory = await _db.getAllFoodLogs();
    _workoutSessionsHistory = await _db.getAllWorkoutSessions();

    notifyListeners();
  }

  Future<void> _loadExerciseTemplates() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _exerciseTemplates = [];
      return;
    }
    try {
      final jsonString = await rootBundle.loadString('assets/exercises.json');
      _exerciseTemplates = json.decode(jsonString) as List<dynamic>;
    } catch (e) {
      debugPrint('Error loading exercise templates: $e');
    }
  }

  Future<void> _loadCustomExercises() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('trackfit_demo_custom_exercises');
      if (data != null) {
        final decoded = json.decode(data) as List<dynamic>;
        _customExercises = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      _customExercises = [];
    }
  }

  Future<void> addCustomExercise(String name, String category, List<String> primaryMuscles) async {
    final newEx = {
      'name': name,
      'category': category,
      'primaryMuscles': primaryMuscles,
      'equipment': 'custom',
    };
    _customExercises.insert(0, newEx);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trackfit_demo_custom_exercises', json.encode(_customExercises));
    notifyListeners();
  }

  List<Map<String, dynamic>> searchExercises(String query) {
    final allExercises = <Map<String, dynamic>>[];
    allExercises.addAll(_customExercises);
    for (var temp in _exerciseTemplates) {
      if (temp is Map) {
        allExercises.add(Map<String, dynamic>.from(temp));
      }
    }

    if (query.trim().length < 2) {
      final popular = ['Bench Press', 'Squat', 'Deadlift', 'Overhead Press', 'Bicep Curl', 'Lunge', 'Pull-up', 'Push-up', 'Plank', 'Lateral Raise'];
      final defaultList = allExercises.where((e) {
        final name = (e['name'] as String? ?? '').toLowerCase();
        return e['equipment'] == 'custom' || popular.any((pop) => name.contains(pop.toLowerCase()));
      }).toList();
      return defaultList.take(15).toList();
    }

    final queryWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return allExercises.where((e) {
      final name = (e['name'] as String? ?? '').toLowerCase();
      final category = (e['category'] as String? ?? '').toLowerCase();
      final muscles = (e['primaryMuscles'] as List<dynamic>? ?? []).map((m) => m.toString().toLowerCase()).toList();
      
      return queryWords.every((word) {
        final cleanWord = word == 'tricep' ? 'triceps' : (word == 'bicep' ? 'biceps' : word);
        return name.contains(word) || name.contains(cleanWord) ||
               category.contains(word) ||
               muscles.any((m) => m.contains(word) || m.contains(cleanWord));
      });
    }).take(20).toList();
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

  Future<void> deleteWater(int id) async {
    await _db.deleteWaterLog(id);
    await loadActiveDateData();
  }

  Future<void> logWeight(double weight, double? bodyFat) async {
    await _db.insertWeightLog(WeightLog(date: _activeDate, weight: weight, bodyFat: bodyFat));
    await loadActiveDateData();
  }

  Future<void> deleteWeight(int id) async {
    await _db.deleteWeightLog(id);
    await loadActiveDateData();
  }

  Future<void> logWorkoutSession(WorkoutSession session) async {
    await _db.insertWorkoutSession(session);
    await loadActiveDateData();
  }

  Future<void> deleteWorkoutSession(int id) async {
    await _db.deleteWorkoutSession(id);
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

  Future<void> completeOnboarding() async {
    _showOnboarding = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trackfit_onboarding_completed', true);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    _showOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trackfit_onboarding_completed', false);
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

  List<dynamic> get foodTemplates => _foodTemplates;

  Future<void> _loadFoodTemplates() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _foodTemplates = [];
      return;
    }
    try {
      final jsonString = await rootBundle.loadString('assets/foods.json');
      _foodTemplates = json.decode(jsonString) as List<dynamic>;
    } catch (e) {
      debugPrint('Error loading food templates: $e');
    }
  }

  List<Map<String, dynamic>> searchFoods(String query) {
    if (query.trim().length < 2) {
      return [];
    }
    final queryWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final results = <Map<String, dynamic>>[];
    for (var f in _foodTemplates) {
      if (f is Map) {
        final name = (f['name'] as String? ?? '').toLowerCase();
        final category = (f['category'] as String? ?? '').toLowerCase();
        
        bool matches = queryWords.every((word) {
          return name.contains(word) || category.contains(word);
        });
        if (matches) {
          results.add(Map<String, dynamic>.from(f));
        }
      }
    }
    return results.take(15).toList();
  }

  Future<List<Map<String, dynamic>>> searchOpenFoodFacts(String query) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&page_size=10');
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'TrackFit - FlutterApp - Version 1.0');
      final response = await request.close();
      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final data = json.decode(jsonString) as Map<String, dynamic>;
        final products = data['products'] as List<dynamic>? ?? [];
        final List<Map<String, dynamic>> results = [];
        for (var p in products) {
          if (p is Map<String, dynamic>) {
            final name = p['product_name'] ?? p['product_name_en'] ?? 'Unknown Food';
            final brand = p['brands'] != null ? ' (${p['brands']})' : '';
            final fullName = '$name$brand';
            
            final nutriments = p['nutriments'] as Map<String, dynamic>? ?? {};
            double calories = 0.0;
            if (nutriments['energy-kcal_100g'] != null) {
              calories = (nutriments['energy-kcal_100g'] as num).toDouble();
            } else if (nutriments['energy-kcal'] != null) {
              calories = (nutriments['energy-kcal'] as num).toDouble();
            } else if (nutriments['energy_100g'] != null) {
              calories = (nutriments['energy_100g'] as num).toDouble() / 4.184;
            }
            
            results.add({
              'name': fullName,
              'calories': calories,
              'protein': (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0.0,
              'carbs': (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0.0,
              'fiber': (nutriments['fiber_100g'] as num?)?.toDouble() ?? 0.0,
              'fat': (nutriments['fat_100g'] as num?)?.toDouble() ?? 0.0,
              'servingSize': 100.0,
              'source': 'open-food-facts'
            });
          }
        }
        return results;
      }
    } catch (e) {
      debugPrint('Open Food Facts API error: $e');
    }
    return [];
  }
}
