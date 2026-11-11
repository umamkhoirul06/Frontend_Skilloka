/// Skilloka Interactive Brand Loading Indicator
/// Engaging, delightful, and informative loading animation with animated pulse and rotating tips.
library;

import 'dart:async';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_typography.dart';

class SkillokaLoading extends StatefulWidget {
  final String? initialMessage;
  final List<String>? customTips;
  final double size;
  final bool fullPage;

  const SkillokaLoading({
    super.key,
    this.initialMessage,
    this.customTips,
    this.size = 72,
    this.fullPage = false,
  });

  /// Full page loader with scaffold and centered engaging animation
  const SkillokaLoading.page({
    super.key,
    String? message,
    List<String>? tips,
  })  : initialMessage = message,
        customTips = tips,
        size = 80.0,
        fullPage = true;

  /// Compact inline loader for search or tab sections
  const SkillokaLoading.inline({
    super.key,
    String? message,
    this.size = 56.0,
  })  : initialMessage = message,
        customTips = null,
        fullPage = false;

  @override
  State<SkillokaLoading> createState() => _SkillokaLoadingState();
}

class _SkillokaLoadingState extends State<SkillokaLoading>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  late Timer _tipsTimer;
  int _currentTipIndex = 0;

  final List<String> _defaultTips = [
    'Menghubungkan ke sistem LPK resmi...',
    'Menyiapkan kurikulum & silabus pelatihan...',
    'Memuat peluang keahlian masa depan...',
    'Hampir siap, sedikit lagi...',
  ];

  final List<IconData> _icons = [
    Icons.school_rounded,
    Icons.workspace_premium_rounded,
    Icons.auto_awesome_rounded,
    Icons.trending_up_rounded,
  ];

  @override
  void initState() {
    super.initState();

    // Pulse animation (breathing)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Subtle continuous rotation for orbit particles
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    // Rotate tips every 2.2 seconds
    _tipsTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (!mounted) return;
      setState(() {
        final tips = widget.customTips ?? _defaultTips;
        _currentTipIndex = (_currentTipIndex + 1) % tips.length;
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _tipsTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tips = widget.customTips ?? _defaultTips;
    final message = widget.initialMessage ?? tips[_currentTipIndex];
    final currentIcon = _icons[_currentTipIndex % _icons.length];

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Animated Logo Mascot
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Outer Glow Wave
                    Container(
                      width: widget.size * 1.55,
                      height: widget.size * 1.55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary
                            .withValues(alpha: _glowAnimation.value * 0.25),
                      ),
                    ),
                    // Middle Soft Aura
                    Container(
                      width: widget.size * 1.25,
                      height: widget.size * 1.25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary
                                .withValues(alpha: _glowAnimation.value * 0.45),
                            AppColors.secondary
                                .withValues(alpha: _glowAnimation.value * 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Center Breathing Orb
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary,
                              Color(0xFF4F46E5), // Indigo blend
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (child, anim) {
                              return ScaleTransition(
                                scale: anim,
                                child: FadeTransition(
                                  opacity: anim,
                                  child: child,
                                ),
                              );
                            },
                            child: Icon(
                              currentIcon,
                              key: ValueKey<int>(_currentTipIndex),
                              size: widget.size * 0.46,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Orbiting Mini Sparkle Satellite
                    RotationTransition(
                      turns: _rotateController,
                      child: Container(
                        width: widget.size * 1.35,
                        height: widget.size * 1.35,
                        alignment: Alignment.topRight,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 9,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Animated Cycling Text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                message,
                key: ValueKey<String>(message),
                textAlign: TextAlign.center,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryFor(context),
                  letterSpacing: -0.2,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Subtle animated dot indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(tips.length, (idx) {
                final isCurrent = idx == (_currentTipIndex % tips.length);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isCurrent ? 18 : 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.outlineDark
                            : AppColors.outlineVariant),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );

    if (widget.fullPage) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(child: content),
      );
    }

    return content;
  }
}

