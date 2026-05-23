import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_service.dart';
import 'overview_tab.dart';
import 'meals_tab.dart';
import 'workouts_tab.dart';
import 'insights_tab.dart';
import 'settings_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIdx = 0;

  final List<Widget> _tabs = [
    const OverviewTab(),
    const MealsTab(),
    const WorkoutsTab(),
    const InsightsTab(),
    const SettingsTab(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'label': 'Overview', 'icon': Icons.insights},
    {'label': 'Meals', 'icon': Icons.restaurant},
    {'label': 'Workout', 'icon': Icons.fitness_center},
    {'label': 'Insights', 'icon': Icons.analytics},
    {'label': 'Settings', 'icon': Icons.settings},
  ];

  String _formatFriendlyDate(String ds) {
    try {
      final dt = DateTime.parse("${ds}T00:00:00");
      final today = DateTime.now();
      final yest = today.subtract(const Duration(days: 1));

      if (dt.year == today.year && dt.month == today.month && dt.day == today.day) {
        return 'Today';
      }
      if (dt.year == yest.year && dt.month == yest.month && dt.day == yest.day) {
        return 'Yesterday';
      }
      return DateFormat('EEEE, MMM d').format(dt);
    } catch (e) {
      return ds;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<StateService>(context);
    final isDark = state.isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;

        return Scaffold(
          appBar: isWide 
              ? null 
              : AppBar(
                  backgroundColor: isDark ? const Color(0xff0d0d12) : Colors.white,
                  elevation: 0,
                  centerTitle: true,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 18),
                        onPressed: () => state.shiftDate(-1),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'VIEWING',
                            style: TextStyle(
                              fontSize: 8.5, 
                              fontWeight: FontWeight.bold, 
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            _formatFriendlyDate(state.activeDate),
                            style: TextStyle(
                              fontSize: 13, 
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 18),
                        onPressed: () => state.shiftDate(1),
                      ),
                    ],
                  ),
                  bottom: state.isDemoMode
                      ? PreferredSize(
                          preferredSize: const Size.fromHeight(16),
                          child: Container(
                            color: Colors.amber.withOpacity(0.08),
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: const Text(
                              'LOCAL DATABASE DEMO ACTIVE',
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 1.0),
                            ),
                          ),
                        )
                      : null,
                ),
          body: Stack(
            children: [
              // Ambient mesh glow highlights (floating background simulation)
              if (isDark) ...[
                Positioned(
                  left: -100,
                  top: -100,
                  width: 350,
                  height: 350,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xff6366f1).withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  right: -100,
                  bottom: -100,
                  width: 400,
                  height: 400,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xff8b5cf6).withOpacity(0.06),
                    ),
                  ),
                ),
              ],

              // Layout skeleton
              isWide 
                  ? Row(
                      children: [
                        _buildDesktopSidebar(context, state),
                        VerticalDivider(
                          width: 1.0, 
                          color: isDark ? const Color(0xff1b1b26) : Colors.grey.shade200
                        ),
                        Expanded(child: _tabs[_currentIdx]),
                      ],
                    )
                  : _tabs[_currentIdx],
            ],
          ),
          bottomNavigationBar: isWide 
              ? null 
              : BottomNavigationBar(
                  currentIndex: _currentIdx,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: isDark ? const Color(0xff0d0d12) : Colors.white,
                  selectedItemColor: const Color(0xff6366f1),
                  unselectedItemColor: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  selectedFontSize: 11,
                  unselectedFontSize: 11,
                  elevation: 8,
                  onTap: (idx) => setState(() => _currentIdx = idx),
                  items: _navItems.map((item) {
                    return BottomNavigationBarItem(
                      icon: Icon(item['icon'] as IconData, size: 20),
                      label: item['label'] as String,
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, StateService state) {
    final isDark = state.isDark;

    return Container(
      width: 240,
      color: isDark ? const Color(0xff0d0d12) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand logo header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xff6366f1), Color(0xff8b5cf6)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fitness_center, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'TrackFit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date Navigator switcher card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff181822) : Colors.grey.shade100,
              border: Border.all(color: isDark ? const Color(0xff252530) : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => state.shiftDate(-1),
                ),
                Column(
                  children: [
                    Text(
                      'VIEWING',
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                    ),
                    Text(
                      _formatFriendlyDate(state.activeDate),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => state.shiftDate(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Navigation list links
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, idx) {
                final item = _navItems[idx];
                final active = _currentIdx == idx;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: InkWell(
                    onTap: () => setState(() => _currentIdx = idx),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: active 
                            ? const Color(0xff6366f1).withOpacity(0.12) 
                            : Colors.transparent,
                        border: Border.all(
                          color: active ? const Color(0xff6366f1).withOpacity(0.3) : Colors.transparent,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 18,
                            color: active ? const Color(0xff818cf8) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: active ? FontWeight.bold : FontWeight.normal,
                              color: active ? const Color(0xff818cf8) : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // DB Active footer info block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: state.isDemoMode 
                  ? Colors.amber.withOpacity(0.08) 
                  : const Color(0xff6366f1).withOpacity(0.08),
              border: Border.all(
                color: state.isDemoMode 
                    ? Colors.amber.withOpacity(0.2) 
                    : const Color(0xff6366f1).withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: state.isDemoMode ? Colors.amber : const Color(0xff818cf8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.isDemoMode ? 'Local Storage' : 'PostgreSQL Sync',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: state.isDemoMode ? Colors.amber : const Color(0xff818cf8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Simple dummy class to emulate DateFormat since intl dependency requires importing
class DateFormat {
  final String pattern;
  DateFormat(this.pattern);

  String format(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return "${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}";
  }
}
