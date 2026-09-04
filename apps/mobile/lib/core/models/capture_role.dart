import 'package:flutter/material.dart';

/// The 3 distinct image roles required per label scan for ML/OCR pipeline.
enum CaptureRole {
  frontLabel,
  curvedSurface,
  scaleReference,
}

/// Metadata for each [CaptureRole] — UI labels, guidance text, icons, and DB column names.
class CaptureRoleInfo {
  final CaptureRole role;
  final String label;
  final String description;
  final String guidanceText;
  final IconData icon;
  final String dbColumnName;

  const CaptureRoleInfo({
    required this.role,
    required this.label,
    required this.description,
    required this.guidanceText,
    required this.icon,
    required this.dbColumnName,
  });

  static const Map<CaptureRole, CaptureRoleInfo> all = {
    CaptureRole.frontLabel: CaptureRoleInfo(
      role: CaptureRole.frontLabel,
      label: 'Front Label',
      description: 'Full front-facing label showing PDP area & mandatory declarations',
      guidanceText: 'Position the front of the package label clearly within the frame. '
          'Ensure MRP, net quantity, and brand name are visible.',
      icon: Icons.crop_original_rounded,
      dbColumnName: 'front_label_url',
    ),
    CaptureRole.curvedSurface: CaptureRoleInfo(
      role: CaptureRole.curvedSurface,
      label: 'Curved Surface',
      description: 'Side/curved surface showing ingredients, nutritional info & manufacturer',
      guidanceText: 'Capture the side panel or curved surface showing ingredients list, '
          'nutritional table, and manufacturer/packer details.',
      icon: Icons.view_in_ar_rounded,
      dbColumnName: 'curved_surface_url',
    ),
    CaptureRole.scaleReference: CaptureRoleInfo(
      role: CaptureRole.scaleReference,
      label: 'Scale Reference',
      description: 'Close-up with scale reference for font-height measurement (PCR 2011)',
      guidanceText: 'Take a close-up photo of the declaration text with a ruler or coin '
          'placed next to it for scale reference. This is used for font-height verification.',
      icon: Icons.straighten_rounded,
      dbColumnName: 'scale_reference_url',
    ),
  };

  /// Returns the [CaptureRoleInfo] for the given [role].
  static CaptureRoleInfo forRole(CaptureRole role) => all[role]!;

  /// Ordered list of all roles in capture sequence.
  static List<CaptureRole> get orderedRoles => [
        CaptureRole.frontLabel,
        CaptureRole.curvedSurface,
        CaptureRole.scaleReference,
      ];
}
