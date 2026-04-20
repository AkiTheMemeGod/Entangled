import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final int? initialDurationMs;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.isMe,
    this.initialDurationMs,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isDragging = false;
  bool _isCaching = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackRate = 1.0;
  bool _isInit = false;
  String? _cachedFilePath;

  static const Duration _replayTolerance = Duration(milliseconds: 220);

  @override
  void initState() {
    super.initState();

    _prefetchAudio();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _position = _duration;
            _isPlaying = false;
          }
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.audioUrl != widget.audioUrl) {
      _isInit = false;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _cachedFilePath = null;
      _prefetchAudio();
    }
  }

  Future<void> _prefetchAudio() async {
    if (_isCaching) return;

    _isCaching = true;
    try {
      final file = await DefaultCacheManager().getSingleFile(widget.audioUrl);
      if (!mounted) return;
      setState(() {
        _cachedFilePath = file.path;
      });
    } catch (_) {
      // Keep URL streaming fallback if local cache fetch fails.
    } finally {
      _isCaching = false;
    }
  }

  Future<void> _setSourceIfNeeded() async {
    if (_isInit) return;

    if (_cachedFilePath != null) {
      await _audioPlayer.setSourceDeviceFile(_cachedFilePath!);
    } else {
      await _audioPlayer.setSourceUrl(widget.audioUrl);
    }
    _isInit = true;
  }

  Source _currentSource() {
    if (_cachedFilePath != null) {
      return DeviceFileSource(_cachedFilePath!);
    }
    return UrlSource(widget.audioUrl);
  }

  Future<void> _initPlayerIfNeeded() async {
    await _setSourceIfNeeded();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _initPlayerIfNeeded();
      final total = _effectiveDuration;
      final atEnd =
          total > Duration.zero &&
          (_position.inMilliseconds >=
              total.inMilliseconds - _replayTolerance.inMilliseconds);

      if (atEnd) {
        await _audioPlayer.play(_currentSource(), position: Duration.zero);
        _isInit = true;
        if (mounted) {
          setState(() {
            _position = Duration.zero;
          });
        }
      } else {
        await _audioPlayer.resume();
      }

      await _audioPlayer.setPlaybackRate(_playbackRate);
    }
  }

  Future<void> _seekToFraction(double fraction) async {
    await _initPlayerIfNeeded();
    final total = _effectiveDuration;
    if (total <= Duration.zero) return;

    final safeFraction = fraction.clamp(0.0, 1.0);
    final targetMs = (total.inMilliseconds * safeFraction).round();
    await _audioPlayer.seek(Duration(milliseconds: targetMs));
  }

  Future<void> _togglePlaybackRate() async {
    const rates = [1.0, 1.25, 1.5, 2.0];
    final currentIndex = rates.indexOf(_playbackRate);
    final nextRate = rates[(currentIndex + 1) % rates.length];

    await _audioPlayer.setPlaybackRate(nextRate);
    if (mounted) {
      setState(() {
        _playbackRate = nextRate;
      });
    }
  }

  Duration get _effectiveDuration {
    final fallback = Duration(milliseconds: widget.initialDurationMs ?? 0);
    return _duration > fallback ? _duration : fallback;
  }

  Widget _buildWaveform(Color active, Color inactive) {
    const bars = 28;
    final total = _effectiveDuration;
    final maxMs = total.inMilliseconds <= 0 ? 1 : total.inMilliseconds;
    final progress = (_position.inMilliseconds / maxMs).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final fraction = details.localPosition.dx / constraints.maxWidth;
            _seekToFraction(fraction);
          },
          onHorizontalDragStart: (_) {
            setState(() => _isDragging = true);
          },
          onHorizontalDragUpdate: (details) {
            final fraction = details.localPosition.dx / constraints.maxWidth;
            _seekToFraction(fraction);
          },
          onHorizontalDragEnd: (_) {
            setState(() => _isDragging = false);
          },
          onHorizontalDragCancel: () {
            setState(() => _isDragging = false);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(bars, (index) {
              final normalizedIndex = (index + 1) / bars;
              final isActive = normalizedIndex <= progress;
              final phase = index / bars;
              final height = 6 + (math.sin(phase * math.pi * 3).abs() * 14);

              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  margin: const EdgeInsets.symmetric(horizontal: 1.2),
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: isActive ? active : inactive,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  String _formatRate(double value) {
    final normalized = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    return '${normalized}x';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fgColor = widget.isMe ? Colors.white : theme.colorScheme.onSurface;
    final softColor = fgColor.withAlpha(120);
    final activeWaveColor = widget.isMe
        ? Colors.white
        : AppColors.radiantViolet;
    final inactiveWaveColor = widget.isMe
        ? Colors.white.withAlpha(70)
        : AppColors.radiantViolet.withAlpha(70);
    final total = _effectiveDuration;
    final displayPosition = _position > Duration.zero
        ? _position
        : Duration.zero;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 280),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isMe
                ? [Colors.white.withAlpha(22), Colors.white.withAlpha(6)]
                : [
                    AppColors.radiantViolet.withAlpha(25),
                    AppColors.electricRose.withAlpha(15),
                  ],
          ),
          border: Border.all(
            color: widget.isMe
                ? Colors.white.withAlpha(35)
                : AppColors.radiantViolet.withAlpha(55),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isMe
                  ? Colors.black.withAlpha(20)
                  : AppColors.radiantViolet.withAlpha(25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _togglePlayPause,
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isMe
                      ? Colors.white.withAlpha(25)
                      : AppColors.radiantViolet.withAlpha(16),
                  border: Border.all(
                    color: widget.isMe
                        ? Colors.white.withAlpha(40)
                        : AppColors.radiantViolet.withAlpha(50),
                  ),
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: widget.isMe ? Colors.white : AppColors.radiantViolet,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 22,
                    child: _buildWaveform(activeWaveColor, inactiveWaveColor),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatDuration(displayPosition),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: fgColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ ${_formatDuration(total)}',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: softColor,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _togglePlaybackRate,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: _isDragging
                                ? activeWaveColor.withAlpha(35)
                                : Colors.transparent,
                            border: Border.all(
                              color: activeWaveColor.withAlpha(110),
                            ),
                          ),
                          child: Text(
                            _formatRate(_playbackRate),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: fgColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
