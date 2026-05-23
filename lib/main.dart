import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/state_service.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => StateService(),
      child: const TrackFitApp(),
    ),
  );
}

class TrackFitApp extends StatelessWidget {
  const TrackFitApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<StateService>(context);

    return MaterialApp(
      title: 'TrackFit',
      debugShowCheckedModeBanner: false,
      themeMode: state.isDark ? ThemeMode.dark : ThemeMode.light,
      
      // Light Theme Configurations
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xff4f46e5),
        colorScheme: const ColorScheme.light(
          primary: Color(0xff4f46e5),
          secondary: Color(0xff6366f1),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xfff9fafb),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
          titleLarge: GoogleFonts.plusJakartaSans(
            textStyle: ThemeData.light().textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            textStyle: ThemeData.light().textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                ),
          ),
        ),
        dividerColor: Colors.grey.shade200,
      ),

      // Dark Theme Configurations
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xff4f46e5),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xff4f46e5),
          secondary: Color(0xff818cf8),
          surface: Color(0xff0d0d12),
        ),
        scaffoldBackgroundColor: const Color(0xff07070c),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          titleLarge: GoogleFonts.plusJakartaSans(
            textStyle: ThemeData.dark().textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            textStyle: ThemeData.dark().textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: Colors.white,
                ),
          ),
        ),
        dividerColor: const Color(0xff1b1b26),
      ),
      
      home: const MainScreen(),
    );
  }
}
