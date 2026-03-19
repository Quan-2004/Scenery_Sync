import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/music_models.dart';
import '../services/deezer_service.dart';
import '../services/jamendo_service.dart';
import 'artist_detail_screen.dart';

class AllArtistsScreen extends StatefulWidget {
  const AllArtistsScreen({super.key});

  @override
  State<AllArtistsScreen> createState() => _AllArtistsScreenState();
}

class _AllArtistsScreenState extends State<AllArtistsScreen> {
  List<Artist> _artists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    final results = await Future.wait([
      DeezerService().getChartArtists(limit: 100),
      JamendoService().getInstrumentalTracks(
        tags: ['ambient', 'nature', 'cinematic'],
        limit: 200,
      ),
    ]);

    final deezerArtists = results[0] as List<Artist>;
    final jamendoTracks = results[1] as List<Track>;

    // Extract unique Jamendo artists from tracks (avoid duplicating Deezer IDs)
    final seenIds = <String>{...deezerArtists.map((a) => a.id)};
    final jamendoArtists = <Artist>[];
    for (final track in jamendoTracks) {
      if (track.artistId.isNotEmpty && !seenIds.contains(track.artistId)) {
        seenIds.add(track.artistId);
        jamendoArtists.add(Artist(
          id: track.artistId,
          name: track.artistName,
          imageUrl: track.imageUrl,
          genres: ['Ambient'],
          followers: 0,
          popularity: track.popularity,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _artists = [...deezerArtists, ...jamendoArtists];
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
              title: Text(
                'all_artists'.tr(),
                style: const TextStyle(
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
          else if (_artists.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'no_artists'.tr(),
                  style: const TextStyle(color: AppColors.textMuted),
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
                  (context, index) => _ArtistGridCard(
                    artist: _artists[index],
                    index: index,
                  ),
                  childCount: _artists.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArtistGridCard extends StatefulWidget {
  final Artist artist;
  final int index;

  const _ArtistGridCard({required this.artist, required this.index});

  @override
  State<_ArtistGridCard> createState() => _ArtistGridCardState();
}

class _ArtistGridCardState extends State<_ArtistGridCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtistDetailScreen(
              artistName: widget.artist.name,
              artistImage: widget.artist.imageUrl,
              artistId: widget.artist.id,
            ),
          ),
        );
      },
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
            children: [
              // Artist Image
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.artist.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.artist.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(height: 12),
              // Artist Name
              Text(
                widget.artist.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Followers or genre tag
              Text(
                widget.artist.followers > 0
                    ? widget.artist.followersFormatted
                    : (widget.artist.genres.isNotEmpty
                        ? widget.artist.genres.first
                        : ''),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
      child: const Icon(Icons.person, size: 60, color: AppColors.primary),
    );
  }
}
