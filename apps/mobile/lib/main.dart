import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/small_business/presentation/screens/my_label_studio_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
