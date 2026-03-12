import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import 'lyrics_screen.dart';
import 'queue_screen.dart';
import 'equalizer_screen.dart';
import 'audio_visualizer_screen.dart';
import '../widgets/share_widgets.dart';
import '../services/audio_player_service.dart';
import '../services/firebase_service.dart';
import '../services/downloads_service.dart';
import '../models/music_models.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background Gradient Blur
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Main Content
          SafeArea(
            child: Column(
              children: [
                const _Header(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      child: Column(
                        children: const [
                          _AlbumArt(),
                          SizedBox(height: 24),
                          _TrackInfo(),
                          SizedBox(height: 32),
                          _ProgressBar(),
                          SizedBox(height: 32),
                          _PlaybackControls(),
                          SizedBox(height: 40),
                          _UpNextList(),
                          SizedBox(height: 24),
                          _DeviceSelector(),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconButton(Icons.keyboard_arrow_down_rounded, 28, () => Navigator.pop(context)),
          Column(
            children: [
              Text(
                'NOW PLAYING',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          _buildIconButton(Icons.more_horiz_rounded, 24, () {
            _showOptionsMenu(context);
          }),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.lyrics_rounded, color: AppColors.primary),
              title: const Text('Lyrics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LyricsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.queue_music_rounded, color: AppColors.primary),
              title: const Text('Up Next'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QueueScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.equalizer_rounded, color: AppColors.primary),
              title: const Text('Equalizer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EqualizerScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.graphic_eq_rounded, color: AppColors.primary),
              title: const Text('Visualizer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AudioVisualizerScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share_rounded, color: AppColors.primary),
              title: const Text('Share'),
              onTap: () {
                final player = AudioPlayerService.instance;
                final track = player.currentTrack;
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => ShareMusicWidget(
                    songTitle: track?.name ?? 'Unknown',
                    artistName: track?.artistName ?? 'Unknown',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, double size, VoidCallback onPressed) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: size),
        color: AppColors.textMain,
        onPressed: onPressed,
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  const _AlbumArt();

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayerService.instance;
    
    return StreamBuilder<Track?>(
      stream: player.trackStream,
      builder: (context, snapshot) {
        final track = snapshot.data ?? player.currentTrack;
        final imageUrl = track?.imageUrl ?? 'https://lh3.googleusercontent.com/aida-public/AB6AXuD9fxCh6ix0aWLgour1YPDsqEAdkSI_q85A_PQ-r-IpV15bFAnCSroUA2hJvtpfEecrMtv6AED61ldXvgn4uH-IiRnElltY4h_YrxbBlPx3BnrGwXGEC9aE1okxT9imLOMmawLxC-IYRS_ABtMvc3IXv7FwqF2kmLHHLjcq9SxUET6r8oSBK48CJcInyPnZPeWVO9owgW3QrGXXfzWiJtRErdJyzR2cQ_vRGO1JqxYeoT2y70dxJyRIhCrL-u-OB3Ed4A9wPIaxQw';
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Shadow/Glow
            Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              top: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
              ),
            ),
            
            // Main Image
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: AppColors.surfaceLight,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.surfaceLight,
                        child: const Icon(
                          Icons.music_note,
                          size: 100,
                          color: AppColors.primary,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.surfaceLight,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrackInfo extends StatefulWidget {
  const _TrackInfo();

  @override
  State<_TrackInfo> createState() => _TrackInfoState();
}

class _TrackInfoState extends State<_TrackInfo> {
  bool _isDownloading = false;

  Map<String, dynamic> _trackToFavoriteMap(Track t) => {
        'id': t.id,
        'name': t.name,
        'artistName': t.artistName,
        'artistId': t.artistId,
        'albumName': t.albumName,
        'albumId': t.albumId,
        'imageUrl': t.imageUrl,
        'previewUrl': t.previewUrl ?? '',
        'durationMs': t.durationMs,
        'popularity': t.popularity,
      };

  Future<void> _toggleFavorite(Track track, FirebaseService firebase, bool isFav) async {
    if (isFav) {
      await firebase.removeFromFavorites(track.id);
    } else {
      await firebase.addToFavorites(_trackToFavoriteMap(track));
    }
  }

  Future<void> _toggleDownload(Track track) async {
    final dl = DownloadsService.instance;
    if (dl.isDownloaded(track.id)) {
      await dl.deleteTrack(track);
      if (mounted) setState(() {});
    } else {
      if (track.previewUrl == null || track.previewUrl!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bài này không có link tải')),
          );
        }
        return;
      }
      setState(() => _isDownloading = true);
      await dl.downloadTrack(track);
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayerService.instance;
    final firebase = Provider.of<FirebaseService>(context, listen: false);

    return StreamBuilder<Track?>(
      stream: player.trackStream,
      initialData: player.currentTrack,
      builder: (context, trackSnap) {
        final track = trackSnap.data;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track?.name ?? 'No track',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track?.artistName ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Download button
            if (track != null)
              ValueListenableBuilder(
                valueListenable: Hive.box<Map>('downloads').listenable(),
                builder: (context, box, _) {
                  final downloaded = DownloadsService.instance.isDownloaded(track.id);
                  return _isDownloading
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            downloaded
                                ? Icons.download_done_rounded
                                : Icons.download_outlined,
                            size: 28,
                          ),
                          color: downloaded ? AppColors.primary : AppColors.textMuted,
                          onPressed: () => _toggleDownload(track),
                        );
                },
              ),
            // Favorite button
            if (track != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: firebase.favoritesStream(),
                builder: (context, favSnap) {
                  final isFav = (favSnap.data ?? []).any((f) => f['id'] == track.id);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      size: 28,
                    ),
                    color: isFav ? Colors.red : AppColors.textMuted,
                    onPressed: () => _toggleFavorite(track, firebase, isFav),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _ProgressBar extends StatefulWidget {
  const _ProgressBar();

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double _sliderValue = 0.0;
  bool _isDragging = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayerService.instance;

    return Column(
      children: [
        // Slider
        StreamBuilder<Duration>(
          stream: player.player.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = player.player.duration ?? Duration.zero;

            // Only update slider value when not dragging
            if (!_isDragging && duration.inMilliseconds > 0) {
              _sliderValue = position.inMilliseconds / duration.inMilliseconds;
              _sliderValue = _sliderValue.clamp(0.0, 1.0);
            }

            return SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surfaceLight,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _sliderValue,
                min: 0.0,
                max: 1.0,
                onChangeStart: (value) {
                  setState(() => _isDragging = true);
                },
                onChanged: (value) {
                  setState(() => _sliderValue = value);
                },
                onChangeEnd: (value) async {
                  setState(() => _isDragging = false);
                  final duration = player.player.duration ?? Duration.zero;
                  final newPosition = Duration(
                    milliseconds: (value * duration.inMilliseconds).round(),
                  );
                  await player.seek(newPosition);
                },
              ),
            );
          },
        ),
        // Time labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: StreamBuilder<Duration>(
            stream: player.player.positionStream,
            builder: (context, positionSnapshot) {
              final position = positionSnapshot.data ?? Duration.zero;
              final duration = player.player.duration ?? Duration.zero;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls();

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayerService.instance;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Shuffle button
        StreamBuilder<bool>(
          stream: player.shuffleStream,
          initialData: player.isShuffleOn,
          builder: (context, snapshot) {
            final isShuffleOn = snapshot.data ?? false;
            return IconButton(
              onPressed: () async {
                await player.toggleShuffle();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isShuffleOn ? 'Tắt phát ngẫu nhiên' : 'Bật phát ngẫu nhiên'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.shuffle_rounded, size: 28),
              color: isShuffleOn ? AppColors.primary : AppColors.textMuted,
            );
          },
        ),
        // Previous button
        IconButton(
          onPressed: () async {
            try {
              await player.skipToPrevious();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            }
          },
          icon: const Icon(Icons.skip_previous_rounded, size: 40),
          color: AppColors.textMain,
        ),
        // Play/Pause button
        StreamBuilder<bool>(
          stream: player.playingStream,
          initialData: player.isPlaying,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data ?? false;
            return Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () async {
                  if (isPlaying) {
                    await player.pause();
                  } else {
                    await player.play();
                  }
                },
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 44,
                ),
                color: Colors.white,
              ),
            );
          },
        ),
        // Next button
        IconButton(
          onPressed: () async {
            try {
              await player.skipToNext();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            }
          },
          icon: const Icon(Icons.skip_next_rounded, size: 40),
          color: AppColors.textMain,
        ),
        // Repeat button
        StreamBuilder<RepeatMode>(
          stream: player.repeatStream,
          initialData: player.repeatMode,
          builder: (context, snapshot) {
            final repeatMode = snapshot.data ?? RepeatMode.off;
            IconData iconData;
            Color iconColor;
            String message;
            
            switch (repeatMode) {
              case RepeatMode.off:
                iconData = Icons.repeat_rounded;
                iconColor = AppColors.textMuted;
                message = 'Bật lặp lại tất cả';
                break;
              case RepeatMode.all:
                iconData = Icons.repeat_rounded;
                iconColor = AppColors.primary;
                message = 'Bật lặp lại một bài';
                break;
              case RepeatMode.one:
                iconData = Icons.repeat_one_rounded;
                iconColor = AppColors.primary;
                message = 'Tắt lặp lại';
                break;
            }
            
            return IconButton(
              onPressed: () async {
                await player.toggleRepeat();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              icon: Icon(iconData, size: 28),
              color: iconColor,
            );
          },
        ),
      ],
    );
  }
}

class _UpNextList extends StatelessWidget {
  const _UpNextList();

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayerService.instance;
    
    return StreamBuilder<List<Track>>(
      stream: player.queueStream,
      initialData: player.queue,
      builder: (context, queueSnapshot) {
        final queue = queueSnapshot.data ?? [];
        final currentIndex = player.currentIndex;
        
        // Get next 3 tracks
        final upNext = <Track>[];
        for (int i = 1; i <= 3 && (currentIndex + i) < queue.length; i++) {
          upNext.add(queue[currentIndex + i]);
        }
        
        if (upNext.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Up Next',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QueueScreen()),
                    );
                  },
                  child: const Text(
                    'SEE ALL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...upNext.asMap().entries.map((entry) {
              final track = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: entry.key < upNext.length - 1 ? 12 : 0),
                child: _buildListItem(
                  context,
                  track,
                  currentIndex + entry.key + 1,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context, Track track, int queueIndex) {
    final player = AudioPlayerService.instance;
    
    return GestureDetector(
      onTap: () async {
        try {
          await player.skipToIndex(queueIndex);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: $e')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator_rounded, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                track.imageUrl,
                height: 48,
                width: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 48,
                    width: 48,
                    color: AppColors.surfaceLight,
                    child: const Icon(Icons.music_note, color: AppColors.textMuted),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artistName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                try {
                  await player.removeFromQueue(queueIndex);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa khỏi hàng chờ'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceSelector extends StatelessWidget {
  const _DeviceSelector();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.speaker_group_outlined, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Text(
            'AirPods Pro',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}