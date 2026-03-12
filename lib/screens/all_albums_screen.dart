import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/music_models.dart';
import '../services/deezer_service.dart';
import '../services/jamendo_service.dart';
import '../services/audio_player_service.dart';
import 'now_playing_screen.dart';

class AllAlbumsScreen extends StatefulWidget {
  const AllAlbumsScreen({super.key});

  @override
  State<AllAlbumsScreen> createState() => _AllAlbumsScreenState();
}

class _AllAlbumsScreenState extends State<AllAlbumsScreen> {
  List<_AlbumEntry> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final results = await Future.wait([
      DeezerService().getChartTracks(limit: 100),
      JamendoService().getInstrumentalTracks(
        tags: ['ambient', 'nature', 'cinematic'],
        limit: 200,
      ),
    ]);

    final deezerTracks = results[0];
    final jamendoTracks = results[1];

    final seenIds = <String>{};
    final albums = <_AlbumEntry>[];

    for (final track in [...deezerTracks, ...jamendoTracks]) {
      if (track.albumId.isNotEmpty && !seenIds.contains(track.albumId)) {
        seenIds.add(track.albumId);
        // Jamendo track IDs contain only digits; Deezer artist IDs are also
        // numeric but higher range. We tag source so playback uses the right API.
        final isJamendo = jamendoTracks.any((t) => t.albumId == track.albumId);
        albums.add(_AlbumEntry(
          id: track.albumId,
          name: track.albumName.isNotEmpty ? track.albumName : 'Unknown Album',
          artistName: track.artistName,
          imageUrl: track.imageUrl,
          isJamendo: isJamendo,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _albums = albums;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textMain,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'All Albums',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
            ),
          ),
          // Loading / Empty / Grid
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_albums.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No albums available',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _AlbumGridCard(
                    entry: _albums[index],
                    index: index,
                  ),
                  childCount: _albums.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Internal model that carries the "source" flag for correct playback routing
class _AlbumEntry {
  final String id;
  final String name;
  final String artistName;
  final String imageUrl;
  final bool isJamendo;

  const _AlbumEntry({
    required this.id,
    required this.name,
    required this.artistName,
    required this.imageUrl,
    required this.isJamendo,
  });
}

class _AlbumGridCard extends StatefulWidget {
  final _AlbumEntry entry;
  final int index;

  const _AlbumGridCard({required this.entry, required this.index});

  @override
  State<_AlbumGridCard> createState() => _AlbumGridCardState();
}

class _AlbumGridCardState extends State<_AlbumGridCard> {
  bool _isPressed = false;
  bool _isLoading = false;

  Future<void> _playAlbum() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    List<Track> tracks;
    if (widget.entry.isJamendo) {
      tracks = await JamendoService().searchInstrumental(
        widget.entry.name,
        limit: 15,
      );
    } else {
      tracks = await DeezerService().getAlbumTracks(widget.entry.id, limit: 20);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (tracks.isEmpty) return;

    await AudioPlayerService.instance.setQueue(tracks, startIndex: 0);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _playAlbum,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (widget.index * 50)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: child,
            ),
          );
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Album Art
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isLoading
                      ? Container(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : widget.entry.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.entry.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                ),
              ),
              const SizedBox(height: 10),
              // Album Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.entry.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              // Artist Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.entry.artistName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
      child: const Icon(Icons.album, size: 60, color: AppColors.primary),
    );
  }
}
