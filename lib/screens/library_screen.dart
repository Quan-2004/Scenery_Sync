import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/colors.dart';
import '../services/app_language.dart';
import '../services/deezer_service.dart';
import '../models/music_models.dart';
import '../services/audio_player_service.dart';
import '../services/firebase_service.dart';
import 'playlist_detail_screen.dart';
import 'artist_detail_screen.dart';
import 'now_playing_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background Gradient
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
                    AppColors.secondary.withOpacity(0.3),
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
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: const _Header(),
                  ),
                ),
                Expanded(
                  child: DefaultTabController(
                    length: 4,
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: const _TabBar(),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _PlaylistsTab(),
                              _SongsTab(),
                              _AlbumsTab(),
                              _ArtistsTab(),
                            ],
                          ),
                        ),
                      ],
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

  void _showCreatePlaylistDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Create Playlist',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Playlist name',
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playlist "${nameController.text}" created!'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLanguage().translate('library'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          GestureDetector(
            onTap: () => _showCreatePlaylistDialog(context),
            child: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: TabBar(
        isScrollable: true,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(text: AppLanguage().translate('playlists')),
          Tab(text: AppLanguage().translate('songs')),
          Tab(text: AppLanguage().translate('albums')),
          Tab(text: AppLanguage().translate('artists')),
        ],
      ),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final playlists = [
      {'name': 'My Favorites', 'count': '42 songs', 'color': AppColors.primary},
      {'name': 'Workout Mix', 'count': '28 songs', 'color': const Color(0xFFE85D75)},
      {'name': 'Chill Vibes', 'count': '35 songs', 'color': const Color(0xFF6B8CFF)},
      {'name': 'Study Focus', 'count': '51 songs', 'color': const Color(0xFF4CAF50)},
      {'name': 'Party Time', 'count': '39 songs', 'color': const Color(0xFFFF9800)},
      {'name': 'Road Trip', 'count': '46 songs', 'color': const Color(0xFF9C27B0)},
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
      itemCount: playlists.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 80)),
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
          child: _PlaylistItem(playlist: playlist),
        );
      },
    );
  }
}

class _PlaylistItem extends StatefulWidget {
  final Map<String, Object> playlist;

  const _PlaylistItem({required this.playlist});

  @override
  State<_PlaylistItem> createState() => _PlaylistItemState();
}

class _PlaylistItemState extends State<_PlaylistItem> {
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
            builder: (context) => PlaylistDetailScreen(
              playlistName: widget.playlist['name'] as String,
              playlistCover: 'https://picsum.photos/400/400',
              songCount: int.parse((widget.playlist['count'] as String).split(' ')[0]),
            ),
          ),
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.02 : 0.05),
                blurRadius: _isPressed ? 5 : 10,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: (widget.playlist['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: widget.playlist['color'] as Color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.playlist['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.playlist['count'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_vert_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongsTab extends StatefulWidget {
  const _SongsTab();

  @override
  State<_SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<_SongsTab> {
  Future<void> _deleteTrack(BuildContext context, Track track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Xóa bài hát?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa "${track.name}"?\nHành động này không thể hoàn tác.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang xóa bài hát...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Delete from Firestore
      await FirebaseFirestore.instance.collection('tracks').doc(track.id).delete();

      // Optionally delete from Cloudinary
      // Note: This requires Cloudinary admin API credentials
      // For now, we'll just delete from Firestore
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa "${track.name}"'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayerService.instance;
    final firebaseService = FirebaseService();
    final profile = firebaseService.userProfile;
    final isAdmin = profile != null && profile['isAdmin'] == true;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('tracks').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error loading tracks: ${snapshot.error}',
                style: const TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final docs = snapshot.data!.docs;
        final tracks = docs
            .map((d) => Track.fromFirestore(d.data(), id: d.id))
            .where((t) => t.previewUrl != null && t.previewUrl!.trim().isNotEmpty)
            .toList();

        if (tracks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_off_rounded,
                  size: 80,
                  color: AppColors.textMuted.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No songs found',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Chưa có bài hát. Hãy đợi Admin upload nhạc.',
                    style: TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 140),
          itemCount: tracks.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final track = tracks[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 40)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: track.imageUrl.isNotEmpty
                      ? Image.network(
                          track.imageUrl,
                          height: 48,
                          width: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                ),
                title: Text(
                  track.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  track.artistName,
                  style: const TextStyle(color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: Colors.red,
                        onPressed: () => _deleteTrack(context, track),
                        tooltip: 'Xóa bài hát',
                      ),
                    IconButton(
                      icon: const Icon(Icons.play_circle_filled),
                      color: AppColors.primary,
                      onPressed: () async {
                        if (context.mounted) {
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Đang tải bài hát...'),
                              duration: Duration(minutes: 5),
                            ),
                          );
                        }
                        try {
                          await player.setTrack(track);
                          await player.play();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Playing ${track.name}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            final msg = e.toString();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Không phát được: $msg')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                onTap: () async {
                  if (context.mounted) {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Đang tải bài hát...'),
                        duration: Duration(minutes: 5),
                      ),
                    );
                  }
                  try {
                    await player.setTrack(track);
                    await player.play();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      // Mở màn hình Now Playing
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NowPlayingScreen(),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      final msg = e.toString();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Không phát được: $msg')),
                      );
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _AlbumsTab extends StatefulWidget {
  const _AlbumsTab();

  @override
  State<_AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<_AlbumsTab> {
  final DeezerService _deezerService = DeezerService();
  List<Album> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() => _isLoading = true);
    try {
      // Get chart tracks and extract unique albums
      final tracks = await _deezerService.getChartTracks(limit: 50);
      final Map<String, Album> albumMap = {};
      
      for (var track in tracks) {
        if (!albumMap.containsKey(track.albumId)) {
          albumMap[track.albumId] = Album(
            id: track.albumId,
            name: track.albumName,
            artistName: track.artistName,
            imageUrl: track.imageUrl,
            releaseDate: '',
            totalTracks: 0,
          );
        }
      }

      if (mounted) {
        setState(() {
          _albums = albumMap.values.take(20).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading albums: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.album_rounded,
              size: 80,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No albums found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAlbums,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 50)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: () {
              // Navigate to album detail or artist detail
              // For now just show a message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening ${album.name}')),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: album.imageUrl.isNotEmpty
                      ? Image.network(
                          album.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.album_rounded,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.album_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                album.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                album.artistName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

class _ArtistsTab extends StatefulWidget {
  const _ArtistsTab();

  @override
  State<_ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends State<_ArtistsTab> {
  final DeezerService _deezerService = DeezerService();
  List<Artist> _artists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    setState(() => _isLoading = true);
    try {
      // Get chart tracks and extract unique artists
      final tracks = await _deezerService.getChartTracks(limit: 50);
      final Map<String, Artist> artistMap = {};
      
      for (var track in tracks) {
        if (!artistMap.containsKey(track.artistId)) {
          artistMap[track.artistId] = Artist(
            id: track.artistId,
            name: track.artistName,
            imageUrl: track.imageUrl,
            genres: [],
            followers: 0,
            popularity: 0,
          );
        }
      }

      if (mounted) {
        setState(() {
          _artists = artistMap.values.take(20).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading artists: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_rounded,
              size: 80,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No artists found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArtists,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
      itemCount: _artists.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 50)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArtistDetailScreen(
                    artistName: artist.name,
                    artistImage: artist.imageUrl,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            child: Row(
              children: [
                ClipOval(
                  child: artist.imageUrl.isNotEmpty
                      ? Image.network(
                          artist.imageUrl,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                                size: 32,
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Artist',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_filled),
                  color: AppColors.primary,
                  iconSize: 32,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Playing ${artist.name}\'s top tracks...'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }
}

// Dialog for uploading track with info
class _UploadTrackDialog extends StatefulWidget {
  const _UploadTrackDialog();

  @override
  State<_UploadTrackDialog> createState() => _UploadTrackDialogState();
}

class _UploadTrackDialogState extends State<_UploadTrackDialog> {
  final _nameController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  bool _uploadImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: const Text(
        'Thông tin bài hát',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên bài hát',
                hintText: 'Nhập tên bài hát',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _artistController,
              decoration: InputDecoration(
                labelText: 'Nghệ sĩ',
                hintText: 'Nhập tên nghệ sĩ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _albumController,
              decoration: InputDecoration(
                labelText: 'Album (tùy chọn)',
                hintText: 'Nhập tên album',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _uploadImage,
              onChanged: (value) {
                setState(() {
                  _uploadImage = value ?? false;
                });
              },
              title: const Text(
                'Thêm ảnh bìa',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMain,
                ),
              ),
              subtitle: const Text(
                'Chọn ảnh từ máy và upload lên Cloudinary',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              activeColor: AppColors.primary,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Hủy',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final artist = _artistController.text.trim();
            final album = _albumController.text.trim();

            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập tên bài hát')),
              );
              return;
            }

            Navigator.pop(context, {
              'name': name,
              'artistName': artist.isEmpty ? 'Unknown Artist' : artist,
              'albumName': album,
              'imageUrl': _uploadImage ? 'UPLOAD' : '',
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Tiếp tục'),
        ),
      ],
    );
  }
}
