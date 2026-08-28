import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../../screens/regulator/regulator_home_screen.dart';
import '../../screens/consumer/consumer_home_screen.dart';
import '../../screens/small_business/small_business_home_screen.dart';
import '../../screens/large_business/large_business_home_screen.dart';

/// Centralized role-based routing utility.
/// Returns the correct home screen widget for the given user role.
class RoleRouter {
  RoleRouter._();

  /// Get the home screen widget for a given role.
  static Widget homeScreenFor(UserRole role) {
    switch (role) {
      case UserRole.regulator:
        return const RegulatorHomeScreen();
      case UserRole.consumer:
        return const ConsumerHomeScreen();
      case UserRole.smallBusiness:
        return const SmallBusinessHomeScreen();
      case UserRole.largeBusiness:
        return const LargeBusinessHomeScreen();
    }
  }

  /// Push-and-remove-all navigation to the correct home screen for the role.
  static void navigateToHome(BuildContext context, UserRole role) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => homeScreenFor(role)),
      (route) => false,
    );
  }
}
