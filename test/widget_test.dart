import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackfit_flutter/main.dart';
import 'package:trackfit_flutter/services/state_service.dart';
import 'package:trackfit_flutter/screens/onboarding_screen.dart';
import 'package:trackfit_flutter/utils/app_fonts.dart';

void main() {
  setUpAll(() {
    // Disable Google Fonts network fetching under tests to prevent exceptions and run faster
    AppFonts.useGoogleFonts = false;
  });

  testWidgets('TrackFit app onboarding and navigation flow test', (WidgetTester tester) async {
    // Reset SharedPreferences mock values to guarantee the onboarding tutorial is shown
    SharedPreferences.setMockInitialValues({
      'trackfit_onboarding_completed': false,
      'trackfit_prepopulated': true,
    });

    // Mock path_provider channel to avoid MissingPluginException in test environments
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '.'; // Return local folder
      }
      return null;
    });

    // Build our app under ChangeNotifierProvider and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => StateService(),
        child: const TrackFitApp(),
      ),
    );

    // Let background asynchronous initialization (DB FFI, JSON assets loading)
    // execute on the real event loop using tester.runAsync.
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 800));
    });

    // Pump a frame to render the screen after loading completes
    await tester.pump();

    // Verify that the OnboardingScreen is showing first
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Welcome to TrackFit'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Tap the 'Skip' button to complete the onboarding tutorial
    await tester.tap(find.text('Skip'));
    
    // Let the background shared preferences write finish on the real event loop
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });

    // Pump a frame to render the transition to the MainScreen
    await tester.pump();

    // Verify that the OnboardingScreen is removed and MainScreen is presented
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify that the main tab labels are visible
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Meals'), findsWidgets);
    expect(find.text('Workout'), findsWidgets);
  });
}
