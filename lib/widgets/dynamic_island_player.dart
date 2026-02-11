import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../screens/now_playing_screen.dart';
import '../models/music_models.dart';
import '../services/audio_player_service.dart'
    show AudioPlayerService, RepeatMode;

class DynamicIslandPlayer extends StatefulWidget {
  const DynamicIslandPlayer({super.key});

  @override
  State<DynamicIslandPlayer> createState() => _DynamicIslandPlayerState();
}

class _DynamicIslandPlayerState extends State<DynamicIslandPlayer>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isPlaying = false;
  bool _isShuffled = false;
  bool _isLiked = false;
  int _repeatMode = 0; // 0: off, 1: repeat all, 2: repeat one
  double _progress = 0.0;
  double _volume = 0.7;

  Track? _track;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription<Track?>? _trackSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<double>? _progressSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<bool>? _shuffleSub;
  StreamSubscription<RepeatMode>? _repeatSub;

  late AnimationController _animationController;
  late AnimationController _waveAnimationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _contentAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    final player = AudioPlayerService.instance;
    _track = player.currentTrack;
    _isPlaying = player.isPlaying;
    _isShuffled = player.isShuffleOn;
    _repeatMode = player.repeatMode.index;

    _trackSub = player.trackStream.listen((t) {
      if (!mounted) return;
      setState(() {
        _track = t;
      });
    });

    _playingSub = player.playingStream.listen((playing) {
      if (!mounted) return;
      setState(() {
        _isPlaying = playing;
      });
    });

    _progressSub = player.progressStream.listen((pct) {
      if (!mounted) return;
      setState(() {
        _progress = pct;
      });
    });

    // Listen to position stream for real-time progress
    _positionSub = player.player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });
    });

    // Listen to duration stream
    _durationSub = player.player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() {
        _totalDuration = duration ?? Duration.zero;
      });
    });

    // Initialize current position and duration
    _currentPosition = player.player.position;
    _totalDuration = player.player.duration ?? Duration.zero;

    // Listen to shuffle changes
    _shuffleSub = player.shuffleStream.listen((isShuffled) {
      if (!mounted) return;
      setState(() {
        _isShuffled = isShuffled;
      });
    });

    // Listen to repeat mode changes
    _repeatSub = player.repeatStream.listen((mode) {
      if (!mounted) return;
      setState(() {
        _repeatMode = mode.index;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _waveAnimationController.dispose();
    _trackSub?.cancel();
    _playingSub?.cancel();
    _progressSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _shuffleSub?.cancel();
    _repeatSub?.cancel();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _togglePlayPause() async {
    final player = AudioPlayerService.instance;
    if (player.currentTrack == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chưa có bài đang phát.')));
      return;
    }

    try {
      if (player.isPlaying) {
        await player.pause();
      } else {
        await player.play();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không điều khiển được phát nhạc: $e')),
      );
    }
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLiked ? '❤️ Added to Liked Songs' : '💔 Removed from Liked Songs',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _isLiked ? AppColors.primary : Colors.grey.shade700,
      ),
    );
  }

  Future<void> _toggleShuffle() async {
    await AudioPlayerService.instance.toggleShuffle();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isShuffled ? '🔀 Shuffle ON' : '➡️ Shuffle OFF'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleRepeat() async {
    await AudioPlayerService.instance.toggleRepeat();
    if (!mounted) return;
    final mode = _repeatMode == 0
        ? 'OFF'
        : _repeatMode == 1
        ? 'ALL'
        : 'ONE';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔁 Repeat $mode'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _skipPrevious() async {
    try {
      await AudioPlayerService.instance.skipToPrevious();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _skipNext() async {
    try {
      await AudioPlayerService.instance.skipToNext();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _openNowPlaying() {
    if (_track == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chưa có bài đang phát.')));
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NowPlayingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Stash state: 0 = Center, -1 = Left (Stashed), 1 = Right (Stashed)
  int _stashState = 0;
  double _dragOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    // 1. Auto-hide if no track is loaded
    if (_track == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaTop = MediaQuery.of(context).padding.top;

    // Calculate position based on stash state
    double leftPosition;
    if (_stashState == 0) {
      // Center
      leftPosition =
          (screenWidth / 2) - (_isExpanded ? (screenWidth - 32) / 2 : 100);
      // Adjust for drag
      if (!_isExpanded) leftPosition += _dragOffset;
    } else if (_stashState == -1) {
      // Stashed Left (show small part)
      leftPosition = -180; // Tuck most of it away
    } else {
      // Stashed Right
      leftPosition = screenWidth - 20; // Show small part
    }

    // Width logic
    double width;
    if (_isExpanded) {
      width = screenWidth - 32;
    } else if (_stashState != 0) {
      width = 200; // Keep original width but hide it
    } else {
      width = 200;
    }

    return Stack(
      children: [
        // Overlay when expanded (to tap outside and close)
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleExpanded,
              child: Container(color: Colors.transparent),
            ),
          ),

        AnimatedPositioned(
          duration: _dragOffset == 0
              ? const Duration(milliseconds: 400)
              : Duration.zero,
          curve: Curves.easeOutBack,
          top: safeAreaTop + 8,
          left: _isExpanded
              ? 16
              : (_stashState == 0
                    ? (screenWidth / 2) - 100 + _dragOffset
                    : (_stashState == 1 ? screenWidth - 40 : -160)),
          right: _isExpanded ? 16 : null,
          child: GestureDetector(
            onHorizontalDragUpdate: _isExpanded
                ? null
                : (details) {
                    setState(() {
                      _dragOffset += details.delta.dx;
                    });
                  },
            onHorizontalDragEnd: _isExpanded
                ? null
                : (details) {
                    // Snap logic
                    final velocity = details.primaryVelocity ?? 0;
                    final threshold = screenWidth * 0.25;

                    setState(() {
                      if (_stashState == 0) {
                        // From Center -> Stash
                        if (_dragOffset > threshold || velocity > 500) {
                          _stashState = 1; // Stash Right
                        } else if (_dragOffset < -threshold ||
                            velocity < -500) {
                          _stashState = -1; // Stash Left
                        }
                        _dragOffset = 0;
                      } else {
                        // From Stashed -> Center
                        // Any significant swipe towards center should restore it
                        if ((_stashState == 1 && velocity < -200) ||
                            (_stashState == -1 && velocity > 200)) {
                          _stashState = 0;
                        }
                        // Tap to restore is handled in onTap
                      }
                    });
                  },
            onTap: () {
              if (_stashState != 0) {
                setState(() => _stashState = 0); // Unstash
              } else if (!_isExpanded) {
                _toggleExpanded();
              }
            },
            onLongPress: _stashState == 0 ? _toggleExpanded : null,
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                // Opacity/Look when stashed
                final isStashed = _stashState != 0;

                final currentHeight = 46.0 + (_expandAnimation.value * 166.0);
                final borderRadius = 20.0;

                return Opacity(
                  opacity: isStashed ? 0.6 : 1.0,
                  child: Container(
                    width: _isExpanded ? null : 200.0,
                    height: currentHeight,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(borderRadius),
                        child: _isExpanded
                            ? _buildExpandedView()
                            : _buildCompactView(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactView() {
    final track = _track;
    final title = track?.name.trim().isNotEmpty == true
        ? track!.name
        : 'Unknown';
    final artist = track?.artistName.trim().isNotEmpty == true
        ? track!.artistName
        : 'Unknown Artist';
    final artUrl = track?.imageUrl.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Original behavior: only tapping the album art opens NowPlaying.
          GestureDetector(
            onTap: _openNowPlaying,
            child: Hero(
              tag: 'album_art_hero',
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: AppColors.primary.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: artUrl.isNotEmpty
                      ? Image.network(
                          artUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.music_note_rounded,
                              color: AppColors.primary,
                              size: 16,
                            );
                          },
                        )
                      : const Icon(
                          Icons.music_note_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  artist,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 24, height: 24, child: _buildWaveform()),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    final track = _track;
    final title = track?.name.trim().isNotEmpty == true
        ? track!.name
        : 'Unknown';
    final artist = track?.artistName.trim().isNotEmpty == true
        ? track!.artistName
        : 'Unknown Artist';
    final artUrl = track?.imageUrl.trim() ?? '';
    // Sử dụng duration thực tế từ AudioPlayer thay vì track.durationMs
    final totalMs = _totalDuration.inMilliseconds;

    return AnimatedBuilder(
      animation: _contentAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _contentAnimation.value,
          child: Transform.scale(
            scale: 0.9 + (_contentAnimation.value * 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _openNowPlaying,
                          child: Hero(
                            tag: 'album_art_hero',
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  artUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      child: const Icon(
                                        Icons.album_rounded,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _openNowPlaying,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  artist,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleLike,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _isLiked
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_outline_rounded,
                              color: _isLiked
                                  ? AppColors.primary
                                  : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            thumbColor: Colors.white,
                            overlayColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          child: Slider(
                            value: _progress,
                            onChanged: (value) {
                              if (totalMs <= 0) return;
                              setState(() {
                                _progress = value;
                              });
                              AudioPlayerService.instance.seek(
                                Duration(
                                  milliseconds: (totalMs * value).round(),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_currentPosition),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _formatDuration(_totalDuration),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          _isShuffled
                              ? Icons.shuffle_on_rounded
                              : Icons.shuffle_rounded,
                          _toggleShuffle,
                          size: 20,
                          isActive: _isShuffled,
                        ),
                        _buildControlButton(
                          Icons.skip_previous_rounded,
                          _skipPrevious,
                          size: 28,
                        ),
                        _buildControlButton(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          _togglePlayPause,
                          size: 32,
                          isPrimary: true,
                        ),
                        _buildControlButton(
                          Icons.skip_next_rounded,
                          _skipNext,
                          size: 28,
                        ),
                        _buildControlButton(
                          _repeatMode == 0
                              ? Icons.repeat_rounded
                              : _repeatMode == 1
                              ? Icons.repeat_on_rounded
                              : Icons.repeat_one_rounded,
                          _toggleRepeat,
                          size: 20,
                          isActive: _repeatMode > 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.volume_down_rounded,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 10,
                              ),
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: _volume,
                              onChanged: (value) {
                                setState(() {
                                  _volume = value;
                                });
                                // Điều chỉnh volume thực tế
                                AudioPlayerService.instance.player.setVolume(
                                  value,
                                );
                              },
                            ),
                          ),
                        ),
                        Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 20,
                        ),
                      ],
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

  Widget _buildControlButton(
    IconData icon,
    VoidCallback onPressed, {
    double size = 22,
    bool isPrimary = false,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isPrimary ? 56 : 44,
        height: isPrimary ? 56 : 44,
        decoration: BoxDecoration(
          color: isPrimary
              ? Colors.white
              : isActive
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: isActive && !isPrimary
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Icon(
          icon,
          color: isPrimary
              ? Colors.black
              : isActive
              ? AppColors.primary
              : Colors.white,
          size: size,
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _waveAnimationController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final baseHeight = 4.0;
            final maxHeight = 16.0;
            final animValue = _waveAnimationController.value;

            double height = baseHeight;
            if (_isPlaying) {
              if (index == 0) {
                height = baseHeight + (maxHeight - baseHeight) * animValue;
              } else if (index == 1) {
                height =
                    baseHeight + (maxHeight - baseHeight) * (1 - animValue);
              } else {
                height = baseHeight + (maxHeight - baseHeight) * animValue;
              }
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: _isPlaying
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}
