import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../services/app_language.dart';
import 'now_playing_screen.dart';
import 'genre_detail_screen.dart';
import 'downloads_screen.dart';
import 'recently_played_screen.dart';
import 'sleep_timer_screen.dart';
import 'playlist_detail_screen.dart';
import 'all_genres_screen.dart';
import 'all_moods_screen.dart';
import 'all_artists_screen.dart';
import 'mood_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'liked_songs_screen.dart';
import '../widgets/share_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimations = List.generate(
      6,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.1,
            0.6 + (index * 0.1),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _slideAnimations = List.generate(
      6,
      (index) =>
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(
                index * 0.1,
                0.6 + (index * 0.1),
                curve: Curves.easeOutCubic,
              ),
            ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 140),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimations[0],
                    child: SlideTransition(
                      position: _slideAnimations[0],
                      child: const _HeaderSection(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimations[1],
                    child: SlideTransition(
                      position: _slideAnimations[1],
                      child: const _QuickActionsSection(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimations[1],
                    child: SlideTransition(
                      position: _slideAnimations[1],
                      child: const _TimeBasedGreeting(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _fadeAnimations[1],
                    child: SlideTransition(
                      position: _slideAnimations[1],
                      child: const _FeaturedPlaylistsSection(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimations[2],
                    child: SlideTransition(
                      position: _slideAnimations[2],
                      child: const _MoodSection(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimations[2],
                    child: SlideTransition(
                      position: _slideAnimations[2],
                      child: const _TopArtistsSection(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimations[2],
                    child: SlideTransition(
                      position: _slideAnimations[2],
                      child: const SocialFeedWidget(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimations[2],
                    child: SlideTransition(
                      position: _slideAnimations[2],
                      child: const _HeroCard(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimations[3],
                    child: SlideTransition(
                      position: _slideAnimations[3],
                      child: const _GenresSection(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimations[4],
                    child: SlideTransition(
                      position: _slideAnimations[4],
                      child: const _DailyMixSection(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Các Widget con (Components) ---

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 18) return '🌤️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting with emoji
          Row(
            children: [
              Text(_getGreetingEmoji(), style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scenery Sync',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    DateTime.now().toString().split(' ')[0],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Icons row
          Row(
            children: [
              // Notifications
              GestureDetector(
                onTap: () {
                  _showNotificationsSheet(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textMain,
                          size: 22,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE74C3C),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Profile
              GestureDetector(
                onTap: () {
                  _showProfileSheet(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    image: const DecorationImage(
                      image: NetworkImage('https://i.pravatar.cc/150?img=32'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _NotificationsSheet(),
    );
  }

  static void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _ProfileSheet(),
    );
  }
}

// Notifications Bottom Sheet
class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<Map<String, dynamic>> notifications = [];

  void _markAllRead() {
    setState(() {
      for (var notif in notifications) {
        notif['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✓ All notifications marked as read'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showNotificationDetail(Map<String, dynamic> notif) {
    setState(() {
      notif['isRead'] = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (notif['color'] as Color).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notif['icon'] as IconData,
                color: notif['color'] as Color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notif['title'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notif['message'] as String,
              style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              notif['time'] as String,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
                TextButton(
                  onPressed: _markAllRead,
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Notifications list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isRead = notif['isRead'] as bool;

                return ListTile(
                  onTap: () => _showNotificationDetail(notif),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  tileColor: isRead
                      ? Colors.transparent
                      : AppColors.primary.withOpacity(0.05),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (notif['color'] as Color).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      notif['icon'] as IconData,
                      color: notif['color'] as Color,
                      size: 24,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif['title'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notif['message'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif['time'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Profile Bottom Sheet
class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Profile header
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              image: const DecorationImage(
                image: NetworkImage('https://i.pravatar.cc/300?img=32'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Alex Morgan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'alex.morgan@email.com',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('128', 'Playlists'),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStat('2.5K', 'Followers'),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStat('890', 'Following'),
            ],
          ),
          const SizedBox(height: 24),
          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildMenuItem(
                  Icons.person_outline_rounded,
                  'Edit Profile',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(Icons.settings_outlined, 'Settings', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                }),
                _buildMenuItem(
                  Icons.favorite_outline_rounded,
                  'Liked Songs',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LikedSongsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(Icons.history_rounded, 'Listening History', () {
                  Navigator.pop(context);
                  // Navigate to history
                }),
                const Divider(height: 32),
                _buildMenuItem(Icons.logout_rounded, 'Logout', () {
                  Navigator.pop(context);
                  // Handle logout
                }, isDestructive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0xFFE74C3C).withOpacity(0.1)
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? const Color(0xFFE74C3C) : AppColors.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDestructive ? const Color(0xFFE74C3C) : AppColors.textMain,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }
}

// Time-based greeting widget with dynamic recommendations
class _TimeBasedGreeting extends StatelessWidget {
  const _TimeBasedGreeting();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _getRecommendation() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Start your day with energy';
    if (hour < 18) return 'Perfect music for your afternoon';
    return 'Unwind with relaxing sounds';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getRecommendation(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// Featured Playlists Section - Beautiful cards for new users
class _FeaturedPlaylistsSection extends StatelessWidget {
  const _FeaturedPlaylistsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Made for you',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _FeaturedPlaylistCard(index: index);
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedPlaylistCard extends StatefulWidget {
  final int index;

  const _FeaturedPlaylistCard({required this.index});

  @override
  State<_FeaturedPlaylistCard> createState() => _FeaturedPlaylistCardState();
}

class _FeaturedPlaylistCardState extends State<_FeaturedPlaylistCard> {
  bool _isPressed = false;

  final List<Map<String, dynamic>> _playlists = [
    {
      'title': 'Discover Weekly',
      'subtitle': 'Your weekly mixtape',
      'icon': Icons.explore_rounded,
      'gradient': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      'image': 'https://picsum.photos/seed/discover/400/400',
    },
    {
      'title': 'Release Radar',
      'subtitle': 'New releases for you',
      'icon': Icons.fiber_new_rounded,
      'gradient': [const Color(0xFFFA709A), const Color(0xFFFF9A6C)],
      'image': 'https://picsum.photos/seed/radar/400/400',
    },
    {
      'title': 'Daily Mix',
      'subtitle': 'Your favorite songs',
      'icon': Icons.playlist_play_rounded,
      'gradient': [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      'image': 'https://picsum.photos/seed/daily/400/400',
    },
    {
      'title': 'Liked Songs',
      'subtitle': '50 songs',
      'icon': Icons.favorite_rounded,
      'gradient': [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      'image': 'https://picsum.photos/seed/liked/400/400',
    },
    {
      'title': 'On Repeat',
      'subtitle': 'Songs you love',
      'icon': Icons.repeat_rounded,
      'gradient': [const Color(0xFFFEAC5E), const Color(0xFFC779D0)],
      'image': 'https://picsum.photos/seed/repeat/400/400',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final playlist = _playlists[widget.index];

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistDetailScreen(
              playlistName: playlist['title'],
              playlistCover: playlist['image'],
              songCount: 50,
            ),
          ),
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (widget.index * 100)),
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
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: playlist['gradient'],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: playlist['gradient'][0].withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.15,
                      child: Image.network(
                        playlist['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container();
                        },
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -40,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            playlist['icon'],
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const Spacer(),
                        // Title
                        Text(
                          playlist['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Subtitle
                        Text(
                          playlist['subtitle'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Play button overlay on hover
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: playlist['gradient'][0],
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatefulWidget {
  const _HeroCard();

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const NowPlayingScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: child,
                      ),
                    );
                  },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: Container(
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8A598),
                  Color(0xFFFFD6A5),
                  Color(0xFFB8CBE3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(0, 20),
                  blurRadius: 40,
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Nội dung Text & Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: const Text(
                                  'FEATURED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Lo-Fi\nBeats',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Relax & Focus',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenresSection extends StatelessWidget {
  const _GenresSection();

  @override
  Widget build(BuildContext context) {
    final genres = [
      {
        'name': 'Pop',
        'color': const Color(0xFFFF6B9D),
        'icon': Icons.music_note,
      },
      {
        'name': 'Chill',
        'color': const Color(0xFF92A3FD),
        'icon': Icons.self_improvement,
      },
      {
        'name': 'EDM',
        'color': const Color(0xFFC58BF2),
        'icon': Icons.equalizer,
      },
      {'name': 'Jazz', 'color': const Color(0xFFFFA84A), 'icon': Icons.piano},
      {'name': 'Indie', 'color': const Color(0xFF7FD8BE), 'icon': Icons.park},
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLanguage().translate('browse_genres'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllGenresScreen(),
                    ),
                  );
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: genres.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = genres[index];
              return _GenreItem(
                name: item['name'] as String,
                color: item['color'] as Color,
                icon: item['icon'] as IconData,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GenreItem extends StatefulWidget {
  final String name;
  final Color color;
  final IconData icon;
  final int index;

  const _GenreItem({
    required this.name,
    required this.color,
    required this.icon,
    required this.index,
  });

  @override
  State<_GenreItem> createState() => _GenreItemState();
}

class _GenreItemState extends State<_GenreItem>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GenreDetailScreen(
              genreName: widget.name,
              genreColor: widget.color,
              genreIcon: widget.icon,
            ),
          ),
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300 + (widget.index * 80)),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Column(
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.4),
                  shape: BoxShape.circle,
                  boxShadow: _isPressed
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Icon(widget.icon, color: AppColors.textMain, size: 26),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyMixSection extends StatelessWidget {
  const _DailyMixSection();

  @override
  Widget build(BuildContext context) {
    final mixes = [
      {
        'title': 'Morning Coffee',
        'subtitle': 'Soft acoustics & jazz',
        'image': 'https://picsum.photos/id/10/300/300',
      },
      {
        'title': 'Neon Drive',
        'subtitle': 'Synthwave mix',
        'image': 'https://picsum.photos/id/15/300/300',
      },
      {
        'title': 'Study Session',
        'subtitle': 'Deep focus beats',
        'image': 'https://picsum.photos/id/20/300/300',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            AppLanguage().translate('daily_mix'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: mixes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final item = mixes[index];
              return _DailyMixCard(
                title: item['title']!,
                subtitle: item['subtitle']!,
                imageUrl: item['image']!,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DailyMixCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final int index;

  const _DailyMixCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.index,
  });

  @override
  State<_DailyMixCard> createState() => _DailyMixCardState();
}

class _DailyMixCardState extends State<_DailyMixCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
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
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailScreen(
                playlistName: widget.title,
                playlistCover: widget.imageUrl,
                songCount: 50,
              ),
            ),
          );
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Hero(
                    tag: 'daily_mix_${widget.index}',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(widget.imageUrl),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              _isPressed ? 0.05 : 0.1,
                            ),
                            blurRadius: _isPressed ? 5 : 10,
                            offset: Offset(0, _isPressed ? 2 : 5),
                          ),
                        ],
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.subtitle,
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
        ),
      ),
    );
  }
}

// Quick Actions Section
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildQuickAction(
                context,
                Icons.history_rounded,
                AppLanguage().translate('recently_played'),
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecentlyPlayedScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildQuickAction(
                context,
                Icons.download_rounded,
                'Downloads',
                Colors.green,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DownloadsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildQuickAction(
                context,
                Icons.bedtime_rounded,
                'Sleep Timer',
                Colors.indigo,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SleepTimerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildQuickAction(
                context,
                Icons.people_rounded,
                'Collaborative',
                Colors.orange,
                () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) => const CollaborativePlaylistWidget(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Mood & Activities Section
class _MoodSection extends StatelessWidget {
  const _MoodSection();

  @override
  Widget build(BuildContext context) {
    final moods = [
      {
        'title': '💪 Workout',
        'color': const Color(0xFFE74C3C),
        'gradient': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
        'icon': Icons.fitness_center_rounded,
      },
      {
        'title': '😌 Chill',
        'color': const Color(0xFF3498DB),
        'gradient': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
        'icon': Icons.self_improvement_rounded,
      },
      {
        'title': '🎉 Party',
        'color': const Color(0xFF9B59B6),
        'gradient': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
        'icon': Icons.celebration_rounded,
      },
      {
        'title': '🧘 Focus',
        'color': const Color(0xFF1ABC9C),
        'gradient': [const Color(0xFF1ABC9C), const Color(0xFF16A085)],
        'icon': Icons.psychology_rounded,
      },
      {
        'title': '😴 Sleep',
        'color': const Color(0xFF34495E),
        'gradient': [const Color(0xFF34495E), const Color(0xFF2C3E50)],
        'icon': Icons.bedtime_rounded,
      },
      {
        'title': '💖 Romantic',
        'color': const Color(0xFFE91E63),
        'gradient': [const Color(0xFFE91E63), const Color(0xFFC2185B)],
        'icon': Icons.favorite_rounded,
      },
      {
        'title': '🎸 Indie',
        'color': const Color(0xFFFF9800),
        'gradient': [const Color(0xFFFF9800), const Color(0xFFF57C00)],
        'icon': Icons.music_note_rounded,
      },
      {
        'title': '⚡ Energetic',
        'color': const Color(0xFFFFEB3B),
        'gradient': [const Color(0xFFFFEB3B), const Color(0xFFFDD835)],
        'icon': Icons.bolt_rounded,
      },
      {
        'title': '😢 Sad',
        'color': const Color(0xFF607D8B),
        'gradient': [const Color(0xFF607D8B), const Color(0xFF546E7A)],
        'icon': Icons.sentiment_dissatisfied_rounded,
      },
      {
        'title': '😊 Happy',
        'color': const Color(0xFF4CAF50),
        'gradient': [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
        'icon': Icons.sentiment_very_satisfied_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Browse by mood',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllMoodsScreen(),
                    ),
                  );
                },
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 165,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: moods.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final mood = moods[index];
              return _MoodCard(
                title: mood['title'] as String,
                gradient: mood['gradient'] as List<Color>,
                icon: mood['icon'] as IconData,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MoodCard extends StatefulWidget {
  final String title;
  final List<Color> gradient;
  final IconData icon;
  final int index;

  const _MoodCard({
    required this.title,
    required this.gradient,
    required this.icon,
    required this.index,
  });

  @override
  State<_MoodCard> createState() => _MoodCardState();
}

class _MoodCardState extends State<_MoodCard> {
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
            builder: (context) => MoodDetailScreen(
              moodTitle: widget.title,
              gradient: widget.gradient,
              icon: widget.icon,
            ),
          ),
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (widget.index * 80)),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value * (_isPressed ? 0.95 : 1.0),
            child: child,
          );
        },
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradient,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.gradient[0].withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon at top
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 26),
                    ),
                    // Title at bottom
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
      ),
    );
  }
}

// Top Artists Section
class _TopArtistsSection extends StatelessWidget {
  const _TopArtistsSection();

  @override
  Widget build(BuildContext context) {
    final artists = <Map<String, String>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your top artists',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllArtistsScreen(),
                    ),
                  );
                },
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: artists.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final artist = artists[index];
              return _ArtistCard(
                name: artist['name']!,
                imageUrl: artist['image']!,
                followers: artist['followers']!,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ArtistCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String followers;
  final int index;

  const _ArtistCard({
    required this.name,
    required this.imageUrl,
    required this.followers,
    required this.index,
  });

  @override
  State<_ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<_ArtistCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        // Navigate to artist page
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (widget.index * 100)),
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
          child: SizedBox(
            width: 150,
            child: Column(
              children: [
                // Artist Image
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primary.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Artist Name
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
