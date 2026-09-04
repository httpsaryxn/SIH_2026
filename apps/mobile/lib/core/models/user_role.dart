import 'package:flutter/material.dart';

/// UserRole represents the 3 stakeholder roles in the Packaged Commodity Compliance Platform.
enum UserRole {
  businessOwner,
  consumer,
  regulator,
}

extension UserRoleExtension on UserRole {
  String get title {
    switch (this) {
      case UserRole.businessOwner:
        return 'Business Owner';
      case UserRole.consumer:
        return 'Consumer';
      case UserRole.regulator:
        return 'Regulator';
    }
  }

  String get description {
    switch (this) {
      case UserRole.businessOwner:
        return 'Create compliant product labels, audit packaging, and manage declarations before your products reach customers.';
      case UserRole.consumer:
        return 'Scan packaged products, understand their labels, and report potential compliance issues.';
      case UserRole.regulator:
        return 'Review complaints, investigate potential violations, and monitor compliance across businesses.';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.businessOwner:
        return Icons.business_center_rounded;
      case UserRole.consumer:
        return Icons.shopping_bag_rounded;
      case UserRole.regulator:
        return Icons.fact_check_rounded;
    }
  }

  String get authRoleLabel {
    switch (this) {
      case UserRole.businessOwner:
        return 'Signing up as a Business Owner.';
      case UserRole.consumer:
        return 'Signing up as a Consumer.';
      case UserRole.regulator:
        return 'Signing up as a Regulator.';
    }
  }

  String? get organizationFieldLabel {
    switch (this) {
      case UserRole.businessOwner:
        return 'Business / Company Name';
      case UserRole.regulator:
        return 'Department / Authority Name';
      case UserRole.consumer:
        return null;
    }
  }

  String? get organizationFieldPlaceholder {
    switch (this) {
      case UserRole.businessOwner:
        return 'Enter business or enterprise name';
      case UserRole.regulator:
        return 'Enter authority or department name';
      case UserRole.consumer:
        return null;
    }
  }
}
