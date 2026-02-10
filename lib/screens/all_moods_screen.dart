import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'playlist_detail_screen.dart';

class AllMoodsScreen extends StatefulWidget {
  const AllMoodsScreen({super.key});

  @override
  State<AllMoodsScreen> createState() => _AllMoodsScreenState();
}

class _AllMoodsScreenState extends State<AllMoodsScreen> {
  final List<Map<String, dynamic>> allMoods = [
    {
      'title': '💪 Workout',
      'subtitle': 'Get pumped and energized',
      'gradient': [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
    },
    {
      'title': '😌 Chill',
      'subtitle': 'Relax and unwind',
      'gradient': [const Color(0xFF3498DB), const Color(0xFF2980B9)],
    },
    {
      'title': '🎉 Party',
      'subtitle': 'Dance and celebrate',
      'gradient': [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
    },
    {
      'title': '🧘 Focus',
      'subtitle': 'Deep concentration',
      'gradient': [const Color(0xFF1ABC9C), const Color(0xFF16A085)],
    },
    {
      'title': '😴 Sleep',
      'subtitle': 'Peaceful dreams',
      'gradient': [const Color(0xFF34495E), const Color(0xFF2C3E50)],
    },
    {
      'title': '☕ Morning',
      'subtitle': 'Start your day right',
      'gradient': [const Color(0xFFF39C12), const Color(0xFFE67E22)],
    },
    {
      'title': '💔 Sad',
      'subtitle': 'Let it all out',
      'gradient': [const Color(0xFF5D6D7E), const Color(0xFF34495E)],
    },
    {
      'title': '😊 Happy',
      'subtitle': 'Feel good vibes',
      'gradient': [const Color(0xFFF1C40F), const Color(0xFFF39C12)],
    },
    {
      'title': '🚗 Road Trip',
      'subtitle': 'Highway anthems',
      'gradient': [const Color(0xFF16A085), const Color(0xFF1ABC9C)],
    },
    {
      'title': '💖 Romance',
      'subtitle': 'Love songs',
      'gradient': [const Color(0xFFE91E63), const Color(0xFFC2185B)],
    },
    {
      'title': '🎸 Rock',
      'subtitle': 'Hard hitting beats',
      'gradient': [const Color(0xFF212121), const Color(0xFF424242)],
    },
    {
      'title': '🌊 Beach',
      'subtitle': 'Summer vibes',
      'gradient': [const Color(0xFF00BCD4), const Color(0xFF0097A7)],
    },
  ];

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
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMain),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Browse by Mood',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
            ),
          ),
          // Moods Grid
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _MoodGridCard(
                    mood: allMoods[index],
                    index: index,
                  );
                },
                childCount: allMoods.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodGridCard extends StatefulWidget {
  final Map<String, dynamic> mood;
  final int index;

  const _MoodGridCard({
    required this.mood,
    required this.index,
  });

  @override
  State<_MoodGridCard> createState() => _MoodGridCardState();
}

class _MoodGridCardState extends State<_MoodGridCard> {
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
              playlistName: widget.mood['title'],
              playlistCover: 'https://picsum.photos/seed/${widget.index}/400/400',
              songCount: 50,
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
            child: Transform.scale(
              scale: value * (_isPressed ? 0.95 : 1.0),
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.mood['gradient'],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.mood['gradient'][0].withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.mood['title'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.mood['subtitle'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                      maxLines: 2,
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
