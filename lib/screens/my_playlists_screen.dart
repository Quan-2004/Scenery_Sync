import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';

class MyPlaylistsScreen extends StatefulWidget {
  const MyPlaylistsScreen({super.key});

  @override
  State<MyPlaylistsScreen> createState() => _MyPlaylistsScreenState();
}

class _MyPlaylistsScreenState extends State<MyPlaylistsScreen> {
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
              title: Text(
                'my_playlists'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppColors.secondary,
                      AppColors.primary,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.queue_music_rounded,
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
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 28),
                  onPressed: () {
                    _showCreatePlaylistDialog();
                  },
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: StreamBuilder<List<Map<String, dynamic>>>(
              stream: context.read<FirebaseService>().getUserPlaylists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final playlists = snapshot.data ?? [];
                
                if (playlists.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'no_playlists'.tr(),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final playlist = playlists[index];
                      return _PlaylistCard(
                        playlist: playlist,
                        onTap: () {
                          // Navigate to playlist detail
                        },
                        onMoreTap: () {
                          _showPlaylistOptions(context, playlist);
                        },
                      );
                    },
                    childCount: playlists.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'create_playlist'.tr(),
          style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textMain),
          decoration: InputDecoration(
            hintText: 'playlist_name_hint'.tr(),
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final firebaseService = context.read<FirebaseService>();
                final navigator = Navigator.of(context);

                final error = await firebaseService.createPlaylist(
                  name: nameController.text.trim(),
                  coverImage: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&q=80&w=400',
                );

                navigator.pop(); // Close dialog

                if (error == null) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('playlist_created'.tr(namedArgs: {'name': nameController.text.trim()})),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('create'.tr()),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(BuildContext context, Map<String, dynamic> playlist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.play_circle, color: AppColors.primary),
              title: Text('play_playlist'.tr(), style: const TextStyle(color: AppColors.textMain)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.textMain),
              title: Text('edit_details'.tr(), style: const TextStyle(color: AppColors.textMain)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.textMain),
              title: Text('share'.tr(), style: const TextStyle(color: AppColors.textMain)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('delete_playlist'.tr(), style: const TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Map<String, dynamic> playlist;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _PlaylistCard({
    required this.playlist,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.secondary.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: playlist['coverImage'] != null && playlist['coverImage'].toString().isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(playlist['coverImage']),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: playlist['coverImage'] == null || playlist['coverImage'].toString().isEmpty
                        ? AppColors.primary.withValues(alpha: 0.3) // Or any fallback color
                        : null,
                  ),
                  child: playlist['coverImage'] == null || playlist['coverImage'].toString().isEmpty
                      ? const Center(
                          child: Icon(Icons.music_note, color: Colors.white, size: 50),
                        )
                      : null,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      onPressed: onMoreTap,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist['name'],
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'song_count'.tr(
                      namedArgs: {'count': (playlist['trackCount'] ?? 0).toString()},
                    ),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
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
