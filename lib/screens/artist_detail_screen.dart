import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../services/deezer_service.dart';
import '../services/audio_player_service.dart';
import '../models/music_models.dart';
import 'now_playing_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistName;
  final String artistImage;
  final String? artistId;

  const ArtistDetailScreen({
    super.key,
    required this.artistName,
    required this.artistImage,
    this.artistId,
  });

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  final _deezerService = DeezerService();
  List<Track> _tracks = [];
  bool _isLoading = true;
  bool _isPlayLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      List<Track> tracks;
      if (widget.artistId != null && widget.artistId!.isNotEmpty) {
        tracks = await _deezerService.getArtistTopTracks(
          widget.artistId!,
          limit: 20,
        );
      } else {
        tracks = await _deezerService.searchTracks(
          widget.artistName,
          limit: 20,
        );
      }
      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _playAll() async {
    if (_tracks.isEmpty) return;
    setState(() => _isPlayLoading = true);
    try {
      await AudioPlayerService.instance.setQueue(_tracks, startIndex: 0);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlayLoading = false);
    }
  }

  String _formatDuration(int ms) {
    final totalSec = ms ~/ 1000;
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          _buildContent(),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.artistImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primary.withValues(alpha: 0.2),
                child: const Icon(Icons.person_rounded,
                    size: 80, color: AppColors.primary),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.artistName,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_isLoading && _tracks.isNotEmpty)
                    Text(
                      'tracks_on_deezer'.tr(namedArgs: {'count': '${_tracks.length}'}),
                      style: const TextStyle(
                          fontSize: 14, color: Colors.white70),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverList _buildContent() {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 24),
        _buildActionButtons(),
        const SizedBox(height: 24),
        _buildPopularSection(),
        const SizedBox(height: 70),
      ]),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: (_tracks.isEmpty || _isPlayLoading) ? null : _playAll,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        icon: _isPlayLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow_rounded, size: 28),
        label: Text(
          'play'.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPopularSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'popular'.tr(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_tracks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('no_tracks_found'.tr(),
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
          )
        else
          ..._tracks.asMap().entries.map((entry) {
            final index = entry.key;
            final track = entry.value;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () async {
                  await AudioPlayerService.instance
                      .setQueue(_tracks, startIndex: index);
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NowPlayingScreen()),
                    );
                  }
                },
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: track.imageUrl.isNotEmpty
                          ? Image.network(
                              track.imageUrl,
                              height: 48,
                              width: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholderArt(),
                            )
                          : _placeholderArt(),
                    ),
                  ],
                ),
                title: Text(
                  track.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.textMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  track.artistName,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatDuration(track.durationMs),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _placeholderArt() {
    return Container(
      height: 48,
      width: 48,
      color: AppColors.primary.withValues(alpha: 0.2),
      child: const Icon(Icons.music_note_rounded, color: AppColors.primary),
    );
  }
}
