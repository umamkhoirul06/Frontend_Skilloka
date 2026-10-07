import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D Animated AI Bot Avatar matching the Skilloka web & 3D mascot design.
///
/// Features:
/// - Smooth floating & swaying bobbing motion
/// - Natural blinking digital cyan eyes with smiling curve
/// - Glossy dark visor screen with glass reflection
/// - Metallic dark navy sphere with 3D radial highlights and gold bounce light
/// - 3D Graduation toga cap (mortarboard) with swaying cyan tassel
/// - Dual-layer golden orbit ring with dynamic perspective occlusion and revolving light flare
/// - Interactive floating message bubble ("Pesan Maseg") for mobile UX
class ChatBotAvatar3D extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;
  final bool isAnimated;
  final bool showShadow;
  final bool showRing;

  const ChatBotAvatar3D({
    super.key,
    this.size = 100.0,
    this.onTap,
    this.isAnimated = true,
    this.showShadow = true,
    this.showRing = true,
  });

  @override
  State<ChatBotAvatar3D> createState() => _ChatBotAvatar3DState();
}

class _ChatBotAvatar3DState extends State<ChatBotAvatar3D>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();

    // 1. Controller untuk melayang halus (floating up & down, rotasi ringan, flare orbit)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // 2. Controller untuk kedipan mata periodik (blinking cycle)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    if (widget.isAnimated) {
      _floatController.repeat();
      _blinkController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ChatBotAvatar3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated != oldWidget.isAnimated) {
      if (widget.isAnimated) {
        _floatController.repeat();
        _blinkController.repeat();
      } else {
        _floatController.stop();
        _blinkController.stop();
      }
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarHeight = widget.size * 1.18;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatController, _blinkController]),
          builder: (context, child) {
            // Hitung nilai floating (-1.0 s/d 1.0)
            final floatProgress =
                math.sin(_floatController.value * 2 * math.pi);
            final floatOffset = floatProgress * 6.5;

            // Hitung kedipan: mata terbuka 88% waktu, lalu berkedip cepat (tutup-buka dalam ~350ms)
            double blinkFactor = 1.0;
            final blinkVal = _blinkController.value;
            if (blinkVal >= 0.88 && blinkVal <= 0.94) {
              // Menutup mata: 1.0 -> 0.0
              blinkFactor = 1.0 - ((blinkVal - 0.88) / 0.06);
            } else if (blinkVal > 0.94 && blinkVal <= 1.0) {
              // Membuka mata: 0.0 -> 1.0
              blinkFactor = (blinkVal - 0.94) / 0.06;
            }

            return SizedBox(
              width: widget.size,
              height: avatarHeight,
              child: CustomPaint(
                size: Size(widget.size, avatarHeight),
                painter: _ChatBotAvatar3DPainter(
                  floatOffset: floatOffset,
                  blinkFactor: blinkFactor,
                  orbitProgress: _floatController.value,
                  showShadow: widget.showShadow,
                  showRing: widget.showRing,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// CustomPainter untuk menggambar visual 3D Bot Avatar secara presisi
class _ChatBotAvatar3DPainter extends CustomPainter {
  final double floatOffset;
  final double blinkFactor;
  final double orbitProgress;
  final bool showShadow;
  final bool showRing;

  _ChatBotAvatar3DPainter({
    required this.floatOffset,
    required this.blinkFactor,
    required this.orbitProgress,
    required this.showShadow,
    required this.showRing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = (size.height * 0.48) + floatOffset;
    final R = size.width * 0.285; // Radius bola kepala

    // Parameter Cincin Orbit Emas
    final ringCenter = Offset(cx, cy + R * 0.10);
    final rx = R * 1.68;
    final ry = R * 0.52;
    const tiltAngle = -0.40; // Sudut miring orbit ~23 derajat

    // ─────────────────────────────────────────────────────────────
    // LAYER 0: Bayangan Lantai di Bawah Bot
    // ─────────────────────────────────────────────────────────────
    if (showShadow) {
      final shadowScale = 1.0 - (floatOffset / 14.0);
      final shadowW = R * 1.55 * shadowScale;
      final shadowH = R * 0.28 * shadowScale;
      final shadowOpacity = (0.22 * shadowScale).clamp(0.08, 0.35);

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: shadowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, size.height - R * 0.22),
          width: shadowW,
          height: shadowH,
        ),
        shadowPaint,
      );
    }

    // ─────────────────────────────────────────────────────────────
    // LAYER 1: Belahan Belakang Cincin Orbit Emas (Lewat Belakang Bola)
    // ─────────────────────────────────────────────────────────────
    if (showRing) {
      canvas.save();
      canvas.translate(ringCenter.dx, ringCenter.dy);
      canvas.rotate(tiltAngle);

      final ringRect =
          Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);

      // Glow belakang cincin
      final backGlowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = R * 0.26
        ..color = const Color(0xFFF59E0B).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(ringRect, math.pi, math.pi, false, backGlowPaint);

      // Garis inti cincin belakang
      final backCorePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = R * 0.13
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFB45309),
            Color(0xFFF59E0B),
            Color(0xFFFBBF24),
            Color(0xFFB45309),
          ],
        ).createShader(ringRect);
      canvas.drawArc(ringRect, math.pi, math.pi, false, backCorePaint);

      // Flare orbit di bagian belakang (jika posisi orbit di separuh atas)
      final flareAngle = (orbitProgress * 2 * math.pi) % (2 * math.pi);
      if (flareAngle > math.pi) {
        final fx = rx * math.cos(flareAngle);
        final fy = ry * math.sin(flareAngle);
        final flarePaint = Paint()
          ..color = const Color(0xFFFFFBEB).withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawCircle(Offset(fx, fy), R * 0.08, flarePaint);
      }

      canvas.restore();
    }

    // ─────────────────────────────────────────────────────────────
    // LAYER 2: Kepala / Bodi Bola Metalik Navy 3D
    // ─────────────────────────────────────────────────────────────
    final sphereCenter = Offset(cx, cy);
    final sphereRect =
        Rect.fromCircle(center: sphereCenter, radius: R);

    // Gradien bola dengan specular highlight di kiri-atas dan ambient gelap di kanan-bawah
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.38, -0.42),
        radius: 1.15,
        colors: const [
          Color(0xFF38BDF8), // Specular light reflect
          Color(0xFF1E3A8A), // Vibrant navy blue
          Color(0xFF0F172A), // Deep dark navy
          Color(0xFF020617), // Deep shadow edge
        ],
        stops: const [0.0, 0.32, 0.72, 1.0],
      ).createShader(sphereRect);
    canvas.drawCircle(sphereCenter, R, spherePaint);

    // Pantulan cahaya emas cincin di bagian kanan-bawah bola (bounce light)
    final bouncePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.42, 0.45),
        radius: 0.85,
        colors: [
          const Color(0xFFF59E0B).withValues(alpha: 0.20),
          const Color(0xFFF59E0B).withValues(alpha: 0.0),
        ],
        stops: const [0.35, 1.0],
      ).createShader(sphereRect);
    canvas.drawCircle(sphereCenter, R, bouncePaint);

    // Rim lighting luar
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.25);
    canvas.drawCircle(sphereCenter, R, rimPaint);

    // ─────────────────────────────────────────────────────────────
    // LAYER 3: Topi Toga Wisuda (Mortarboard) di Atas Kepala
    // ─────────────────────────────────────────────────────────────
    final togaCenterY = cy - R * 0.95;

    // Leher / Mahkota Bawah Topi (silinder dasar topi toga)
    final baseRect = Rect.fromCenter(
      center: Offset(cx, togaCenterY + R * 0.08),
      width: R * 0.74,
      height: R * 0.24,
    );
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617)],
      ).createShader(baseRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, Radius.circular(R * 0.08)),
      basePaint,
    );

    // Bidang Diamond Mortarboard (belah ketupat datar dengan perspektif)
    final diamondTop = Offset(cx, togaCenterY - R * 0.45);
    final diamondRight = Offset(cx + R * 0.94, togaCenterY - R * 0.06);
    final diamondBottom = Offset(cx, togaCenterY + R * 0.24);
    final diamondLeft = Offset(cx - R * 0.94, togaCenterY - R * 0.06);

    // Efek ketebalan sisi bawah topi toga (drop thickness edge)
    final thicknessPath = Path()
      ..moveTo(diamondLeft.dx, diamondLeft.dy)
      ..lineTo(diamondBottom.dx, diamondBottom.dy)
      ..lineTo(diamondRight.dx, diamondRight.dy)
      ..lineTo(diamondRight.dx, diamondRight.dy + R * 0.08)
      ..lineTo(diamondBottom.dx, diamondBottom.dy + R * 0.08)
      ..lineTo(diamondLeft.dx, diamondLeft.dy + R * 0.08)
      ..close();
    canvas.drawPath(thicknessPath, Paint()..color = const Color(0xFF020617));

    // Permukaan Atas Topi Toga
    final diamondPath = Path()
      ..moveTo(diamondTop.dx, diamondTop.dy)
      ..lineTo(diamondRight.dx, diamondRight.dy)
      ..lineTo(diamondBottom.dx, diamondBottom.dy)
      ..lineTo(diamondLeft.dx, diamondLeft.dy)
      ..close();

    final diamondRect = Rect.fromCenter(
      center: Offset(cx, togaCenterY - R * 0.10),
      width: R * 1.9,
      height: R * 0.7,
    );
    final diamondPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(diamondRect);
    canvas.drawPath(diamondPath, diamondPaint);

    // Garis tepi halus topi toga
    canvas.drawPath(
      diamondPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF475569),
    );

    // Kancing Tengah Topi Toga
    final buttonCenter = Offset(cx, togaCenterY - R * 0.06);
    canvas.drawCircle(
      buttonCenter,
      R * 0.08,
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawCircle(
      buttonCenter,
      R * 0.07,
      Paint()..color = const Color(0xFF38BDF8),
    );

    // Tali Toga (Tassel Cord) & Rumbai Biru Menggantung
    final tasselSway = math.sin(orbitProgress * 2 * math.pi) * 3.5;
    final tasselCordPath = Path()
      ..moveTo(buttonCenter.dx, buttonCenter.dy)
      ..quadraticBezierTo(
        cx + R * 0.65,
        togaCenterY - R * 0.02,
        cx + R * 0.86,
        togaCenterY + R * 0.02,
      )
      ..quadraticBezierTo(
        cx + R * 0.90,
        togaCenterY + R * 0.32,
        cx + R * 0.88 + tasselSway * 0.5,
        togaCenterY + R * 0.55,
      );

    canvas.drawPath(
      tasselCordPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF38BDF8),
    );

    // Kepala Rumbai Toga
    final tasselTip = Offset(cx + R * 0.88 + tasselSway * 0.5, togaCenterY + R * 0.56);
    canvas.drawCircle(tasselTip, R * 0.05, Paint()..color = const Color(0xFF0284C7));

    // Rumbai Gantung (Brush Tassel)
    final brushPath = Path()
      ..moveTo(tasselTip.dx - R * 0.04, tasselTip.dy + R * 0.03)
      ..lineTo(tasselTip.dx + R * 0.04, tasselTip.dy + R * 0.03)
      ..lineTo(tasselTip.dx + R * 0.07 + tasselSway * 0.2, tasselTip.dy + R * 0.22)
      ..lineTo(tasselTip.dx - R * 0.07 + tasselSway * 0.2, tasselTip.dy + R * 0.22)
      ..close();
    canvas.drawPath(
      brushPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF38BDF8), Color(0xFF0284C7)],
        ).createShader(Rect.fromLTWH(tasselTip.dx - 10, tasselTip.dy, 20, 25)),
    );

    // ─────────────────────────────────────────────────────────────
    // LAYER 4: Visor Layar Kaca Hitam Glossy (Layar Wajah)
    // ─────────────────────────────────────────────────────────────
    final visorW = R * 1.28;
    final visorH = R * 0.64;
    final visorRect = Rect.fromCenter(
      center: Offset(cx, cy - R * 0.01),
      width: visorW,
      height: visorH,
    );
    final visorRRect =
        RRect.fromRectAndRadius(visorRect, Radius.circular(visorH / 2));

    // Latar Visor Hitam Pekat dengan pantulan kaca
    final visorPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A1124), Color(0xFF030712), Color(0xFF020617)],
      ).createShader(visorRect);
    canvas.drawRRect(visorRRect, visorPaint);

    // Border Frame Visor
    canvas.drawRRect(
      visorRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF1E293B),
    );

    // Pantulan Kaca Mengkilap di Bagian Atas Visor
    final glossPath = Path()
      ..addArc(
        Rect.fromCenter(
          center: Offset(cx, cy - R * 0.16),
          width: visorW * 0.88,
          height: visorH * 0.45,
        ),
        math.pi * 0.15,
        math.pi * 0.7,
      );
    canvas.drawPath(
      glossPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.white.withValues(alpha: 0.16),
    );

    // ─────────────────────────────────────────────────────────────
    // LAYER 5: Mata Digital Cyan & Senyum (Bisa Berkedip & Melengkung Bahagia)
    // ─────────────────────────────────────────────────────────────
    final eyeSpacing = R * 0.32;
    final leftEyeCenter = Offset(cx - eyeSpacing, cy - R * 0.04);
    final rightEyeCenter = Offset(cx + eyeSpacing, cy - R * 0.04);

    final eyeWidth = R * 0.28;
    final eyeMaxHeight = R * 0.18;
    final currentEyeHeight = eyeMaxHeight * blinkFactor.clamp(0.06, 1.0);

    final eyePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.072
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF00F0FF);

    final eyeGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    if (blinkFactor > 0.3) {
      // 1. Mata Tersenyum Bahagia Melengkung Ke Atas (Inverted Arc ^ ^)
      final leftEyeRect = Rect.fromCenter(
        center: leftEyeCenter,
        width: eyeWidth,
        height: currentEyeHeight * 2,
      );
      final rightEyeRect = Rect.fromCenter(
        center: rightEyeCenter,
        width: eyeWidth,
        height: currentEyeHeight * 2,
      );

      // Glow Mata
      canvas.drawArc(leftEyeRect, math.pi, math.pi, false, eyeGlowPaint);
      canvas.drawArc(rightEyeRect, math.pi, math.pi, false, eyeGlowPaint);

      // Inti Mata Cyan
      canvas.drawArc(leftEyeRect, math.pi, math.pi, false, eyePaint);
      canvas.drawArc(rightEyeRect, math.pi, math.pi, false, eyePaint);
    } else {
      // 2. Saat Berkedip (Mata menutup menjadi garis horizontal tipis)
      final halfW = eyeWidth * 0.45;
      final slitGlow = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.5)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      final slitCore = Paint()
        ..color = const Color(0xFF00F0FF)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(leftEyeCenter.dx - halfW, leftEyeCenter.dy),
        Offset(leftEyeCenter.dx + halfW, leftEyeCenter.dy),
        slitGlow,
      );
      canvas.drawLine(
        Offset(leftEyeCenter.dx - halfW, leftEyeCenter.dy),
        Offset(leftEyeCenter.dx + halfW, leftEyeCenter.dy),
        slitCore,
      );

      canvas.drawLine(
        Offset(rightEyeCenter.dx - halfW, rightEyeCenter.dy),
        Offset(rightEyeCenter.dx + halfW, rightEyeCenter.dy),
        slitGlow,
      );
      canvas.drawLine(
        Offset(rightEyeCenter.dx - halfW, rightEyeCenter.dy),
        Offset(rightEyeCenter.dx + halfW, rightEyeCenter.dy),
        slitCore,
      );
    }

    // Mulut Senyum Digital Cyan (Senyum manis robot)
    final mouthCenter = Offset(cx, cy + R * 0.12);
    final mouthW = R * 0.20;
    final mouthH = R * 0.09;
    final mouthRect = Rect.fromCenter(
      center: mouthCenter,
      width: mouthW,
      height: mouthH * 2,
    );

    final mouthGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.08
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final mouthCorePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.048
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF00F0FF);

    canvas.drawArc(mouthRect, 0, math.pi, false, mouthGlowPaint);
    canvas.drawArc(mouthRect, 0, math.pi, false, mouthCorePaint);

    // ─────────────────────────────────────────────────────────────
    // LAYER 6: Belahan Depan Cincin Orbit Emas (Lewat Depan Bodi Bola)
    // ─────────────────────────────────────────────────────────────
    if (showRing) {
      canvas.save();
      canvas.translate(ringCenter.dx, ringCenter.dy);
      canvas.rotate(tiltAngle);

      final ringRect =
          Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);

      // Glow emas menyala di depan
      final frontGlowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = R * 0.32
        ..color = const Color(0xFFF59E0B).withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawArc(ringRect, 0, math.pi, false, frontGlowPaint);

      // Cincin emas padat bergradasi
      final frontCorePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = R * 0.15
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFB45309),
            Color(0xFFF59E0B),
            Color(0xFFFEF08A),
            Color(0xFFFBBF24),
            Color(0xFFB45309),
          ],
        ).createShader(ringRect);
      canvas.drawArc(ringRect, 0, math.pi, false, frontCorePaint);

      // Kilau sorotan cahaya putih-kuning di lengkungan depan
      final highlightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = R * 0.04
        ..color = const Color(0xFFFFFBEB).withValues(alpha: 0.85);
      canvas.drawArc(ringRect, 0.20, math.pi - 0.40, false, highlightPaint);

      // Flare partikel cahaya yang berputar mengelilingi cincin di depan
      final flareAngle = (orbitProgress * 2 * math.pi) % (2 * math.pi);
      if (flareAngle <= math.pi) {
        final fx = rx * math.cos(flareAngle);
        final fy = ry * math.sin(flareAngle);
        final flareCenter = Offset(fx, fy);

        // Pendaran luar flare
        final flareOuter = Paint()
          ..color = const Color(0xFFFDE047).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(flareCenter, R * 0.16, flareOuter);

        // Pendaran inti flare
        final flareCore = Paint()..color = Colors.white;
        canvas.drawCircle(flareCenter, R * 0.065, flareCore);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ChatBotAvatar3DPainter oldDelegate) {
    return oldDelegate.floatOffset != floatOffset ||
        oldDelegate.blinkFactor != blinkFactor ||
        oldDelegate.orbitProgress != orbitProgress ||
        oldDelegate.showShadow != showShadow ||
        oldDelegate.showRing != showRing;
  }
}

/// Floating ChatBot Button lengkap dengan Pesan Speech Bubble interaktif ("Pesan Maseg").
///
/// Didesain khusus agar nyaman di perangkat mobile:
/// - Tidak menghalangi tombol penting
/// - Pesan dapat berganti otomatis atau ditutup jika diinginkan
/// - Pesan profesional tanpa emoji berlebihan
/// - Sekali klik langsung membuka Chatbot Screen
class FloatingChatBotWidget extends StatefulWidget {
  final VoidCallback onTap;
  final bool initialBubbleVisible;

  const FloatingChatBotWidget({
    super.key,
    required this.onTap,
    this.initialBubbleVisible = true,
  });

  @override
  State<FloatingChatBotWidget> createState() => _FloatingChatBotWidgetState();
}

class _FloatingChatBotWidgetState extends State<FloatingChatBotWidget>
    with SingleTickerProviderStateMixin {
  bool _isBubbleVisible = true;
  int _currentMessageIndex = 0;
  late AnimationController _bubbleFadeController;
  late Animation<double> _bubbleFadeAnimation;

  // Daftar pesan ramah & profesional (tanpa emoji berlebihan)
  final List<String> _prompts = [
    'Butuh rekomendasi kursus? Tanya AI Skilloka!',
    'Cari info LPK resmi dan jadwal pelatihan di sini.',
    'Konsultasi biaya dan pendaftaran pelatihan.',
  ];

  @override
  void initState() {
    super.initState();
    _isBubbleVisible = widget.initialBubbleVisible;
    _bubbleFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bubbleFadeAnimation =
        CurvedAnimation(parent: _bubbleFadeController, curve: Curves.easeInOut);
    _bubbleFadeController.forward();

    // Mengganti teks pesan secara berkala
    _startMessageCycle();
  }

  void _startMessageCycle() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 6));
      if (!mounted || !_isBubbleVisible) continue;

      await _bubbleFadeController.reverse();
      if (!mounted) break;

      setState(() {
        _currentMessageIndex = (_currentMessageIndex + 1) % _prompts.length;
      });
      await _bubbleFadeController.forward();
    }
  }

  @override
  void dispose() {
    _bubbleFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pesan Speech Bubble (Pesan Maseg)
          if (_isBubbleVisible)
            Flexible(
              child: FadeTransition(
                opacity: _bubbleFadeAnimation,
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 210),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 16, top: 1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Asisten Skilloka',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _prompts[_currentMessageIndex],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Tombol Tutup Bubble (X kecil)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _isBubbleVisible = false);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Avatar 3D Robot Melayang & Berkedip
          GestureDetector(
            onTap: () {
              if (!_isBubbleVisible) {
                setState(() => _isBubbleVisible = true);
                _bubbleFadeController.forward();
              }
              widget.onTap();
            },
            child: const ChatBotAvatar3D(
              size: 68,
              showShadow: true,
              showRing: true,
            ),
          ),
        ],
      ),
    );
  }
}
