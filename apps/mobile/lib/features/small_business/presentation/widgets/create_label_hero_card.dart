import 'package:flutter/material.dart';

class CreateLabelHeroCard extends StatelessWidget {
  const CreateLabelHeroCard({super.key, this.onStartCreating, this.onAddTap});

  final VoidCallback? onStartCreating;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006E2F), Color(0xFF139343), Color(0xFF22C55E)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006E2F).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative background waves
            Positioned.fill(child: CustomPaint(painter: _HeroWavePainter())),
            // Main content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: New product badge and Add button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'NEW PRODUCT',
                          style: TextStyle(
                            color: Color(0xFF006E2F),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          onTap: onAddTap ?? onStartCreating,
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.add,
                              color: Color(0xFF006E2F),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Middle section with title, subtitle, and mockup image
                  Stack(
                    children: [
                      // Product Illustration on right
                      Positioned(
                        right: -10,
                        top: 0,
                        bottom: 4,
                        width: 145,
                        child: Image.network(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuAytPI8J213u3mtbnMf8QBqTXVDomRexKHi79FBJwvQLOojdJf7PtxlVOTrtiHnJmKxIsTVcKsqY5AWvqE-6UZ3DO2R6bk1SsbCV8m1BIhP5wQ6KaAakYjBsAKnwPPmszFVRsg61UljIjk9SxMe3i5Kuj3_GpfJ310NV3SdFrdUCNVJjgcQk00Ij3BnwcQ6dwVbGa3u3MbmC95HxHEmMzmQcfK6vIamBNogT9JFqSKhDZNxZpXy3ZUpAg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.white70,
                                  size: 64,
                                ),
                              ),
                        ),
                      ),
                      // Text content (constrained to left 65%)
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 120.0,
                          bottom: 8.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Create a new label',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                height: 1.15,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Add your product details and we'll organize the information for your label.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Start Creating CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onStartCreating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF006E2F),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Start creating your label',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bottom Highlights Divider & Badges
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHighlightItem(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Legal Metrology Compliant',
                          ),
                          const SizedBox(width: 10),
                          _buildHighlightItem(
                            icon: Icons.verified_user_outlined,
                            label: 'Trusted by Small Businesses',
                          ),
                          const SizedBox(width: 10),
                          _buildHighlightItem(
                            icon: Icons.bolt_rounded,
                            label: 'Quick & Easy',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightItem({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HeroWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.15,
        size.width * 0.75,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.9,
        size.width,
        size.height * 0.5,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
