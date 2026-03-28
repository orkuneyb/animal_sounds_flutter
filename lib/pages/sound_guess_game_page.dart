import 'package:animal_sounds_flutter/providers/game_provider.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SoundGuessGamePage extends StatefulWidget {
  const SoundGuessGamePage({Key? key}) : super(key: key);

  @override
  State<SoundGuessGamePage> createState() => _SoundGuessGamePageState();
}

class _SoundGuessGamePageState extends State<SoundGuessGamePage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;
  late AnimationController _gameOverController;
  late Animation<Offset> _gameOverSlide;
  late Animation<double> _gameOverFade;

  int _displayScore = 0;
  bool _isProcessing = false;
  int? _selectedIndex;
  bool? _answerResult;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scoreAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.elasticOut),
    );

    _gameOverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _gameOverSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _gameOverController,
      curve: Curves.easeOutCubic,
    ));
    _gameOverFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gameOverController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GameProvider>();
      provider.startGame();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) provider.playSound();
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scoreController.dispose();
    _gameOverController.dispose();
    super.dispose();
  }

  void _onAnswerTap(int index) {
    if (_isProcessing) return;

    final provider = context.read<GameProvider>();
    if (provider.isGameOver) return;

    setState(() {
      _isProcessing = true;
      _selectedIndex = index;
    });

    final isCorrect = provider.checkAnswer(index);

    setState(() {
      _answerResult = isCorrect;
    });

    if (isCorrect) {
      _scoreController.forward().then((_) => _scoreController.reverse());
      setState(() {
        _displayScore = provider.currentScore;
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _selectedIndex = null;
          _answerResult = null;
        });
        provider.pickNextRound();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) provider.playSound();
        });
      });
    } else {
      _gameOverController.forward();
      setState(() {
        _displayScore = provider.currentScore;
      });
    }
  }

  void _restartGame() {
    final provider = context.read<GameProvider>();
    _gameOverController.reset();
    setState(() {
      _isProcessing = false;
      _selectedIndex = null;
      _answerResult = null;
      _displayScore = 0;
    });
    provider.startGame();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) provider.playSound();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE3F2FD),
                  Color(0xFFFFF8E1),
                  Color(0xFFE8F5E9),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildTopBar(provider),
                      const SizedBox(height: 12),
                      _buildSoundButton(provider),
                      const SizedBox(height: 20),
                      Expanded(child: _buildOptionsGrid(provider)),
                      const SizedBox(height: 16),
                    ],
                  ),
                  if (provider.isGameOver) _buildGameOverOverlay(provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(GameProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.onSurface,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          // Current score
          ScaleTransition(
            scale: _scoreAnimation,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$_displayScore',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // High score badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF176), Color(0xFFFFD54F)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Color(0xFFF57F17), size: 18),
                const SizedBox(width: 4),
                Text(
                  '${provider.highScore}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF57F17),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundButton(GameProvider provider) {
    return Column(
      children: [
        Text(
          'sound_guess_tap_to_listen'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => provider.playSound(),
          child: ScaleTransition(
            scale: provider.isPlaying ? _pulseAnimation : kAlwaysCompleteAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: provider.isPlaying
                      ? [const Color(0xFF42A5F5), const Color(0xFF1565C0)]
                      : [const Color(0xFF81D4FA), const Color(0xFF039BE5)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tertiary.withOpacity(0.35),
                    spreadRadius: provider.isPlaying ? 6 : 2,
                    blurRadius: provider.isPlaying ? 24 : 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                provider.isPlaying
                    ? Icons.graphic_eq_rounded
                    : Icons.volume_up_rounded,
                size: 54,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsGrid(GameProvider provider) {
    if (provider.currentOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemCount: provider.currentOptions.length,
        itemBuilder: (context, index) {
          return _buildOptionCard(provider, index);
        },
      ),
    );
  }

  Widget _buildOptionCard(GameProvider provider, int index) {
    final animal = provider.currentOptions[index];
    final isSelected = _selectedIndex == index;
    final isCorrectAnimal =
        provider.correctAnimal?.index == animal.index;

    Color borderColor = Colors.white;
    Color bgColor = Colors.white;

    if (_answerResult != null && isSelected) {
      if (_answerResult!) {
        borderColor = AppColors.success;
        bgColor = const Color(0xFFE8F5E9);
      } else {
        borderColor = AppColors.error;
        bgColor = const Color(0xFFFFEBEE);
      }
    }

    if (_answerResult == false && isCorrectAnimal) {
      borderColor = AppColors.success;
      bgColor = const Color(0xFFE8F5E9);
    }

    return GestureDetector(
      onTap: () => _onAnswerTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: (isSelected || (_answerResult == false && isCorrectAnimal))
                ? 3
                : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animal image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    animal.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Animal name
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 12, left: 8, right: 8),
              child: Text(
                animal.name.tr(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: (_answerResult == false && isCorrectAnimal)
                      ? const Color(0xFF2E7D32)
                      : (_answerResult == false && isSelected)
                          ? const Color(0xFFC62828)
                          : AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Correct/wrong indicator
            if (_answerResult != null &&
                (isSelected || (_answerResult == false && isCorrectAnimal)))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Icon(
                  (_answerResult! && isSelected) ||
                          (_answerResult == false && isCorrectAnimal)
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: (_answerResult! && isSelected) ||
                          (_answerResult == false && isCorrectAnimal)
                      ? AppColors.success
                      : AppColors.error,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(GameProvider provider) {
    return FadeTransition(
      opacity: _gameOverFade,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: SlideTransition(
            position: _gameOverSlide,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Game over title
                  Text(
                    'sound_guess_game_over'.tr(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Score
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF8E1), Color(0xFFFFE082)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'sound_guess_your_score'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.currentScore}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF57F17),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < provider.starRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFFFC107),
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  // New high score badge
                  if (provider.isNewHighScore)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6F00), Color(0xFFFFC107)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.celebration_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'sound_guess_new_high_score'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Play Again button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                        ),
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _restartGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.replay_rounded,
                                color: Colors.white, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'play_again'.tr(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Go Home button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.outlineVariant,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'sound_guess_go_home'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
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
    );
  }
}
