import 'package:flutter/material.dart';

class ClaimsRegulatoryNoticeCard extends StatelessWidget {
  const ClaimsRegulatoryNoticeCard({
    super.key,
    this.selectedCount = 0,
  });

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFDE68A),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Regulatory Notice on Packaging Claims',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Under FSSAI Advertising and Claims Regulations (2021) & Legal Metrology Rules, all health and nutrient claims (e.g. "Low Sodium", "High Fiber") must meet Schedule I limits. Ensure test certificates are maintained at your registered facility.',
                  style: TextStyle(
                    color: const Color(0xFF92400E).withValues(alpha: 0.85),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
                if (selectedCount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF059669),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$selectedCount claim${selectedCount > 1 ? 's' : ''} selected for label front',
                        style: const TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
