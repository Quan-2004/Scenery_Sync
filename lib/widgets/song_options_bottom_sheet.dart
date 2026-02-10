import 'package:flutter/material.dart';
import '../theme/colors.dart';

class SongOptionsBottomSheet {
  static void show(BuildContext context, {
    required String songTitle,
    required String artistName,
    required String imageUrl,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
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
                color: AppColors.textMuted.withOpacity(0.3),
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
                        image: NetworkImage(imageUrl),
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
                          songTitle,
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
                          artistName,
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
            _buildOption(
              context,
              icon: Icons.favorite_border_rounded,
              title: 'Add to Favorites',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to Favorites')),
                );
              },
            ),
            _buildOption(
              context,
              icon: Icons.playlist_add_rounded,
              title: 'Add to Playlist',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context,
              icon: Icons.download_outlined,
              title: 'Download',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloading...')),
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
              icon: Icons.album_outlined,
              title: 'Go to Album',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context,
              icon: Icons.person_outline_rounded,
              title: 'Go to Artist',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context,
              icon: Icons.share_outlined,
              title: 'Share',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context,
              icon: Icons.info_outline_rounded,
              title: 'Song Info',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textMain,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
