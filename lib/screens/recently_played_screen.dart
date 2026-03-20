import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/colors.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';

class RecentlyPlayedScreen extends StatefulWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  State<RecentlyPlayedScreen> createState() => _RecentlyPlayedScreenState();
}

class _RecentlyPlayedScreenState extends State<RecentlyPlayedScreen> {
  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    if (!firebaseService.isLoggedIn) {
      return _buildLoginRequired(context);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: firebaseService.getRecentlyPlayed(limit: 100),
          builder: (context, snapshot) {
            final tracks = snapshot.data ?? [];

            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                    ),
                  ),
                  actions: [
                    if (tracks.isNotEmpty)
                      IconButton(
                        onPressed: () => _clearHistory(context, firebaseService),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                  ],
                  flexibleSpace: const FlexibleSpaceBar(
                    title: Text(
                      'Lịch sử nghe',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    titlePadding: EdgeInsets.only(left: 64, bottom: 16),
                  ),
                ),

                // Stats Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _buildStat('Bài hát', tracks.length.toString())),
                          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                          Expanded(
                            child: _buildStat(
                              'Lượt nghe',
                              tracks.fold<int>(0, (sum, t) {
                                final pc = t['playCount'];
                                return sum + (pc is int ? pc : (pc is num ? pc.toInt() : 1));
                              }).toString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Empty State
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (tracks.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có bài hát nào được nghe',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hãy khám phá và nghe nhạc!',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = tracks[index];
                        return _buildHistoryItem(context, track, firebaseService);
                      },
                      childCount: tracks.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  String _formatTime(dynamic playedAt) {
    if (playedAt == null) return '';
    DateTime dt;
    if (playedAt is Timestamp) {
      dt = playedAt.toDate();
    } else {
      return '';
    }
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildHistoryItem(
    BuildContext context,
    Map<String, dynamic> track,
    FirebaseService firebaseService,
  ) {
    final title = track['title'] ?? track['name'] ?? 'Unknown';
    final artist = track['artist'] ?? track['artistName'] ?? '';
    final imageUrl = track['imageUrl'] ?? track['artworkUrl'] ?? '';
    final playedAt = track['playedAt'];
    final playCount = track['playCount'] ?? 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cover art or default icon
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 52, height: 52, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultCover(),
                  )
                : _defaultCover(),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (artist.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    artist,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(playedAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.play_circle_outline, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(
                      '$playCount lần',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // More Options
          IconButton(
            onPressed: () => _showOptions(context, track, firebaseService),
            icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _defaultCover() {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.secondary.withValues(alpha: 0.2)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.music_note_rounded, color: AppColors.primary, size: 28),
    );
  }

  void _showOptions(
    BuildContext context,
    Map<String, dynamic> track,
    FirebaseService firebaseService,
  ) {
    final trackId = track['id']?.toString() ?? '';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
              title: Text('Xóa khỏi lịch sử', style: TextStyle(color: Colors.red.shade400)),
              onTap: () async {
                Navigator.pop(ctx);
                if (trackId.isNotEmpty) {
                  final uid = firebaseService.userId;
                  if (uid != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('recently_played')
                        .doc(trackId)
                        .delete();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clearHistory(BuildContext context, FirebaseService firebaseService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa lịch sử nghe'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử nghe nhạc?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uid = firebaseService.userId;
              if (uid == null) return;
              final col = FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('recently_played');
              final snap = await col.get();
              final batch = FirebaseFirestore.instance.batch();
              for (final d in snap.docs) {
                batch.delete(d.reference);
              }
              await batch.commit();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Đã xóa lịch sử nghe'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Lịch sử nghe', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Đăng nhập để xem lịch sử nghe', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
