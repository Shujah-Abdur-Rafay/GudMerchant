import 'package:gudmerchant/screens/auth-ui/SignInScreen.dart';
import 'package:gudmerchant/utils/app_theme.dart';
import 'package:gudmerchant/widgets/lottie_compat.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// Controller for the welcome screen
class WelcomeController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  void nextPage() {
    if (currentPage.value < 2) {
      // 2 is the last index
      pageController.nextPage(
        duration: AppTheme.mediumAnimationDuration,
        curve: AppTheme.defaultCurve,
      );
    }
  }

  void onPageChanged(int page) {
    currentPage.value = page;
  }

  void goToSignIn() {
    Get.to(
      () => const Signinscreen(),
      transition: Transition.rightToLeft,
      duration: AppTheme.mediumAnimationDuration,
    );
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller
  late AnimationController _animationController;

  // Welcome controller
  final WelcomeController _controller = Get.put(WelcomeController());

  // Onboarding content
  final List<OnboardingContent> _onboardingContents = [
    OnboardingContent(
      title: "Welcome to GudMerchant",
      description:
          "Your one-stop destination for all your shopping needs. Find the best products at the best prices!",
      animation: "Assets/json/cart_animation.json",
      useAnimation: true,
    ),
    OnboardingContent(
      title: "Discover Quality Products",
      description:
          "Explore a wide range of high-quality products from trusted brands across multiple categories.",
      animation: "Assets/images/2j.json",
      useAnimation: true,
    ),
    OnboardingContent(
      title: "Fast & Secure Checkout",
      description:
          "Experience seamless payment process with multiple payment options and secure transactions.",
      animation: "Assets/images/cart.png",
      useAnimation: false,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.mediumAnimationDuration,
    );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Brand logo and name
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing_md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _controller.goToSignIn,
                    child: const Text("Skip"),
                  ),
                ],
              ),
            ),

            // Onboarding slider
            Expanded(
              child: PageView.builder(
                controller: _controller.pageController,
                itemCount: _onboardingContents.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingContents[index]);
                },
                onPageChanged: _controller.onPageChanged,
              ),
            ),

            // Page indicator
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppTheme.spacing_md),
              child: SmoothPageIndicator(
                controller: _controller.pageController,
                count: _onboardingContents.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: AppTheme.primaryColor,
                  dotColor: AppTheme.primaryColor.withOpacity(0.3),
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 4,
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing_xl),
              child: GetX<WelcomeController>(
                builder: (controller) {
                  return controller.currentPage.value ==
                          _onboardingContents.length - 1
                      ? _buildAuthButtons()
                      : _buildNavigationButton();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build onboarding page content
  Widget _buildOnboardingPage(OnboardingContent content) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing_lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation or Image
          Expanded(
            flex: 5,
            child: content.useAnimation
                ? LottieCompat(
                    assetName: content.animation,
                    height: 220,
                    fallbackWidget: Image.asset(
                      'Assets/images/cart.png',
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  )
                : Image.asset(
                    content.animation,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
          ),

          const SizedBox(height: AppTheme.spacing_xl),

          // Title
          Text(
            content.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacing_md),

          // Description
          Text(
            content.description,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacing_xl),

          Expanded(flex: 1, child: Container()),
        ],
      ),
    );
  }

  // Build navigation button (Next)
  Widget _buildNavigationButton() {
    return SizedBox(
      width: double.infinity,
      height: AppTheme.buttonHeight,
      child: ElevatedButton(
        onPressed: _controller.nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Next',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Build authentication buttons
  Widget _buildAuthButtons() {
    return Column(
      children: [
        // Email Sign-In Button
        SizedBox(
          width: double.infinity,
          height: AppTheme.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: _controller.goToSignIn,
            icon: const Icon(Icons.email_outlined, size: 24),
            label: const Text(
              "Sign in with Email",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacing_lg),

        // Terms and Conditions
        Text(
          "By continuing, you agree to our Terms of Service and Privacy Policy",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

// Onboarding content model
class OnboardingContent {
  final String title;
  final String description;
  final String animation;
  final bool useAnimation;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.animation,
    this.useAnimation = false,
  });
}
