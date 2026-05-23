import 'dart:math';
import 'package:flutter/material.dart';

class MuscleGroup {
  final String id;
  final String name;
  final List<String> exerciseNames;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rx;
  final String side;
  final String category;

  MuscleGroup({
    required this.id,
    required this.name,
    required this.exerciseNames,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rx = 6.0,
    required this.side,
    required this.category,
  });
}

final List<MuscleGroup> muscleGroups = [
  MuscleGroup(id: 'shoulders', name: 'Shoulders', exerciseNames: ['shoulder', 'delt', 'overhead press', 'lateral raise'], x: 105, y: 50, width: 90, height: 22, rx: 6, side: 'front', category: 'upper'),
  MuscleGroup(id: 'chest', name: 'Chest', exerciseNames: ['bench', 'chest', 'fly', 'pushup', 'push-up', 'incline', 'decline'], x: 115, y: 78, width: 70, height: 28, rx: 6, side: 'front', category: 'upper'),
  MuscleGroup(id: 'biceps', name: 'Biceps', exerciseNames: ['bicep', 'curl', 'hammer curl', 'preacher'], x: 82, y: 80, width: 22, height: 38, rx: 5, side: 'front', category: 'upper'),
  MuscleGroup(id: 'abs', name: 'Abs', exerciseNames: ['ab', 'crunch', 'plank', 'core', 'sit-up', 'cable crunch', 'leg raise'], x: 128, y: 112, width: 44, height: 42, rx: 6, side: 'front', category: 'upper'),
  MuscleGroup(id: 'forearms', name: 'Forearms', exerciseNames: ['wrist', 'forearm', 'grip', 'reverse curl'], x: 78, y: 124, width: 20, height: 34, rx: 5, side: 'front', category: 'upper'),
  MuscleGroup(id: 'quads', name: 'Quads', exerciseNames: ['squat', 'leg press', 'lunge', 'leg extension', 'quad', 'front squat', 'hack squat'], x: 112, y: 160, width: 76, height: 52, rx: 6, side: 'front', category: 'lower'),
  MuscleGroup(id: 'calves', name: 'Calves', exerciseNames: ['calf', 'raise', 'seated calf'], x: 120, y: 218, width: 60, height: 42, rx: 6, side: 'front', category: 'lower'),
  MuscleGroup(id: 'traps', name: 'Traps', exerciseNames: ['shrug', 'trap', 'upright row', 'face pull'], x: 120, y: 48, width: 60, height: 22, rx: 6, side: 'back', category: 'upper'),
  MuscleGroup(id: 'lats', name: 'Lats', exerciseNames: ['lat', 'pull-up', 'pull down', 'row', 'deadlift', 't-bar row', 'cable row'], x: 105, y: 76, width: 90, height: 42, rx: 6, side: 'back', category: 'upper'),
  MuscleGroup(id: 'triceps', name: 'Triceps', exerciseNames: ['tricep', 'dip', 'skull crusher', 'pushdown', 'overhead extension'], x: 82, y: 80, width: 22, height: 38, rx: 5, side: 'back', category: 'upper'),
  MuscleGroup(id: 'lower-back', name: 'Lower Back', exerciseNames: ['deadlift', 'good morning', 'back extension', 'hyperextension', 'rack pull'], x: 126, y: 124, width: 48, height: 28, rx: 6, side: 'back', category: 'upper'),
  MuscleGroup(id: 'glutes', name: 'Glutes', exerciseNames: ['glute', 'hip thrust', 'bridge', 'deadlift', 'kickback', 'cable pull-through'], x: 115, y: 158, width: 70, height: 30, rx: 6, side: 'back', category: 'lower'),
  MuscleGroup(id: 'hamstrings', name: 'Hamstrings', exerciseNames: ['hamstring', 'leg curl', 'rdl', 'romanian', 'nordic curl'], x: 112, y: 194, width: 76, height: 44, rx: 6, side: 'back', category: 'lower'),
];

class BodyHeatmap extends StatefulWidget {
  final List<dynamic> workoutLogs;

  const BodyHeatmap({Key? key, required this.workoutLogs}) : super(key: key);

  @override
  State<BodyHeatmap> createState() => _BodyHeatmapState();
}

class _BodyHeatmapState extends State<BodyHeatmap> {
  String? _selectedMuscleId;
  String _mobileView = 'front'; // 'front' or 'back'

  // Helper colors
  Map<String, Color> _getHeatFill(int totalSets) {
    if (totalSets == 0) return {'base': const Color(0xff1f1f2e).withOpacity(0.4), 'glow': Colors.transparent};
    if (totalSets < 3) return {'base': const Color(0xff064e3b).withOpacity(0.65), 'glow': const Color(0xff10b981).withOpacity(0.15)};
    if (totalSets < 6) return {'base': const Color(0xff047857).withOpacity(0.7), 'glow': const Color(0xff10b981).withOpacity(0.25)};
    if (totalSets < 9) return {'base': const Color(0xffa16207).withOpacity(0.75), 'glow': const Color(0xffeab308).withOpacity(0.25)};
    if (totalSets < 12) return {'base': const Color(0xffc2410c).withOpacity(0.8), 'glow': const Color(0xfff97316).withOpacity(0.3)};
    return {'base': const Color(0xffdc2626).withOpacity(0.85), 'glow': const Color(0xffef4444).withOpacity(0.35)};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate sets per muscle
    final Map<String, int> muscleSets = {};
    final Map<String, List<String>> muscleExercises = {};

    for (var mg in muscleGroups) {
      final matchingLogs = widget.workoutLogs.where((log) {
        final name = (log.exerciseName as String).toLowerCase();
        return mg.exerciseNames.any((item) => name.contains(item));
      }).toList();
      
      muscleSets[mg.id] = matchingLogs.length;
      muscleExercises[mg.id] = matchingLogs
          .map((l) => l.exerciseName as String)
          .toSet()
          .toList();
    }

    final selectedGroup = _selectedMuscleId != null 
        ? muscleGroups.firstWhere((m) => m.id == _selectedMuscleId) 
        : null;

    return Column(
      children: [
        // Silhouette Toggle View (Mobile toggle, Desktop displays side-by-side)
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 500;
            if (isDesktop) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSilhouette(context, 'front', muscleSets),
                  _buildSilhouette(context, 'back', muscleSets),
                ],
              );
            } else {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildToggleButton('Front', _mobileView == 'front', () => setState(() => _mobileView = 'front')),
                      const SizedBox(width: 8),
                      _buildToggleButton('Back', _mobileView == 'back', () => setState(() => _mobileView = 'back')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSilhouette(context, _mobileView, muscleSets),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 16),

        // Heatmap Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Cold', style: TextStyle(fontSize: 10, color: isDark ? Colors.zinc.shade500 : Colors.grey.shade500)),
            const SizedBox(width: 6),
            Row(
              children: [
                const Color(0xff1f1f2e),
                const Color(0xff064e3b),
                const Color(0xff047857),
                const Color(0xffa16207),
                const Color(0xffc2410c),
                const Color(0xffdc2626)
              ].map((c) => Container(width: 14, height: 8, color: c)).toList(),
            ),
            const SizedBox(width: 6),
            Text('Hot', style: TextStyle(fontSize: 10, color: isDark ? Colors.zinc.shade500 : Colors.grey.shade500)),
          ],
        ),

        const SizedBox(height: 16),

        // Selected Muscle Detail Panel
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: selectedGroup != null
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xff151520).withOpacity(0.5) : Colors.grey.shade50.withOpacity(0.5),
                    border: Border.all(
                      color: isDark ? const Color(0xff212130) : Colors.grey.shade200,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getHeatFill(muscleSets[selectedGroup.id] ?? 0)['base'],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedGroup.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.zinc.shade200 : Colors.grey.shade900,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${muscleSets[selectedGroup.id] ?? 0} sets logged',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.zinc.shade500 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (muscleExercises[selectedGroup.id]?.isNotEmpty ?? false)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: muscleExercises[selectedGroup.id]!.map((ex) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xff6366f1).withOpacity(0.12),
                                border: Border.all(color: const Color(0xff6366f1).withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                ex,
                                style: const TextStyle(fontSize: 10, color: Color(0xff818cf8), fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'No exercises logged for this muscle group today.',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? Colors.zinc.shade600 : Colors.grey.shade500),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active 
              ? const Color(0xff4f46e5) 
              : (Theme.of(context).brightness == Brightness.dark ? const Color(0xff181822) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.zinc.shade400 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildSilhouette(BuildContext context, String side, Map<String, int> sets) {
    final sideGroups = muscleGroups.where((m) => m.side == side).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          side.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: isDark ? Colors.zinc.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 300,
          height: 280,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Silhouette graphic base outline
              Positioned.fill(
                child: CustomPaint(
                  painter: _SilhouettePainter(isDark: isDark),
                ),
              ),

              // Interactive muscle buttons mapped onto the graphic coordinates
              ...sideGroups.map((mg) {
                final totalSets = sets[mg.id] ?? 0;
                final colors = _getHeatFill(totalSets);
                final isSelected = _selectedMuscleId == mg.id;

                return Positioned(
                  left: mg.x,
                  top: mg.y,
                  width: mg.width,
                  height: mg.height,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (_selectedMuscleId == mg.id) {
                          _selectedMuscleId = null;
                        } else {
                          _selectedMuscleId = mg.id;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(mg.rx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: colors['base'],
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xff6366f1) 
                              : const Color(0xff3f3f50).withOpacity(0.3),
                          width: isSelected ? 1.5 : 0.5,
                        ),
                        borderRadius: BorderRadius.circular(mg.rx),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xff6366f1).withOpacity(0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          mg.name,
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  final bool isDark;

  _SilhouettePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final bgPaint = Paint()
      ..color = isDark ? Colors.zinc.shade900.withOpacity(0.4) : Colors.grey.shade200.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Draw a simplified silhouette using oval and rect paths to mimic body segments
    // Head
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 26), width: 36, height: 44),
      bgPaint,
    );

    // Torso & Limbs
    final torsoPath = Path()
      ..moveTo(122, 46)
      ..quadraticBezierTo(135, 40, 150, 38)
      ..quadraticBezierTo(165, 40, 178, 46)
      ..lineTo(182, 56)
      ..lineTo(176, 62)
      ..lineTo(176, 96)
      ..lineTo(182, 104)
      ..lineTo(182, 162)
      ..lineTo(174, 168)
      ..lineTo(174, 224)
      ..lineTo(166, 258)
      ..lineTo(160, 278)
      ..lineTo(154, 278)
      ..lineTo(150, 260)
      ..lineTo(146, 278)
      ..lineTo(140, 278)
      ..lineTo(134, 258)
      ..lineTo(126, 224)
      ..lineTo(126, 168)
      ..lineTo(118, 162)
      ..lineTo(118, 104)
      ..lineTo(124, 96)
      ..lineTo(124, 62)
      ..lineTo(118, 56)
      ..close();

    canvas.drawPath(torsoPath, bgPaint);
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
