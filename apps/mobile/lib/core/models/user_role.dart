import 'package:flutter/material.dart';

/// UserRole represents the 4 stakeholder roles in the Packaged Commodity Compliance Platform.
enum UserRole {
  smallBusiness,
  largeBusiness,
  consumer,
  regulator,
}

extension UserRoleExtension on UserRole {
  String get title {
    switch (this) {
      case UserRole.smallBusiness:
        return 'Small Business';
      case UserRole.largeBusiness:
        return 'Large Business';
      case UserRole.consumer:
        return 'Consumer';
      case UserRole.regulator:
        return 'Regulator';
    }
  }

  String get description {
    switch (this) {
      case UserRole.smallBusiness:
        return 'Create compliant product labels and check your packaging before it reaches customers.';
      case UserRole.largeBusiness:
        return 'Audit product labels, manage compliance issues, and track packaging changes across products.';
      case UserRole.consumer:
        return 'Scan packaged products, understand their labels, and report potential compliance issues.';
      case UserRole.regulator:
        return 'Review complaints, investigate potential violations, and monitor compliance across businesses.';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.smallBusiness:
        return Icons.storefront_rounded;
      case UserRole.largeBusiness:
        return Icons.domain_rounded;
      case UserRole.consumer:
        return Icons.shopping_bag_rounded;
      case UserRole.regulator:
        return Icons.fact_check_rounded;
    }
  }

  String get authRoleLabel {
    switch (this) {
      case UserRole.smallBusiness:
        return 'Signing up as a Small Business.';
      case UserRole.largeBusiness:
        return 'Signing up as a Large Business.';
      case UserRole.consumer:
        return 'Signing up as a Consumer.';
      case UserRole.regulator:
        return 'Signing up as a Regulator.';
    }
  }

  String? get organizationFieldLabel {
    switch (this) {
      case UserRole.smallBusiness:
        return 'Business Name';
      case UserRole.largeBusiness:
        return 'Company Name';
      case UserRole.regulator:
        return 'Department / Authority Name';
      case UserRole.consumer:
        return null;
    }
  }

  String? get organizationFieldPlaceholder {
    switch (this) {
      case UserRole.smallBusiness:
        return 'Enter business name';
      case UserRole.largeBusiness:
        return 'Enter organization name';
      case UserRole.regulator:
        return 'Enter authority or department name';
      case UserRole.consumer:
        return null;
    }
  }
}
