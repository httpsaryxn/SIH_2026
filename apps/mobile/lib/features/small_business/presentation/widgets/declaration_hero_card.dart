import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DeclarationHeroCard extends StatelessWidget {
  const DeclarationHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006E2F), Color(0xFF1E8745)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006E2F).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ambient blurred glow shapes
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: 30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandFreshGreen.withValues(alpha: 0.2),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column (Text)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tell us about your product',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add the essential details to start building your compliant label.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Every great product deserves a label that tells its story.',
                          style: TextStyle(
                            color: Color(0xFF9AF7A8),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right Column (Illustration)
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCLmR4T8NhYRyOxtozjaMp4e7VyMiZVspHHwGfg5mwGYof7_yeMLJuAgTXA60eCBk3QHEHr5N9QTv2s_FwxB1YjJ5ctdp_zJNPjyyREoioS8cbLXX4yJ-3c4-dUW658Pnwzi2K8aNDsEls_mM_VqI9D4nX5qrfr1U2osZeIi48JTMv5lyKfb766eURnHLlQyZFxaNE8OwnaTkkvNwlOmU2leV3XsCq-hDd7Q4JvxsQrPixohZdxoL56JQ',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.white70,
                              size: 36,
                            ),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
