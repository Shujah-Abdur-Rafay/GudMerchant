import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoader extends StatelessWidget {
  final String assetPath;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget fallbackWidget;

  const LottieLoader({
    Key? key,
    required this.assetPath,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    required this.fallbackWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      assetPath,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading Lottie animation: $error');
        return fallbackWidget;
      },
    );
  }
} 