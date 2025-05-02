class OnboardingContent {
  final String title;
  final String description;
  final String animPath;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.animPath,
  });
}

final List<OnboardingContent> onboardingContents = [
  OnboardingContent(
    title: "Welcome to Good Merchant",
    description: "Discover a world of amazing products tailored just for you.",
    animPath: "Assets/images/2j.json",
  ),
  OnboardingContent(
    title: "Easy Shopping Experience",
    description: "Browse, select, and purchase with just a few taps.",
    animPath: "Assets/images/onboarding_animation_2.json",
  ),
  OnboardingContent(
    title: "Fast Delivery",
    description: "Get your orders delivered to your doorstep quickly and safely.",
    animPath: "Assets/images/onboarding_animation_3.json",
  ),
]; 