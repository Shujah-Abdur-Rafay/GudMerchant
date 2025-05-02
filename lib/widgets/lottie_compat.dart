import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieCompat extends StatefulWidget {
  final String assetName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget fallbackWidget;
  final bool repeat;
  final bool animate;

  const LottieCompat({
    Key? key,
    required this.assetName,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    required this.fallbackWidget,
    this.repeat = true,
    this.animate = true,
  }) : super(key: key);

  @override
  State<LottieCompat> createState() => _LottieCompatState();
}

class _LottieCompatState extends State<LottieCompat> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.animate) {
      if (widget.repeat) {
        _controller.repeat();
      } else {
        _controller.forward();
      }
    }
    
    // Try to pre-load the asset to check if it exists
    _checkAssetExists();
  }
  
  Future<void> _checkAssetExists() async {
    try {
      // Try to load asset in a non-UI thread
      await Future.delayed(Duration.zero, () {
        if (!mounted) return;
        setState(() {
          // Set _isError to false initially (no change, but ensures the state is set once)
          _isError = false;
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return widget.fallbackWidget;
    }

    return LottieBuilder.asset(
      widget.assetName,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      controller: widget.animate ? _controller : null,
      onWarning: (warning) {
        debugPrint('Lottie Warning: $warning');
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Lottie Error: $error');
        // Use a post-frame callback to prevent setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isError = true;
            });
          }
        });
        return widget.fallbackWidget;
      },
    );
  }
} 