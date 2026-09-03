import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/app/theme/app_theme.dart';
import 'package:mentorride/features/onboarding/providers/onboarding_providers.dart';
import 'package:mentorride/shared/widgets/app_logo.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pages = [
    _OnboardingPageData(
      icon: Icons.build_circle_outlined,
      title: 'Catat perawatan kendaraan',
      description:
          'Simpan riwayat servis dan biaya perawatan kendaraan dalam satu '
          'tempat yang mudah dilihat kembali.',
    ),
    _OnboardingPageData(
      icon: Icons.notifications_active_outlined,
      title: 'Jangan lewatkan jadwal servis',
      description:
          'Atur pengingat servis berdasarkan tanggal dan pantau jatuh tempo '
          'berdasarkan kilometer kendaraan.',
    ),
    _OnboardingPageData(
      icon: Icons.space_dashboard_outlined,
      title: 'Pantau kendaraan dengan mudah',
      description:
          'Lihat ringkasan kilometer, servis terakhir, jadwal, dan biaya '
          'perawatan langsung dari beranda.',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final animationDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  const AppLogo(size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'MentorRide',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: animationDuration,
                    child: isLastPage
                        ? const SizedBox(key: ValueKey('skip-placeholder'))
                        : TextButton(
                            key: const Key('onboarding_skip_button'),
                            onPressed: _isCompleting ? null : _finish,
                            child: const Text('Lewati'),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                key: const Key('onboarding_page_view'),
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    _errorMessage = null;
                  });
                },
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    key: ValueKey('onboarding_page_$index'),
                    data: _pages[index],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        label:
                            'Halaman ${_currentPage + 1} dari ${_pages.length}',
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (
                                var index = 0;
                                index < _pages.length;
                                index++
                              )
                                AnimatedContainer(
                                  duration: animationDuration,
                                  curve: Curves.easeOutCubic,
                                  width: index == _currentPage ? 24 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index == _currentPage
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.outlineVariant,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (_errorMessage case final message?) ...[
                        const SizedBox(height: 12),
                        Text(
                          message,
                          key: const Key('onboarding_error_message'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: Key(
                          isLastPage
                              ? 'onboarding_start_button'
                              : 'onboarding_next_button',
                        ),
                        onPressed: _isCompleting
                            ? null
                            : isLastPage
                            ? _finish
                            : _nextPage,
                        icon: _isCompleting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isLastPage
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                              ),
                        label: AnimatedSwitcher(
                          duration: animationDuration,
                          child: Text(
                            _isCompleting
                                ? 'Menyimpan...'
                                : isLastPage
                                ? 'Mulai'
                                : 'Berikutnya',
                            key: ValueKey((_isCompleting, isLastPage)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    FocusManager.instance.primaryFocus?.unfocus();
    final nextPage = _currentPage + 1;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(nextPage);
      return;
    }
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
      _errorMessage = null;
    });
    final completed = await ref
        .read(onboardingStatusProvider.notifier)
        .completeOnboarding();
    if (!mounted) return;

    if (!completed && ref.read(onboardingStatusProvider).value != true) {
      setState(() {
        _isCompleting = false;
        _errorMessage = 'Onboarding belum dapat disimpan. Silakan coba lagi.';
      });
    }
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, super.key});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        data.icon,
                        size: 64,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
