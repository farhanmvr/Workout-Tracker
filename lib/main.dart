import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/workout.dart';
import 'models/session.dart';
import 'models/body_weight.dart';
import 'models/profile.dart';
import 'providers/workout_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(WorkoutAdapter());
  Hive.registerAdapter(SessionSetAdapter());
  Hive.registerAdapter(SessionExerciseAdapter());
  Hive.registerAdapter(WorkoutSessionAdapter());
  Hive.registerAdapter(BodyWeightRecordAdapter());
  Hive.registerAdapter(ProfileAdapter());
  
  // Open Boxes
  await Hive.openBox<Workout>('workouts');
  await Hive.openBox<WorkoutSession>('sessions');
  await Hive.openBox<BodyWeightRecord>('bodyWeights');
  await Hive.openBox<Profile>('profiles');
  await Hive.openBox('settings');

  final bool isFirstTime = Hive.box('settings').get('isFirstTime', defaultValue: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()..init()),
        ChangeNotifierProxyProvider<ProfileProvider, WorkoutProvider>(
          create: (_) => WorkoutProvider()..init(),
          update: (_, profileProps, workoutProvider) =>
              workoutProvider!..updateProfile(profileProps.activeProfileId),
        ),
        ChangeNotifierProxyProvider<ProfileProvider, StatsProvider>(
          create: (_) => StatsProvider()..init(),
          update: (_, profileProps, statsProvider) =>
              statsProvider!..updateProfile(profileProps.activeProfileId),
        ),
      ],
      child: MyApp(showOnboarding: isFirstTime),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Premium Color Palette
    const primaryCyan = Color(0xFF22D3EE);
    const secondaryIndigo = Color(0xFF818CF8);
    const slate900 = Color(0xFF0F172A);
    const slate800 = Color(0xFF1E293B);
    const slate50 = Color(0xFFF8FAFC);

    return MaterialApp(
      title: 'Workout Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryCyan,
          primary: const Color(0xFF0891B2),
          secondary: const Color(0xFF4F46E5),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: slate50,
        appBarTheme: AppBarTheme(
          backgroundColor: slate50,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.outfit(
            color: slate900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryCyan,
          primary: primaryCyan,
          secondary: secondaryIndigo,
          surface: slate800,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: slate900,
        appBarTheme: AppBarTheme(
          backgroundColor: slate900,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}

