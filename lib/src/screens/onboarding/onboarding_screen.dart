import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingPageModel> _pages = const [
    _OnboardingPageModel(
      title: 'Pilote ton business\npartout, tout le temps',
      subtitle:
          'Surveille tes ventes, tes stocks et tes paiements en temps réel, même en déplacement.',
      imageUrl:
          'https://images.unsplash.com/photo-1521791055366-0d553872125f?w=800',
    ),
    _OnboardingPageModel(
      title: 'Vends plus\navec des insights clairs',
      subtitle:
          'Des tableaux de bord simples et actionnables pour prendre des décisions plus vite.',
      imageUrl:
          'https://images.unsplash.com/photo-1556741533-f6acd647d2fb?w=800',
    ),
    _OnboardingPageModel(
      title: 'Collabore en confiance',
      subtitle:
          'Invitations d’équipe, rôles et permissions pour travailler sereinement.',
      imageUrl:
          'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=800',
    ),
  ];

  Future<void> _setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  Future<void> _navigate(BuildContext context, Widget screen) async {
    await _setOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _skip() async {
    await _navigate(context, const LoginScreen());
  }

  void _next() async {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _navigate(context, const SignupScreen());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final safe = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Jangolo',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _skip,
                    child: const Text('Passer'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Carrousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _OnboardingSlide(page: page);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Indicateurs
              _DotsIndicator(
                count: _pages.length,
                index: _currentIndex,
                activeColor: primary,
                inactiveColor: Colors.grey.shade400,
              ),

              const SizedBox(height: 24),

              // CTA
              _PrimaryCtas(
                primary: primary,
                isLastPage: _currentIndex == _pages.length - 1,
                onCreateAccount: () => _navigate(context, const SignupScreen()),
                onLogin: () => _navigate(context, const LoginScreen()),
                onNext: _next,
              ),

              const SizedBox(height: 8),

              // Légal
              _LegalArea(
                textColor: Colors.black87,
                linkColor: primary,
              ),

              SizedBox(height: safe.bottom > 0 ? safe.bottom / 2 : 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.page});
  final _OnboardingPageModel page;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              page.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.image_not_supported,
                size: 120,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: t.textTheme.headlineSmall?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          page.subtitle,
          textAlign: TextAlign.center,
          style: t.textTheme.bodyMedium?.copyWith(
            color: Colors.black54,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.index,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int count;
  final int index;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: i == index ? 22 : 8,
          decoration: BoxDecoration(
            color: i == index ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _PrimaryCtas extends StatelessWidget {
  const _PrimaryCtas({
    required this.primary,
    required this.isLastPage,
    required this.onCreateAccount,
    required this.onLogin,
    required this.onNext,
  });

  final Color primary;
  final bool isLastPage;
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (!isLastPage) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          child: const Text('Continuer'),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onCreateAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: const Text('Créer un compte'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onLogin,
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: const Text('Se connecter'),
          ),
        ),
      ],
    );
  }
}

class _LegalArea extends StatelessWidget {
  const _LegalArea({
    required this.textColor,
    required this.linkColor,
  });

  final Color textColor;
  final Color linkColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'En créant un compte, vous acceptez nos',
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 12),
        ),
        TextButton(
          onPressed: () {
            // TODO: ouvrir bottom sheet Conditions
          },
          child: Text(
            'Conditions d’utilisation et Politique de confidentialité',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: linkColor,
              fontSize: 12,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPageModel {
  final String title;
  final String subtitle;
  final String imageUrl;

  const _OnboardingPageModel({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}
