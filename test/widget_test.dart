import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trackfit_flutter/main.dart';
import 'package:trackfit_flutter/services/state_service.dart';

void main() {
  testWidgets('TrackFit app smoke test', (WidgetTester tester) async {
    // Build our app under ChangeNotifierProvider and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => StateService(),
        child: const TrackFitApp(),
      ),
    );

    // Let the initial database loading finish (pump once and then pump a small duration)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the BottomNavigationBar is present on mobile sizes
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify that some of our nav tab labels are present
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Meals'), findsWidgets);
    expect(find.text('Workout'), findsWidgets);
  });
}
