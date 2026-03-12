import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/music_models.dart';
import '../services/downloads_service.dart';
import '../services/audio_player_service.dart';
import 'now_playing_screen.dart';

class MySongsScreen extends StatefulWidget {
  const MySongsScreen({super.key});

  @override
  State<MySongsScreen> createState() => _MySongsScreenState();
}

class _MySongsScreenState extends State<MySongsScreen> {
  List<Track> _tracks = [];
  bool _isLoading = true;
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    final tracks = DownloadsService.instance.getDownloadedTracks();
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    }
  }

  List<Track> get _sortedTracks {
    final list = List<Track>.from(_tracks);
    switch (_sortBy) {
      case 'title':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'artist':
        list.sort((a, b) => a.artistName.compareTo(b.artistName));
        break;
      default:
        break;
    }
    return list;
  }

  Future<void> _playTrack(List<Track> sorted, int index) async {
    await AudioPlayerService.instance.setQueue(sorted, startIndex: index);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedTracks;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Downloaded Songs',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.download_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: Colors.white),
                onSelected: (v) => setState(() => _sortBy = v),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'recent', child: Text('Recently Added')),
                  PopupMenuItem(value: 'title', child: Text('Title')),
                  PopupMenuItem(value: 'artist', child: Text('Artist')),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (sorted.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.download_outlined,
                      size: 80,
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No downloaded songs',
                      style: TextStyle(fontSize: 18, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Download songs to listen offline',
                      style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = sorted[index];
                    return _TrackTile(
                      track: track,
                      onTap: () => _playTrack(sorted, index),
                      onDelete: () async {
                        await DownloadsService.instance.deleteTrack(track);
                        _loadTracks();
                      },
                    );
                  },
                  childCount: sorted.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TrackTile({
    required this.track,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: track.imageUrl.isNotEmpty
              ? Image.network(
                  track.imageUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        title: Text(
          track.name,
          style: const TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.artistName,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              track.duration,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }
}
