import 'package:animal_sounds_flutter/pages/coloring_page.dart';
import 'package:animal_sounds_flutter/pages/compare_page.dart';
import 'package:animal_sounds_flutter/providers/achievement_provider.dart';
import 'package:animal_sounds_flutter/providers/discovery_provider.dart';
import 'package:animal_sounds_flutter/providers/usage_stats_provider.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../models/animal.dart';
import '../providers/favorites_provider.dart';

class AnimalInfoPage extends StatefulWidget {
  final Animal animal;

  const AnimalInfoPage({Key? key, required this.animal}) : super(key: key);

  @override
  State<AnimalInfoPage> createState() => _AnimalInfoPageState();
}

class _AnimalInfoPageState extends State<AnimalInfoPage> {
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;
  String? currentlyPlayingText;
  ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  bool _isInitialized = false;
  bool _hasTrackedVisit = false;
  final AdService _adService = AdService();
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  // Pastel colors for characteristic cards
  static const List<Color> _pastelColors = [
    Color(0xFFE8F5E9), // soft green
    Color(0xFFE3F2FD), // soft blue
    Color(0xFFFFF3E0), // soft orange
    Color(0xFFF3E5F5), // soft purple
    Color(0xFFE0F7FA), // soft cyan
  ];

  @override
  void initState() {
    super.initState();
    _bannerAd = _adService.createBannerAd()
      ..load().then((_) {
        setState(() {
          _isBannerAdReady = true;
        });
      });
    _initBasicTts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initLanguage();
      _isInitialized = true;
    }

    // Track info visit once for discovery and stats (deferred to avoid setState during build)
    if (!_hasTrackedVisit) {
      _hasTrackedVisit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _trackInfoVisit();
      });
    }
  }

  /// Tracks the info page visit across discovery, usage stats, and achievements.
  void _trackInfoVisit() {
    final discoveryProvider =
        Provider.of<DiscoveryProvider>(context, listen: false);
    final usageStatsProvider =
        Provider.of<UsageStatsProvider>(context, listen: false);
    final achievementProvider =
        Provider.of<AchievementProvider>(context, listen: false);

    discoveryProvider.markInfoVisited(widget.animal.index);
    usageStatsProvider.incrementInfoVisited(widget.animal.index);
    achievementProvider.incrementProgress('first_info', 1);
    achievementProvider.incrementProgress('curious_mind', 1);
    achievementProvider.incrementProgress('animal_expert', 1);
    achievementProvider.incrementProgress('fact_lover', 1);
  }

  Future<void> _initBasicTts() async {
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    flutterTts.setCompletionHandler(() {
      isSpeakingNotifier.value = false;
      currentlyPlayingText = null;
    });
  }

  Future<void> _initLanguage() async {
    await flutterTts.setLanguage(context.locale.languageCode);
  }

  Future<void> _speak(String text) async {
    if (isSpeakingNotifier.value && currentlyPlayingText == text) {
      await flutterTts.stop();
      isSpeakingNotifier.value = false;
      currentlyPlayingText = null;
    } else {
      if (isSpeakingNotifier.value) {
        await flutterTts.stop();
      }
      currentlyPlayingText = text;
      isSpeakingNotifier.value = true;
      await flutterTts.speak(text);
    }
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    flutterTts.stop();
    isSpeakingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(context),
                if (_isBannerAdReady)
                  Center(
                    child: SizedBox(
                      width: _bannerAd.size.width.toDouble(),
                      height: _bannerAd.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd),
                    ),
                  ),
                _buildCharacteristics(),
                _buildHabitat(),
                _buildDietSection(),
                _buildFunFacts(),
                // Action buttons for Compare and Coloring
                _buildActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.animal.name.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'animal_image_${widget.animal.index}',
              child: Image.asset(
                widget.animal.imagePath,
                fit: BoxFit.cover,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Compare button
        IconButton(
          icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
          tooltip: 'compare'.tr(),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComparePage()),
            );
          },
        ),
        // Favorite button
        Consumer<FavoritesProvider>(
          builder: (context, favoritesProvider, child) {
            return IconButton(
              icon: Icon(
                favoritesProvider.isFavorite(widget.animal.index)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: favoritesProvider.isFavorite(widget.animal.index)
                    ? Colors.redAccent
                    : Colors.white,
              ),
              onPressed: () =>
                  favoritesProvider.toggleFavorite(widget.animal.index),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSmallTtsIcon(String text) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSpeakingNotifier,
      builder: (context, isSpeaking, child) {
        bool isThisPlaying = currentlyPlayingText == text && isSpeaking;
        return GestureDetector(
          onTap: () => _speak(text),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isThisPlaying
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isThisPlaying
                  ? Icons.stop_rounded
                  : Icons.volume_up_rounded,
              color: isThisPlaying
                  ? AppColors.primaryDark
                  : AppColors.onSurfaceVariant,
              size: 15,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextWithSpeech(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.onSurface,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _buildSmallTtsIcon(text),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> content,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              _buildSmallTtsIcon(title),
            ],
          ),
          const SizedBox(height: 14),
          ...content,
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return _buildSection(
      title: 'description'.tr(),
      content: [
        _buildTextWithSpeech(widget.animal.description.tr()),
      ],
    );
  }

  Widget _buildCharacteristics() {
    final items = [
      _CharacteristicData(
        icon: Icons.height_rounded,
        label: 'size'.tr(),
        value: '${widget.animal.name}_size'.tr(),
        color: _pastelColors[0],
      ),
      _CharacteristicData(
        icon: Icons.scale_rounded,
        label: 'weight'.tr(),
        value: '${widget.animal.name}_weight'.tr(),
        color: _pastelColors[1],
      ),
      _CharacteristicData(
        icon: Icons.timer_rounded,
        label: 'lifespan'.tr(),
        value: '${widget.animal.name}_lifespan'.tr(),
        color: _pastelColors[2],
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'characteristics'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                _buildSmallTtsIcon('characteristics'.tr()),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final fullText = '${item.label}: ${item.value}';
                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon,
                                color: AppColors.primaryDark, size: 20),
                          ),
                          _buildSmallTtsIcon(fullText),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Expanded(
                        child: Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitat() {
    return _buildSection(
      title: 'habitat'.tr(),
      content: [
        _buildTextWithSpeech('${widget.animal.name}_habitat'.tr()),
      ],
    );
  }

  Widget _buildDietSection() {
    return _buildSection(
      title: 'diet'.tr(),
      content: [
        _buildTextWithSpeech('${widget.animal.name}_diet'.tr()),
      ],
    );
  }

  Widget _buildFunFacts() {
    final facts = [
      '${widget.animal.name}_fun_fact_1'.tr(),
      '${widget.animal.name}_fun_fact_2'.tr(),
      '${widget.animal.name}_fun_fact_3'.tr(),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'fun_facts'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              _buildSmallTtsIcon('fun_facts'.tr()),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(facts.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryLight,
                          AppColors.primary,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextWithSpeech(facts[index]),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Action buttons for Compare and Coloring features.
  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Compare button
          Expanded(
            child: _ActionButton(
              icon: Icons.compare_arrows_rounded,
              label: 'compare'.tr(),
              color: AppColors.secondary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ComparePage()),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Coloring button
          Expanded(
            child: _ActionButton(
              icon: Icons.palette_rounded,
              label: 'coloring'.tr(),
              color: AppColors.tertiary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ColoringPage(animal: widget.animal),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A styled action button for the info page.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacteristicData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CharacteristicData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
