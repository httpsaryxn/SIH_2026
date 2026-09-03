import 'package:flutter/material.dart';

class CreateLabelHeroCard extends StatelessWidget {
  const CreateLabelHeroCard({super.key, this.onStartCreating, this.onAddTap});

  final VoidCallback? onStartCreating;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF00672E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00672E).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Dark green wave background shape matching Figma design
            Positioned.fill(child: CustomPaint(painter: _HeroWavePainter())),
            // Main content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: NEW PRODUCT badge and Add button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'NEW PRODUCT',
                          style: TextStyle(
                            color: Color(0xFF00672E),
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
                              color: Color(0xFF00672E),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Middle section: Title, Subtitle, and Product Mockup Graphic
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Text content (left side)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Create a\nnew label',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                height: 1.12,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Add your product details\nand we'll organize the\ninformation for your label.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Product Graphic on right (Label Sheet + Turmeric Pouch + Pickle Jar)
                      const _ProductMockupIllustration(),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Start Creating CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onStartCreating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF00672E),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Flexible(
                            child: Text(
                              'Start creating your label',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF00672E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: Color(0xFF00672E),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bottom Highlights Row (2-line text badges matching Figma reference)
                  Container(
                    padding: const EdgeInsets.only(top: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildHighlightItem(
                            icon: Icons.check_circle_outline_rounded,
                            line1: 'Legal Metrology',
                            line2: 'Compliant',
                          ),
                        ),
                        Expanded(
                          child: _buildHighlightItem(
                            icon: Icons.check_circle_outline_rounded,
                            line1: 'Trusted by Small',
                            line2: 'Businesses',
                          ),
                        ),
                        Expanded(
                          child: _buildHighlightItem(
                            icon: Icons.bolt_outlined,
                            line1: 'Quick &',
                            line2: 'Easy',
                          ),
                        ),
                      ],
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

  Widget _buildHighlightItem({
    required IconData icon,
    required String line1,
    required String line2,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.0),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                line1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                line2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Seamless Product Mockup Illustration matching Figma reference image:
/// 1. White label document sheet (background left)
/// 2. Dark green stand-up pouch labeled "PREMIUM TURMERIC POWDER" (middle center)
/// 3. Glass jar of yellow turmeric pickle with cloth cap and jute twine tie (foreground right)
class _ProductMockupIllustration extends StatelessWidget {
  const _ProductMockupIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Soft ambient drop shadow under mockup cluster
          Positioned(
            right: 8,
            bottom: 6,
            child: Container(
              width: 110,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // 1. Back-Left: White Label Document Sheet
          Positioned(
            left: 0,
            top: 10,
            child: Transform.rotate(
              angle: -0.10, // ~6 degree left tilt
              child: Container(
                width: 54,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 8,
                      offset: const Offset(-2, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Green top header bar on label sheet
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00672E),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Center(
                        child: Text(
                          'DECLARATION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 4,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Line items simulating label details
                    Container(height: 2, width: 36, color: const Color(0xFF424242)),
                    const SizedBox(height: 2),
                    Container(height: 1.5, width: 28, color: const Color(0xFF757575)),
                    const SizedBox(height: 3),
                    // Mini simulated Nutrition Facts Table Grid
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFBDBDBD), width: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(height: 1.5, width: 14, color: Colors.black87),
                              Container(height: 1.5, width: 8, color: Colors.black87),
                            ],
                          ),
                          const SizedBox(height: 1.5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(height: 1.2, width: 12, color: Colors.grey),
                              Container(height: 1.2, width: 6, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 1.5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(height: 1.2, width: 10, color: Colors.grey),
                              Container(height: 1.2, width: 7, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Mini Barcode at bottom of label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        8,
                        (index) => Container(
                          width: index % 2 == 0 ? 1.5 : 1.0,
                          height: 9,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Middle: Dark Green Stand-Up Pouch ("PREMIUM TURMERIC POWDER")
          Positioned(
            left: 36,
            top: 2,
            child: Container(
              width: 62,
              height: 92,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF074E27),
                    Color(0xFF033319),
                    Color(0xFF01210F),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Top Seal Notch bar
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFF011A0B),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.amber.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gold Decorative Framing & Text
                  Positioned.fill(
                    top: 10,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Gold Emblem / Mandala Icon
                          const Icon(
                            Icons.auto_awesome,
                            size: 10,
                            color: Color(0xFFFFD54F),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          // Bold Title
                          const Text(
                            'TURMERIC',
                            style: TextStyle(
                              color: Color(0xFFFFF59D),
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const Text(
                            'POWDER',
                            style: TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 6,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Gold circular artwork line
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.spa_rounded,
                              size: 10,
                              color: Color(0xFFFFD54F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Foreground-Right: Glass Jar of Yellow Pickle with Jute String Tie
          Positioned(
            right: 0,
            bottom: 2,
            child: SizedBox(
              width: 52,
              height: 64,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Glass Jar Body filled with Turmeric / Mango Pickle
                  Container(
                    width: 48,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFF176),
                          Color(0xFFFFB300),
                          Color(0xFFE65100),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.32),
                          blurRadius: 8,
                          offset: const Offset(1, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Glass Highlight Specular Line
                        Positioned(
                          left: 4,
                          top: 4,
                          bottom: 4,
                          child: Container(
                            width: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Jar Label Sticker
                        Center(
                          child: Container(
                            width: 32,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 2,
                                  color: const Color(0xFF00672E),
                                ),
                                const SizedBox(height: 1.5),
                                const Text(
                                  'PICKLE',
                                  style: TextStyle(
                                    fontSize: 5.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00672E),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Jar Neck & Jute Tied Cloth/Lid Cover
                  Positioned(
                    top: 0,
                    child: Column(
                      children: [
                        // Glass Rim / Fabric Cap Top Cover
                        Container(
                          width: 38,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7CCC8), // Fabric cloth cap
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 1.5,
                              color: const Color(0xFFA1887F),
                            ),
                          ),
                        ),
                        // Jute String wrapped around lid neck with bow knot
                        Container(
                          width: 42,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8D6E63), // Jute twine color
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: const Color(0xFF6D4C41),
                              width: 0.6,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.all_inclusive,
                                size: 5,
                                color: Color(0xFFFFECB3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF005224)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.60,
        size.width * 0.70,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.38,
        size.width,
        size.height * 0.48,
      )
      ..lineTo(size.width, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.70,
        0,
        size.height * 0.75,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
