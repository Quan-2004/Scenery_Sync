import 'package:flutter/material.dart';
import '../theme/colors.dart';

class MySongsScreen extends StatefulWidget {
  const MySongsScreen({super.key});

  @override
  State<MySongsScreen> createState() => _MySongsScreenState();
}

class _MySongsScreenState extends State<MySongsScreen> {
  String _sortBy = 'recent'; // recent, title, artist, duration

  final List<Map<String, dynamic>> _songs = [];

  List<Map<String, dynamic>> get _sortedSongs {
    final songs = List<Map<String, dynamic>>.from(_songs);
    switch (_sortBy) {
      case 'title':
        songs.sort((a, b) => a['title'].compareTo(b['title']));
        break;
      case 'artist':
        songs.sort((a, b) => a['artist'].compareTo(b['artist']));
        break;
      case 'recent':
      default:
        songs.sort((a, b) => b['addedDate'].compareTo(a['addedDate']));
    }
    return songs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'My Songs',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, color: Colors.white),
                  onSelected: (value) {
                    setState(() {
                      _sortBy = value;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'recent',
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: _sortBy == 'recent' ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Recently Added',
                            style: TextStyle(
                              color: _sortBy == 'recent' ? AppColors.primary : AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'title',
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_by_alpha,
                            size: 20,
                            color: _sortBy == 'title' ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Title',
                            style: TextStyle(
                              color: _sortBy == 'title' ? AppColors.primary : AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'artist',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 20,
                            color: _sortBy == 'artist' ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Artist',
                            style: TextStyle(
                              color: _sortBy == 'artist' ? AppColors.primary : AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _sortedSongs[index];
                  return _SongTile(
                    song: song,
                    onTap: () {
                      // Play song
                    },
                    onMoreTap: () {
                      _showSongOptions(context, song);
                    },
                  );
                },
                childCount: _sortedSongs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSongOptions(BuildContext context, Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.secondary.withOpacity(0.3),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.play_circle, color: AppColors.primary),
                title: const Text('Play Now', style: TextStyle(color: AppColors.textMain)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add, color: AppColors.textMain),
                title: const Text('Add to Playlist', style: TextStyle(color: AppColors.textMain)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.share, color: AppColors.textMain),
                title: const Text('Share', style: TextStyle(color: AppColors.textMain)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove from Library', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final Map<String, dynamic> song;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _SongTile({
    required this.song,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Hero(
          tag: 'song_${song['title']}',
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(song['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        title: Text(
          song['title'],
          style: const TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song['artist'],
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              song['duration'],
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onPressed: onMoreTap,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
