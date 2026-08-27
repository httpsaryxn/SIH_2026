import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/onboarding/role_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FreshLabelApp());
}

class FreshLabelApp extends StatelessWidget {
  const FreshLabelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshLabel Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleSelectionScreen(),
    );
  }
}
