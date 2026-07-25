import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../extensions/context_extension.dart';

class LoginRequiredScreen extends StatefulWidget {
  const LoginRequiredScreen({
    super.key,
    this.onLogin,
    this.showBackButton = true,
  });

  final VoidCallback? onLogin;
  final bool showBackButton;

  @override
  State<LoginRequiredScreen> createState() => _LoginRequiredScreenState();
}

class _LoginRequiredScreenState extends State<LoginRequiredScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _orbitCtrl;

  // ── Entry animations ─────────────────────────────────────────────────────────
  late final Animation<double> _bgFade;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;
  late final Animation<double> _btnScale;

  // ── Idle animations ──────────────────────────────────────────────────────────
  late final Animation<double> _pulse;
  late final Animation<double> _orbit;

  // ── Button press state ───────────────────────────────────────────────────────
  bool _btnPressed = false;

  // ── Palette — white bg / black accent ────────────────────────────────────────
  static const _bg          = Color(0xFFFFFFFF);
  static const _surface     = Color(0xFFF7F7F7);
  static const _surfaceHigh = Color(0xFFF0F0F0);
  static const _black       = Color(0xFF0A0A0A);
  static const _blackMid    = Color(0xFF1A1A1A);
  static const _textPrimary = Color(0xFF0A0A0A);
  static const _textSub     = Color(0xFF5A5A6A);
  static const _textMuted   = Color(0xFFAAAAAA);
  static const _divider     = Color(0xFFE8E8E8);
  static const _orbitColor  = Color(0xFF333333);

  @override
  void initState() {
    super.initState();

    // ── Entry (one-shot, 1 000 ms) ───────────────────────────────────────────
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _bgFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _iconFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.05, 0.5, curve: Curves.easeOut),
    );

    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.05, 0.55, curve: Curves.elasticOut),
      ),
    );

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _cardFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.3, 0.72, curve: Curves.easeOut),
    );

    _btnScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.58, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // ── Pulse (looping shadow breath behind icon) ────────────────────────────
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // ── Orbit ring ───────────────────────────────────────────────────────────
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _orbit = Tween<double>(begin: 0.0, end: math.pi * 2).animate(_orbitCtrl);

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.showBackButton,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: widget.showBackButton
            ? AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        )
            : null,
        body: FadeTransition(
          opacity: _bgFade,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  _buildIconSection(),
                  const SizedBox(height: 40),
                  _buildTextSection(),
                  const SizedBox(height: 50),
                  _buildFooterSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Icon section ─────────────────────────────────────────────────────────────
  Widget _buildIconSection() {
    return FadeTransition(
      opacity: _iconFade,
      child: ScaleTransition(
        scale: _iconScale,
        child: SizedBox(
          height: 210,
          width: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Breathing shadow halo (light grey on white)
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  height: 210,
                  width: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          0.04 + _pulse.value * 0.06,
                        ),
                        blurRadius: 50 + _pulse.value * 25,
                        spreadRadius: 4 + _pulse.value * 6,
                      ),
                    ],
                  ),
                ),
              ),

              // Outer orbit ring (rotating dashes)
              AnimatedBuilder(
                animation: _orbit,
                builder: (_, __) => CustomPaint(
                  size: const Size(198, 198),
                  painter: _OrbitRingPainter(
                    angle: _orbit.value,
                    color: _orbitColor.withOpacity(0.18),
                  ),
                ),
              ),

              // Static mid ring
              Container(
                height: 164,
                width: 164,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _divider,
                    width: 1,
                  ),
                ),
              ),

              // Core disc — black circle
              Container(
                height: 116,
                width: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle white radial gradient inside disc
                    Container(
                      height: 116,
                      width: 116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.10),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.75],
                        ),
                      ),
                    ),
                    // Lock icon
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Text section ─────────────────────────────────────────────────────────────
  Widget _buildTextSection() {
    return SlideTransition(
      position: _cardSlide,
      child: FadeTransition(
        opacity: _cardFade,
        child: Column(
          children: [
            // Pill label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _surfaceHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _divider),
              ),
              child: Text(
                context.tr('login_required_title'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                  letterSpacing: 0.9,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Description
            Text(
              context.tr('login_required_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: _textSub,
                height: 1.7,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),

            const SizedBox(height: 28),

            // Decorative dot-pill row
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     _dot(),
            //     const SizedBox(width: 7),
            //     _dot(large: true),
            //     const SizedBox(width: 7),
            //     _dot(),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  Widget _dot({bool large = false}) => Container(
    height: large ? 5 : 4,
    width: large ? 20 : 4,
    decoration: BoxDecoration(
      color: large ? _black : _divider,
      borderRadius: BorderRadius.circular(99),
    ),
  );

  // ── Footer section ───────────────────────────────────────────────────────────
  Widget _buildFooterSection() {
    return ScaleTransition(
      scale: _btnScale,
      child: Column(
        children: [
          // Benefit chips
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     _chip(Icons.bolt_rounded, 'Instant Access'),
          //     const SizedBox(width: 10),
          //     _chip(Icons.shield_outlined, 'Secure Login'),
          //   ],
          // ),

          // const SizedBox(height: 20),

          // CTA — solid black button
          GestureDetector(
            onTapDown: (_) => setState(() => _btnPressed = true),
            onTapUp: (_) => setState(() => _btnPressed = false),
            onTapCancel: () => setState(() => _btnPressed = false),
            child: AnimatedScale(
              scale: _btnPressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 90),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _black,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.22),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onLogin,
                      borderRadius: BorderRadius.circular(16),
                      splashColor: Colors.white.withOpacity(0.06),
                      highlightColor: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.login_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.tr('login_now'),
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Hint
          // Text(
          //   context.tr('login_required_hint'),
          //   textAlign: TextAlign.center,
          //   style: const TextStyle(
          //     color: _textMuted,
          //     fontSize: 12.5,
          //     fontWeight: FontWeight.w400,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _divider),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _textSub),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _textSub,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// ── Orbit ring painter ────────────────────────────────────────────────────────
class _OrbitRingPainter extends CustomPainter {
  const _OrbitRingPainter({required this.angle, required this.color});

  final double angle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const dashCount  = 6;
    const dashLength = 0.22; // radians

    for (int i = 0; i < dashCount; i++) {
      final start = angle + (math.pi * 2 / dashCount) * i;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start,
        dashLength,
        false,
        paint,
      );
    }

    // Two small accent dots on the ring
    for (int i = 0; i < 2; i++) {
      final a  = angle + math.pi * i;
      final dx = cx + r * math.cos(a);
      final dy = cy + r * math.sin(a);
      canvas.drawCircle(
        Offset(dx, dy),
        2.8,
        Paint()..color = color.withOpacity(0.85),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitRingPainter old) =>
      old.angle != angle || old.color != color;
}