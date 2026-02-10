import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../screens/now_playing_screen.dart';
import '../services/audio_player_service.dart';
import '../models/music_models.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // Ensure audio session is configured
    AudioPlayerService.instance.init();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayerService.instance;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppColors.surfaceLight.withOpacity(0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main Content
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Album Art
                        Hero(
                          tag: 'album_art',
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: StreamBuilder<Track?>(
                                stream: player.trackStream,
                                builder: (context, snapshot) {
                                  final imageUrl = snapshot.data?.imageUrl ??
                                      'https://via.placeholder.com/120x120.png?text=Music';
                                  return Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        
                        // Song Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StreamBuilder<Track?>(
                                stream: player.trackStream,
                                builder: (context, snapshot) {
                                  final title = snapshot.data?.name ?? 'No track';
                                  return Text(
                                    title,
                                    style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                  letterSpacing: -0.3,
                                  height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.music_note_rounded,
                                    size: 13,
                                    color: AppColors.textMuted,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: StreamBuilder<Track?>(
                                      stream: player.trackStream,
                                      builder: (context, snapshot) {
                                        final subtitle = snapshot.data?.artistName ?? 'Choose a song';
                                        return Text(
                                          subtitle,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Control Buttons
                        _buildControlButton(
                          icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          onTap: () {
                            setState(() {
                              _isFavorite = !_isFavorite;
                            });
                          },
                          color: _isFavorite ? Colors.red : AppColors.textMuted,
                          size: 21,
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Play Button
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final playing = player.isPlaying;
                                if (playing) {
                                  await player.pause();
                                } else {
                                  await player.play();
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: StreamBuilder<bool>(
                                stream: player.playingStream,
                                builder: (context, snapshot) {
                                  final playing = snapshot.data ?? false;
                                  return Icon(
                                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Progress Bar
                StreamBuilder<double>(
                  stream: player.progressStream,
                  builder: (context, snapshot) {
                    final pct = snapshot.data ?? 0.0;
                    return Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pct.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    double size = 22,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(9),
          child: Icon(
            icon,
            color: color,
            size: size,
          ),
        ),
      ),
    );
  }
}
