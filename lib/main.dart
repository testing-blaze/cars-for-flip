import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/owner_selection_page.dart';
import 'services/app_supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppSupabase.supabaseUrl,
    anonKey: AppSupabase.supabaseAnonKey,
  );

  runApp(const CarInventoryApp());
}

class CarInventoryApp extends StatelessWidget {
  const CarInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Inventory',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8), // sky blue
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFE0F2FE), // very light sky
        cardColor: Colors.transparent,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // less rounded
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          isDense: true,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0EA5E9), // sky blue app bar
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const OwnerSelectionPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

