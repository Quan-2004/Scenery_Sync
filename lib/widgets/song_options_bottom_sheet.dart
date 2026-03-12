import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../models/music_models.dart';
import '../services/firebase_service.dart';
import '../services/downloads_service.dart';

class SongOptionsBottomSheet {
  static void show(BuildContext context, {
    required Track track,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SongOptionsSheet(track: track),
    );
  }
}

class _SongOptionsSheet extends StatefulWidget {
  final Track track;
  const _SongOptionsSheet({required this.track});

  @override
  State<_SongOptionsSheet> createState() => _SongOptionsSheetState();
}

class _SongOptionsSheetState extends State<_SongOptionsSheet> {
  bool _isDownloading = false;

  Map<String, dynamic> _trackToMap(Track t) => {
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

  Future<void> _toggleFavorite(bool isFav) async {
    final firebase = Provider.of<FirebaseService>(context, listen: false);
    if (isFav) {
      await firebase.removeFromFavorites(widget.track.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa khỏi Yêu thích')),
        );
      }
    } else {
      await firebase.addToFavorites(_trackToMap(widget.track));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm vào Yêu thích')),
        );
      }
    }
  }

  Future<void> _toggleDownload(bool downloaded) async {
    final dl = DownloadsService.instance;
    if (downloaded) {
      await dl.deleteTrack(widget.track);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài đã tải')),
        );
      }
    } else {
      if (widget.track.previewUrl == null || widget.track.previewUrl!.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bài này không có link tải')),
        );
        return;
      }
      setState(() => _isDownloading = true);
      await dl.downloadTrack(widget.track);
      if (mounted) {
        setState(() => _isDownloading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã tải xong!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebase = Provider.of<FirebaseService>(context, listen: false);
    final track = widget.track;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(track.imageUrl),
                      fit: BoxFit.cover,
                    ),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.artistName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Favorites option - streams real state
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: firebase.favoritesStream(),
            builder: (context, snap) {
              final isFav = (snap.data ?? []).any((f) => f['id'] == track.id);
              return _buildOption(
                context,
                icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                iconColor: isFav ? Colors.red : AppColors.textMain,
                title: isFav ? 'Xóa khỏi Yêu thích' : 'Thêm vào Yêu thích',
                onTap: () => _toggleFavorite(isFav),
              );
            },
          ),
          _buildOption(
            context,
            icon: Icons.playlist_add_rounded,
            title: 'Add to Playlist',
            onTap: () => Navigator.pop(context),
          ),
          // Download option - reads Hive state
          ValueListenableBuilder(
            valueListenable: Hive.box<Map>('downloads').listenable(),
            builder: (context, box, _) {
              final downloaded = DownloadsService.instance.isDownloaded(track.id);
              return _buildOption(
                context,
                icon: downloaded
                    ? Icons.download_done_rounded
                    : Icons.download_outlined,
                iconColor: downloaded ? AppColors.primary : AppColors.textMain,
                title: downloaded ? 'Xóa bài đã tải' : 'Tải xuống',
                onTap: _isDownloading ? null : () => _toggleDownload(downloaded),
                trailing: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              );
            },
          ),
          _buildOption(
            context,
            icon: Icons.queue_music_rounded,
            title: 'Add to Queue',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to Queue')),
              );
            },
          ),
          _buildOption(
            context,
            icon: Icons.share_outlined,
            title: 'Share',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? AppColors.textMain,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMain,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
