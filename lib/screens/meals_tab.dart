import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/state_service.dart';
import '../models/food_log.dart';
import '../widgets/glass_card.dart';

class MealsTab extends StatefulWidget {
  const MealsTab({Key? key}) : super(key: key);

  @override
  State<MealsTab> createState() => _MealsTabState();
}

class _MealsTabState extends State<MealsTab> {
  String _selectedMealType = 'Breakfast';
  final _foodNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  final _servingUnitController = TextEditingController(text: 'g');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();

  // Base macro variables for selected food scaling
  double _baseCalories = 0.0;
  double _baseProtein = 0.0;
  double _baseCarbs = 0.0;
  double _baseFat = 0.0;
  double _baseFiber = 0.0;

  final List<Map<String, dynamic>> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _quantityController.dispose();
    _servingUnitController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favsJson = prefs.getString('trackfit_favorite_meals');
    if (favsJson != null) {
      try {
        final List<dynamic> decoded = json.decode(favsJson);
        setState(() {
          _favorites.clear();
          _favorites.addAll(decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList());
        });
      } catch (e) {
        debugPrint('Error loading favorites: $e');
        _loadDefaultFavorites();
      }
    } else {
      _loadDefaultFavorites();
      _saveFavorites();
    }
  }

  void _loadDefaultFavorites() {
    setState(() {
      _favorites.clear();
      _favorites.addAll([
        {'displayName': 'Plain Chapati', 'icon': '🫓', 'foodName': 'Chapati (Plain)', 'qty': 1.0, 'unit': 'piece', 'cals': 85.0, 'protein': 3.0, 'carbs': 17.0, 'fat': 0.4, 'fiber': 2.2},
        {'displayName': 'Paneer (200g)', 'icon': '🧀', 'foodName': 'Paneer', 'qty': 200.0, 'unit': 'g', 'cals': 530.0, 'protein': 36.0, 'carbs': 6.0, 'fat': 40.0, 'fiber': 0.0},
        {'displayName': 'Toned Milk', 'icon': '🥛', 'foodName': 'Milk (Toned)', 'qty': 1.0, 'unit': 'glass', 'cals': 120.0, 'protein': 6.4, 'carbs': 9.6, 'fat': 6.0, 'fiber': 0.0},
        {'displayName': 'Whey Protein', 'icon': '🥤', 'foodName': 'Whey Protein (1 scoop)', 'qty': 1.0, 'unit': 'scoop', 'cals': 120.0, 'protein': 25.0, 'carbs': 3.0, 'fat': 1.5, 'fiber': 0.0},
        {'displayName': 'Boiled Egg', 'icon': '🥚', 'foodName': 'Egg (Boiled)', 'qty': 1.0, 'unit': 'piece', 'cals': 78.0, 'protein': 6.5, 'carbs': 0.6, 'fat': 5.5, 'fiber': 0.0},
        {'displayName': 'Steamed Rice', 'icon': '🍚', 'foodName': 'Steamed Rice', 'qty': 1.0, 'unit': 'bowl', 'cals': 200.0, 'protein': 4.0, 'carbs': 44.0, 'fat': 0.4, 'fiber': 1.4},
      ]);
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trackfit_favorite_meals', json.encode(_favorites));
  }

  void _quickLog(StateService state, Map<String, dynamic> fav) {
    final log = FoodLog(
      date: state.activeDate,
      foodName: "${fav['icon']} ${fav['foodName']}",
      quantity: fav['qty'],
      calories: fav['cals'],
      protein: fav['protein'],
      carbs: fav['carbs'],
      fat: fav['fat'],
      fiber: fav['fiber'],
      mealType: _selectedMealType,
      servingUnit: fav['unit'],
    );
    state.logFood(log);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged ${fav['foodName']} to $_selectedMealType!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _updateMacrosFromQuantity() {
    final double qty = double.tryParse(_quantityController.text) ?? 100.0;
    final double ratio = qty / 100.0;
    
    setState(() {
      _caloriesController.text = (qty == 0) ? '' : (_baseCalories * ratio).round().toString();
      _proteinController.text = (qty == 0) ? '' : ((_baseProtein * ratio * 10).round() / 10).toString();
      _carbsController.text = (qty == 0) ? '' : ((_baseCarbs * ratio * 10).round() / 10).toString();
      _fatController.text = (qty == 0) ? '' : ((_baseFat * ratio * 10).round() / 10).toString();
      _fiberController.text = (qty == 0) ? '' : ((_baseFiber * ratio * 10).round() / 10).toString();
    });
  }

  void _showAddFavoriteDialog(StateService state) {
    final displayNameCtrl = TextEditingController();
    final iconCtrl = TextEditingController(text: '🍲');
    final foodNameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '100');
    final unitCtrl = TextEditingController(text: 'g');
    final calsCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final fiberCtrl = TextEditingController();

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

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xff121219) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add Favorite Staple', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: displayNameCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: inputDecoration.copyWith(labelText: 'Display Name (e.g. Oats)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: iconCtrl,
                          style: const TextStyle(fontSize: 13),
                          textAlign: TextAlign.center,
                          decoration: inputDecoration.copyWith(labelText: 'Icon'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: foodNameCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: inputDecoration.copyWith(labelText: 'Food Name (database match)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                          decoration: inputDecoration.copyWith(labelText: 'Quantity'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: unitCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: inputDecoration.copyWith(labelText: 'Unit (e.g. g, piece)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: calsCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                          decoration: inputDecoration.copyWith(labelText: 'Calories (kcal)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: proteinCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                          decoration: inputDecoration.copyWith(labelText: 'Protein (g)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: carbsCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                          decoration: inputDecoration.copyWith(labelText: 'Carbs (g)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: fatCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                          decoration: inputDecoration.copyWith(labelText: 'Fat (g)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fiberCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: inputDecoration.copyWith(labelText: 'Fiber (g) (optional)'),
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
                if (displayNameCtrl.text.isNotEmpty && foodNameCtrl.text.isNotEmpty) {
                  final newFav = {
                    'displayName': displayNameCtrl.text,
                    'icon': iconCtrl.text,
                    'foodName': foodNameCtrl.text,
                    'qty': double.tryParse(qtyCtrl.text) ?? 1.0,
                    'unit': unitCtrl.text,
                    'cals': double.tryParse(calsCtrl.text) ?? 0.0,
                    'protein': double.tryParse(proteinCtrl.text) ?? 0.0,
                    'carbs': double.tryParse(carbsCtrl.text) ?? 0.0,
                    'fat': double.tryParse(fatCtrl.text) ?? 0.0,
                    'fiber': double.tryParse(fiberCtrl.text) ?? 0.0,
                  };
                  setState(() {
                    _favorites.add(newFav);
                  });
                  _saveFavorites();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Staple'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteFavoriteDialog(int index) {
    final fav = _favorites[index];
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xff121219) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Delete Favorite?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text('Are you sure you want to remove "${fav['displayName']}" from your favorites?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  _favorites.removeAt(index);
                });
                _saveFavorites();
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAddFoodDialog(StateService state) {
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    // Reset macro tracker values
    _foodNameController.clear();
    _quantityController.text = '100';
    _servingUnitController.text = 'g';
    _caloriesController.clear();
    _proteinController.clear();
    _carbsController.clear();
    _fatController.clear();
    _fiberController.clear();
    _baseCalories = 0.0;
    _baseProtein = 0.0;
    _baseCarbs = 0.0;
    _baseFat = 0.0;
    _baseFiber = 0.0;

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
              title: const Text('Log Food', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedMealType,
                        dropdownColor: isDark ? const Color(0xff121219) : Colors.white,
                        decoration: inputDecoration.copyWith(labelText: 'Meal Section'),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                        items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                            .map((mt) => DropdownMenuItem(value: mt, child: Text(mt)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedMealType = v!),
                      ),
                      const SizedBox(height: 12),
                      
                      // SEARCH FIELD FOR AUTOCOMPLETE
                      TextField(
                        style: const TextStyle(fontSize: 13),
                        decoration: inputDecoration.copyWith(
                          labelText: 'Search food...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                        ),
                        onChanged: (val) async {
                          if (val.trim().length < 2) {
                            setDialogState(() {
                              searchResults = [];
                              isSearching = false;
                            });
                            return;
                          }
                          
                          // 1. Search local Indian foods
                          final localMatches = state.searchFoods(val);
                          setDialogState(() {
                            searchResults = localMatches;
                            isSearching = true;
                          });

                          // 2. Fetch from Open Food Facts API asynchronously
                          final apiMatches = await state.searchOpenFoodFacts(val);
                          setDialogState(() {
                            final Set<String> names = searchResults.map((e) => e['name'].toString().toLowerCase()).toSet();
                            for (var item in apiMatches) {
                              if (!names.contains(item['name'].toString().toLowerCase())) {
                                searchResults.add(item);
                              }
                            }
                          });
                        },
                      ),

                      // AUTOCOMPLETE RESULTS PANEL
                      if (isSearching) ...[
                        const SizedBox(height: 8),
                        Container(
                          height: 130,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xff151520) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xff212130) : Colors.grey.shade200),
                          ),
                          child: searchResults.isEmpty
                              ? Center(
                                  child: Text(
                                    'Searching...',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: searchResults.length,
                                  separatorBuilder: (context, i) => Divider(height: 1.0, color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                                  itemBuilder: (context, i) {
                                    final item = searchResults[i];
                                    final name = item['name'] as String;
                                    final cals = (item['calories'] as num?)?.round() ?? 0;
                                    final source = item['source'] == 'indian-database' ? 'IN' : 'OFF';
                                    
                                    return ListTile(
                                      dense: true,
                                      title: Text(name, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                                      subtitle: Text('${item['category'] ?? ''} · $cals kcal · $source', style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                                      onTap: () {
                                        setDialogState(() {
                                          _foodNameController.text = name;
                                          final double servingSize = (item['servingSize'] as num?)?.toDouble() ?? 100.0;
                                          final double scale = servingSize > 0 ? (100.0 / servingSize) : 1.0;
                                          
                                          _baseCalories = ((item['calories'] as num?)?.toDouble() ?? 0.0) * scale;
                                          _baseProtein = ((item['protein'] as num?)?.toDouble() ?? 0.0) * scale;
                                          _baseCarbs = ((item['carbs'] as num?)?.toDouble() ?? 0.0) * scale;
                                          _baseFat = ((item['fat'] as num?)?.toDouble() ?? 0.0) * scale;
                                          _baseFiber = ((item['fiber'] as num?)?.toDouble() ?? 0.0) * scale;
                                          
                                          _quantityController.text = '100';
                                          _servingUnitController.text = 'g';
                                          
                                          isSearching = false;
                                          searchResults = [];
                                        });
                                        _updateMacrosFromQuantity();
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      TextField(
                        controller: _foodNameController,
                        style: const TextStyle(fontSize: 13),
                        decoration: inputDecoration.copyWith(labelText: 'Food Name', hintText: 'e.g. Banana'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13),
                              onChanged: (v) {
                                _updateMacrosFromQuantity();
                                setDialogState(() {});
                              },
                              decoration: inputDecoration.copyWith(labelText: 'Quantity'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _servingUnitController,
                              style: const TextStyle(fontSize: 13),
                              decoration: inputDecoration.copyWith(labelText: 'Unit (e.g. g, piece)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Macros',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff151520) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xff212130) : Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _caloriesController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (v) {
                                      _baseCalories = double.tryParse(v) ?? 0.0;
                                      final double qty = double.tryParse(_quantityController.text) ?? 100.0;
                                      if (qty > 0) _baseCalories = _baseCalories * (100.0 / qty);
                                    },
                                    decoration: inputDecoration.copyWith(labelText: 'Calories (kcal)'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _proteinController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (v) {
                                      _baseProtein = double.tryParse(v) ?? 0.0;
                                      final double qty = double.tryParse(_quantityController.text) ?? 100.0;
                                      if (qty > 0) _baseProtein = _baseProtein * (100.0 / qty);
                                    },
                                    decoration: inputDecoration.copyWith(labelText: 'Protein (g)'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _carbsController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (v) {
                                      _baseCarbs = double.tryParse(v) ?? 0.0;
                                      final double qty = double.tryParse(_quantityController.text) ?? 100.0;
                                      if (qty > 0) _baseCarbs = _baseCarbs * (100.0 / qty);
                                    },
                                    decoration: inputDecoration.copyWith(labelText: 'Carbs (g)'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _fatController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (v) {
                                      _baseFat = double.tryParse(v) ?? 0.0;
                                      final double qty = double.tryParse(_quantityController.text) ?? 100.0;
                                      if (qty > 0) _baseFat = _baseFat * (100.0 / qty);
                                    },
                                    decoration: inputDecoration.copyWith(labelText: 'Fat (g)'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _fiberController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13),
                              onChanged: (v) {
                                _baseFiber = double.tryParse(v) ?? 0.0;
                                final double qty = double.tryParse(_quantityController.text) ?? 100.0;
                                if (qty > 0) _baseFiber = _baseFiber * (100.0 / qty);
                              },
                              decoration: inputDecoration.copyWith(labelText: 'Fiber (g) (optional)'),
                            ),
                          ],
                        ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    if (_foodNameController.text.isNotEmpty) {
                      final log = FoodLog(
                        date: state.activeDate,
                        foodName: _foodNameController.text,
                        quantity: double.tryParse(_quantityController.text) ?? 1.0,
                        calories: double.tryParse(_caloriesController.text) ?? 0.0,
                        protein: double.tryParse(_proteinController.text) ?? 0.0,
                        carbs: double.tryParse(_carbsController.text) ?? 0.0,
                        fat: double.tryParse(_fatController.text) ?? 0.0,
                        fiber: double.tryParse(_fiberController.text) ?? 0.0,
                        mealType: _selectedMealType,
                        servingUnit: _servingUnitController.text,
                      );
                      state.logFood(log);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Log Food'),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Consumed glass card
            GlassCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL CONSUMED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${state.totalConsumedCalories.round()} kcal',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  Container(
                    height: 40,
                    width: 1.0,
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                  ),
                  Row(
                    children: [
                      _buildMacroSummary('Protein', state.totalConsumedProtein, Colors.orange),
                      const SizedBox(width: 16),
                      _buildMacroSummary('Carbs', state.totalConsumedCarbs, Colors.indigo),
                      const SizedBox(width: 16),
                      _buildMacroSummary('Fat', state.totalConsumedFat, Colors.yellow.shade700),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Favorites quick log card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Everyday Favorites', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(
                            '1-click to log staples · Hold to delete',
                            style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                      // Dropdown selection for Favorites
                      SizedBox(
                        height: 28,
                        child: DropdownButton<String>(
                          value: _selectedMealType,
                          underline: const SizedBox.shrink(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                          dropdownColor: isDark ? const Color(0xff121219) : Colors.white,
                          items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                              .map((mt) => DropdownMenuItem(value: mt, child: Text(mt)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedMealType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 85,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _favorites.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        if (idx == _favorites.length) {
                          // Add staple button
                          return InkWell(
                            onTap: () => _showAddFavoriteDialog(state),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 95,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xff151520).withOpacity(0.3) : Colors.grey.shade100,
                                border: Border.all(color: isDark ? const Color(0xff212130) : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 20, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add Staple',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final fav = _favorites[idx];
                        return GestureDetector(
                          onLongPress: () => _showDeleteFavoriteDialog(idx),
                          child: InkWell(
                            onTap: () => _quickLog(state, fav),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 105,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xff151520).withOpacity(0.5) : Colors.grey.shade50,
                                border: Border.all(color: isDark ? const Color(0xff212130) : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(fav['icon'] ?? '🍲', style: const TextStyle(fontSize: 18)),
                                  const SizedBox(height: 2),
                                  Text(
                                    fav['displayName'] ?? '',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${fav['qty']?.round() ?? 1}${fav['unit'] ?? ''}',
                                    style: TextStyle(fontSize: 8.5, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Food Log List sections grouped by meal types
            ...['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((mt) {
              final meals = state.foodLogs.where((f) => f.mealType == mt).toList();
              final mealCalories = meals.fold(0.0, (s, m) => s + m.calories);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
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
                            Text(mt, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(
                              '${mealCalories.round()} kcal',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff818cf8)),
                            ),
                          ],
                        ),
                      ),
                      if (meals.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No items logged for $mt.',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? Colors.grey.shade600 : Colors.grey.shade500),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: meals.length,
                          separatorBuilder: (context, idx) => Divider(
                            height: 1.0,
                            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                          ),
                          itemBuilder: (context, idx) {
                            final log = meals[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log.foodName,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${log.quantity.round()} ${log.servingUnit} · ${log.calories.round()} kcal · P: ${log.protein.round()}g · C: ${log.carbs.round()}g · F: ${log.fat.round()}g',
                                          style: TextStyle(fontSize: 9.5, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                    onPressed: () {
                                      if (log.id != null) {
                                        state.deleteFood(log.id!);
                                      }
                                    },
                                  ),
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
            const SizedBox(height: 60), // padding for floating action button
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFoodDialog(state),
        backgroundColor: const Color(0xff4f46e5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log Food', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMacroSummary(String label, double val, Color color) {
    return Column(
      children: [
        Text(
          '${val.round()}g',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
