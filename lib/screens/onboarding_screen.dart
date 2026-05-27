import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_service.dart';
import '../utils/app_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIdx = 0;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: 'Welcome to TrackFit',
      description: 'Your premium fitness, water tracker, meals log, and workout tracker in one elegant interface.',
      icon: Icons.spa,
      gradient: const [Color(0xff4f46e5), Color(0xff6366f1)],
    ),
    OnboardingSlideData(
      title: 'Log Nutrition & Macros',
      description: 'Quick log your everyday staple meals, track proteins, carbs, fats, and fiber with auto-scaling metrics.',
      icon: Icons.restaurant,
      gradient: const [Color(0xfff97316), Color(0xffef4444)],
    ),
    OnboardingSlideData(
      title: 'Train & Rest Timer',
      description: 'Log exercise sets, reps, weights, and primary target muscle groups. Keep pacing with the integrated stopwatch rest timer.',
      icon: Icons.fitness_center,
      gradient: const [Color(0xff8b5cf6), Color(0xffec4899)],
    ),
    OnboardingSlideData(
      title: 'Visual Insights',
      description: 'Track progress with interactive charts, consistency calendars, and a dynamic target muscle body heatmap.',
      icon: Icons.analytics,
      gradient: const [Color(0xff10b981), Color(0xff14b8a6)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext(StateService state) {
    if (_currentIdx < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      state.completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<StateService>(context);
    final isDark = state.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff07070c) : const Color(0xfff9fafb),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient mesh glow background highlights in dark mode
            if (isDark) ...[
              Positioned(
                left: -120,
                top: -120,
                width: 380,
                height: 380,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xff6366f1).withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                right: -120,
                bottom: -120,
                width: 380,
                height: 380,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xff8b5cf6).withOpacity(0.04),
                  ),
                ),
              ),
            ],

            // Content Column
            Column(
              children: [
                // Top header with Skip button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => state.completeOnboarding(),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          'Skip',
                          style: AppFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Carousel slides
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentIdx = idx),
                    itemCount: _slides.length,
                    itemBuilder: (context, idx) {
                      final slide = _slides[idx];
                      return _buildSlide(slide, isDark);
                    },
                  ),
                ),

                // Footer layout (Indicators + Action button)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Indicators
                      Row(
                        children: List.generate(_slides.length, (index) {
                          final active = _currentIdx == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6.0),
                            height: 6,
                            width: active ? 18 : 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xff4f46e5)
                                  : (isDark ? const Color(0xff27273a) : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),

                      // Next/Get Started Button
                      ElevatedButton(
                        onPressed: () => _onNext(state),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4f46e5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: const Color(0xff4f46e5).withOpacity(0.4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentIdx == _slides.length - 1 ? 'Get Started' : 'Next',
                              style: AppFonts.plusJakartaSans(
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _currentIdx == _slides.length - 1 ? Icons.done : Icons.chevron_right,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlideData slide, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Graphic container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slide.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: slide.gradient.first.withOpacity(0.35),
                  blurRadius: 36,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                slide.icon,
                size: 54,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppFonts.plusJakartaSans(
              textStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: AppFonts.inter(
              textStyle: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSlideData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  OnboardingSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
