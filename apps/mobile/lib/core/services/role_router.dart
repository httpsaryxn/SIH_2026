import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../../screens/regulator/regulator_home_screen.dart';
import '../../screens/consumer/consumer_home_screen.dart';
import '../../screens/business_owner/business_owner_home_screen.dart';

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
      case UserRole.businessOwner:
        return const BusinessOwnerHomeScreen();
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
