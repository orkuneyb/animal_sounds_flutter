import 'dart:async';
import 'dart:io';

import 'package:animal_sounds_flutter/services/audio_recorder_service.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/widgets/sound_wave_animation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The possible states of the voice recorder widget.
enum RecorderState { idle, recording, recorded }

/// A child-friendly "You Try!" voice recorder widget.
///
/// Allows children to record their imitation of an animal sound, then play
/// it back side-by-side with the original for comparison.
class VoiceRecorderWidget extends StatefulWidget {
  /// The asset path of the original animal sound for comparison playback.
  final String animalSoundPath;

  /// The name of the animal, used for display labels.
  final String animalName;

  const VoiceRecorderWidget({
    super.key,
    required this.animalSoundPath,
    required this.animalName,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  final AudioRecorderService _recorder = AudioRecorderService();
  final AudioPlayer _animalPlayer = AudioPlayer();
  final AudioPlayer _recordedPlayer = AudioPlayer();

  RecorderState _state = RecorderState.idle;
  String? _recordedFilePath;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  bool _isPlayingAnimal = false;
  bool _isPlayingRecorded = false;

  // Animation for the pulsing record indicator
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const int _maxRecordingSeconds = 10;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animalPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingAnimal = false);
    });
    _recordedPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingRecorded = false);
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    _animalPlayer.dispose();
    _recordedPlayer.dispose();
    _deleteRecording();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Recording logic
  // ---------------------------------------------------------------------------

  Future<void> _startRecording() async {
    try {
      var hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        hasPermission = await _recorder.requestPermission();
      }
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('mic_permission_denied'.tr()),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      final filePath = await _recorder.startRecording();
      if (filePath == null) {
        debugPrint('Failed to start recording');
        return;
      }

      setState(() {
        _state = RecorderState.recording;
        _recordingSeconds = 0;
        _recordedFilePath = filePath;
      });

      _pulseController.repeat(reverse: true);

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
        if (_recordingSeconds >= _maxRecordingSeconds) {
          _stopRecording();
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordingTimer?.cancel();
      _pulseController.stop();
      _pulseController.reset();

      final path = await _recorder.stopRecording();

      if (mounted) {
        setState(() {
          _state = RecorderState.recorded;
          if (path != null) {
            _recordedFilePath = path;
          }
        });
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _playAnimalSound() async {
    try {
      if (_isPlayingAnimal) {
        await _animalPlayer.stop();
        setState(() => _isPlayingAnimal = false);
        return;
      }
      await _recordedPlayer.stop();
      setState(() {
        _isPlayingRecorded = false;
        _isPlayingAnimal = true;
      });

      String cleanPath = widget.animalSoundPath;
      if (cleanPath.startsWith('assets/')) {
        cleanPath = cleanPath.substring(7);
      }
      await _animalPlayer.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint('Error playing animal sound: $e');
      if (mounted) setState(() => _isPlayingAnimal = false);
    }
  }

  Future<void> _playRecordedSound() async {
    try {
      if (_isPlayingRecorded) {
        await _recordedPlayer.stop();
        setState(() => _isPlayingRecorded = false);
        return;
      }
      if (_recordedFilePath == null) return;

      await _animalPlayer.stop();
      setState(() {
        _isPlayingAnimal = false;
        _isPlayingRecorded = true;
      });

      await _recordedPlayer.play(DeviceFileSource(_recordedFilePath!));
    } catch (e) {
      debugPrint('Error playing recorded sound: $e');
      if (mounted) setState(() => _isPlayingRecorded = false);
    }
  }

  void _recordAgain() {
    _deleteRecording();
    setState(() {
      _state = RecorderState.idle;
      _recordedFilePath = null;
      _recordingSeconds = 0;
    });
  }

  void _deleteRecording() {
    _recorder.deleteFile(_recordedFilePath);
    _recordedFilePath = null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryContainer,
            AppColors.tertiaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic_rounded, color: AppColors.primaryDark,
                  size: 22),
              const SizedBox(width: 8),
              Text(
                'you_try'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case RecorderState.idle:
        return _buildIdleState();
      case RecorderState.recording:
        return _buildRecordingState();
      case RecorderState.recorded:
        return _buildRecordedState();
    }
  }

  // ---------------------------------------------------------------------------
  // IDLE state
  // ---------------------------------------------------------------------------

  Widget _buildIdleState() {
    return Column(
      children: [
        Text(
          'you_try_description'.tr(),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.onPrimaryContainer,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _BigActionButton(
          icon: Icons.mic_rounded,
          label: 'start_recording'.tr(),
          color: AppColors.primary,
          onTap: _startRecording,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RECORDING state
  // ---------------------------------------------------------------------------

  Widget _buildRecordingState() {
    return Column(
      children: [
        // Pulsing red indicator
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'recording'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 12),
        // Sound wave animation
        SoundWaveAnimation(
          barCount: 7,
          color: AppColors.primaryDark,
          maxHeight: 36,
          isAnimating: true,
        ),
        const SizedBox(height: 12),
        // Timer
        Text(
          '${_recordingSeconds}s / ${_maxRecordingSeconds}s',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.onPrimaryContainer,
          ),
        ),
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _recordingSeconds / _maxRecordingSeconds,
              backgroundColor: Colors.white.withOpacity(0.4),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.red),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _BigActionButton(
          icon: Icons.stop_rounded,
          label: 'stop_recording'.tr(),
          color: Colors.red,
          onTap: _stopRecording,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RECORDED state
  // ---------------------------------------------------------------------------

  Widget _buildRecordedState() {
    return Column(
      children: [
        Text(
          'compare_sounds'.tr(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 14),
        // Two playback buttons side by side
        Row(
          children: [
            Expanded(
              child: _PlaybackButton(
                icon: Icons.volume_up_rounded,
                label: 'animal_sound'.tr(),
                isPlaying: _isPlayingAnimal,
                color: AppColors.secondary,
                onTap: _playAnimalSound,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PlaybackButton(
                icon: Icons.mic_rounded,
                label: 'your_voice'.tr(),
                isPlaying: _isPlayingRecorded,
                color: AppColors.primary,
                onTap: _playRecordedSound,
              ),
            ),
          ],
        ),
        // Sound wave (active when either is playing)
        if (_isPlayingAnimal || _isPlayingRecorded) ...[
          const SizedBox(height: 12),
          SoundWaveAnimation(
            barCount: 5,
            color: _isPlayingAnimal
                ? AppColors.secondary
                : AppColors.primary,
            maxHeight: 28,
            isAnimating: true,
          ),
        ],
        const SizedBox(height: 16),
        // Bottom actions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _recordAgain,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text('record_again'.tr()),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () {
                _deleteRecording();
                setState(() {
                  _state = RecorderState.idle;
                  _recordedFilePath = null;
                });
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: Text('delete'.tr()),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Big action button (record / stop)
// =============================================================================

class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigActionButton({
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Playback button for the comparison view
// =============================================================================

class _PlaybackButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPlaying;
  final Color color;
  final VoidCallback onTap;

  const _PlaybackButton({
    required this.icon,
    required this.label,
    required this.isPlaying,
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: isPlaying ? color : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                isPlaying ? Icons.stop_rounded : icon,
                color: isPlaying ? Colors.white : color,
                size: 30,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPlaying ? Colors.white : color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
