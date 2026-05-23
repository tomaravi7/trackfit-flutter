import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final _quantityController = TextEditingController(text: '1');
  final _servingUnitController = TextEditingController(text: 'piece');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();

  final List<Map<String, dynamic>> _favorites = [
    {'displayName': 'Plain Chapati', 'icon': '🫓', 'foodName': 'Chapati (Plain)', 'qty': 1.0, 'unit': 'piece', 'cals': 85.0, 'protein': 3.0, 'carbs': 17.0, 'fat': 0.4, 'fiber': 2.2},
    {'displayName': 'Paneer (200g)', 'icon': '🧀', 'foodName': 'Paneer', 'qty': 200.0, 'unit': 'g', 'cals': 530.0, 'protein': 36.0, 'carbs': 6.0, 'fat': 40.0, 'fiber': 0.0},
    {'displayName': 'Toned Milk', 'icon': '🥛', 'foodName': 'Milk (Toned)', 'qty': 1.0, 'unit': 'glass', 'cals': 120.0, 'protein': 6.4, 'carbs': 9.6, 'fat': 6.0, 'fiber': 0.0},
    {'displayName': 'Whey Protein', 'icon': '🥤', 'foodName': 'Whey Protein (1 scoop)', 'qty': 1.0, 'unit': 'scoop', 'cals': 120.0, 'protein': 25.0, 'carbs': 3.0, 'fat': 1.5, 'fiber': 0.0},
    {'displayName': 'Boiled Egg', 'icon': '🥚', 'foodName': 'Egg (Boiled)', 'qty': 1.0, 'unit': 'piece', 'cals': 78.0, 'protein': 6.5, 'carbs': 0.6, 'fat': 5.5, 'fiber': 0.0},
    {'displayName': 'Steamed Rice', 'icon': '🍚', 'foodName': 'Steamed Rice', 'qty': 1.0, 'unit': 'bowl', 'cals': 200.0, 'protein': 4.0, 'carbs': 44.0, 'fat': 0.4, 'fiber': 1.4},
  ];

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

  void _showAddFoodDialog(StateService state) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = state.isDark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xff121219) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Log Custom Food', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedMealType,
                  dropdownColor: isDark ? const Color(0xff121219) : Colors.white,
                  decoration: const InputDecoration(labelText: 'Meal Type'),
                  items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                      .map((mt) => DropdownMenuItem(value: mt, child: Text(mt)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMealType = v!),
                ),
                TextField(controller: _foodNameController, decoration: const InputDecoration(labelText: 'Food Name')),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _servingUnitController, decoration: const InputDecoration(labelText: 'Unit (e.g. g, piece)'))),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _caloriesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories (kcal)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _proteinController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein (g)'))),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _carbsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs (g)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _fatController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fat (g)'))),
                  ],
                ),
                TextField(controller: _fiberController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fiber (g) (optional)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
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
                  
                  // clear forms
                  _foodNameController.clear();
                  _caloriesController.clear();
                  _proteinController.clear();
                  _carbsController.clear();
                  _fatController.clear();
                  _fiberController.clear();

                  Navigator.pop(context);
                }
              },
              child: const Text('Log Item'),
            )
          ],
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
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
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
                            '1-click to quickly log your standard daily staples',
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
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _favorites.length,
                    itemBuilder: (context, idx) {
                      final fav = _favorites[idx];
                      return InkWell(
                        onTap: () => _quickLog(state, fav),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xff151520).withOpacity(0.5) : Colors.grey.shade50,
                            border: Border.all(color: isDark ? const Color(0xff212130) : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(fav['icon'], style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 2),
                              Text(
                                fav['displayName'],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${fav['qty'].round()}${fav['unit']}',
                                style: TextStyle(fontSize: 8.5, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
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
        label: const Text('Log Custom Food', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
