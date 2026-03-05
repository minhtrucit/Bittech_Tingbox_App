import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../app_colors.dart';

class AILoadingOverlay extends StatefulWidget {
  final String message;
  const AILoadingOverlay({super.key, required this.message});

  @override
  State<AILoadingOverlay> createState() => _AILoadingOverlayState();
}

class _AILoadingOverlayState extends State<AILoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scannerController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Glassmorphic Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.7)),
          ),

          // AI Gradient Glow
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 300.w,
                  height: 300.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryBlue.withValues(
                          alpha: 0.3 * _pulseController.value,
                        ),
                        AppColors.primaryBlue.withValues(
                          alpha: 0.1 * _pulseController.value,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Scanning Box
                Container(
                  width: 140.w,
                  height: 140.w,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.document_scanner_rounded,
                          size: 60.sp,
                          color: Colors.white,
                        ),
                      ),
                      // Scanning Line
                      AnimatedBuilder(
                        animation: _scannerController,
                        builder: (context, child) {
                          return Positioned(
                            top: _scannerController.value * 100,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue,
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.primaryBlue,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40.h),

                // Animated Text
                Text(
                  widget.message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  "Đang bóc tách dữ liệu bằng AI...",
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),

                SizedBox(height: 40.h),
                // Small indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        double opacity =
                            (index == 0)
                                ? _pulseController.value
                                : (index == 1)
                                ? (0.5 + _pulseController.value / 2).clamp(0, 1)
                                : 1 - _pulseController.value;
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryBlue.withValues(
                              alpha: opacity,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
