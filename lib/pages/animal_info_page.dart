import 'package:animal_sounds_flutter/services/ad_service.dart';
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
  final AdService _adService = AdService();
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

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
      backgroundColor: Colors.amber[50],
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
      backgroundColor: Colors.orangeAccent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.animal.name.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
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
        Consumer<FavoritesProvider>(
          builder: (context, favoritesProvider, child) {
            return IconButton(
              icon: Icon(
                favoritesProvider.isFavorite(widget.animal.index)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: favoritesProvider.isFavorite(widget.animal.index)
                    ? Colors.red
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

  Widget _buildTextWithSpeech(String text) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSpeakingNotifier,
      builder: (context, isSpeaking, child) {
        bool isThisTextPlaying = currentlyPlayingText == text && isSpeaking;
        return Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isThisTextPlaying ? Icons.stop_circle : Icons.play_circle,
                color: Colors.orangeAccent,
                size: 30,
              ),
              onPressed: () => _speak(text),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> content,
  }) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
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
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _speak(title),
                    icon: const Icon(
                      Icons.volume_up,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...content,
        ],
      ),
    );
  }

  Widget _buildCharacteristicItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    String fullText = '$label: $value';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.orangeAccent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<bool>(
                  valueListenable: isSpeakingNotifier,
                  builder: (context, isSpeaking, child) {
                    bool isThisTextPlaying =
                        currentlyPlayingText == fullText && isSpeaking;
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isThisTextPlaying
                                ? Icons.stop_circle
                                : Icons.play_circle,
                            color: Colors.orangeAccent,
                            size: 30,
                          ),
                          onPressed: () => _speak(fullText),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
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
    return _buildSection(
      title: 'characteristics'.tr(),
      content: [
        _buildCharacteristicItem(
          icon: Icons.height,
          label: 'size'.tr(),
          value: '${widget.animal.name}_size'.tr(),
        ),
        const SizedBox(height: 8),
        _buildCharacteristicItem(
          icon: Icons.scale,
          label: 'weight'.tr(),
          value: '${widget.animal.name}_weight'.tr(),
        ),
        const SizedBox(height: 8),
        _buildCharacteristicItem(
          icon: Icons.timer,
          label: 'lifespan'.tr(),
          value: '${widget.animal.name}_lifespan'.tr(),
        ),
      ],
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
    return _buildSection(
      title: 'fun_facts'.tr(),
      content: [
        _buildFunFactItem('${widget.animal.name}_fun_fact_1'.tr()),
        const SizedBox(height: 12),
        _buildFunFactItem('${widget.animal.name}_fun_fact_2'.tr()),
        const SizedBox(height: 12),
        _buildFunFactItem('${widget.animal.name}_fun_fact_3'.tr()),
      ],
    );
  }

  Widget _buildFunFactItem(String fact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.star,
          color: Colors.orangeAccent,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTextWithSpeech(fact),
        ),
      ],
    );
  }
}
