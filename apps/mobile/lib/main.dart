import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/small_business/presentation/screens/my_label_studio_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization warning: $e');
  }

  runApp(const MyLabelStudioApp());
}

class MyLabelStudioApp extends StatelessWidget {
  const MyLabelStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Label Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MyLabelStudioScreen(),
    );
  }
}
