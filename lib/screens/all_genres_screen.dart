import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'genre_detail_screen.dart';

class AllGenresScreen extends StatefulWidget {
  const AllGenresScreen({super.key});

  @override
  State<AllGenresScreen> createState() => _AllGenresScreenState();
}

class _AllGenresScreenState extends State<AllGenresScreen> {
  final List<Map<String, dynamic>> _allGenres = [
    {'name': 'Pop', 'color': const Color(0xFFFF6B9D), 'icon': Icons.music_note},
    {'name': 'Rock', 'color': const Color(0xFF8B5CF6), 'icon': Icons.auto_awesome},
    {'name': 'Hip Hop', 'color': const Color(0xFF3B82F6), 'icon': Icons.headphones},
    {'name': 'Jazz', 'color': const Color(0xFFFFA500), 'icon': Icons.piano},
    {'name': 'Classical', 'color': const Color(0xFF10B981), 'icon': Icons.album},
    {'name': 'Electronic', 'color': const Color(0xFFEC4899), 'icon': Icons.graphic_eq},
    {'name': 'R&B', 'color': const Color(0xFFF59E0B), 'icon': Icons.favorite},
    {'name': 'Country', 'color': const Color(0xFF6366F1), 'icon': Icons.explore},
    {'name': 'Latin', 'color': const Color(0xFFEF4444), 'icon': Icons.local_fire_department},
    {'name': 'Indie', 'color': const Color(0xFF06B6D4), 'icon': Icons.palette},
    {'name': 'Metal', 'color': const Color(0xFF64748B), 'icon': Icons.bolt},
    {'name': 'Blues', 'color': const Color(0xFF1E40AF), 'icon': Icons.nights_stay},
    {'name': 'Reggae', 'color': const Color(0xFF22C55E), 'icon': Icons.wb_sunny},
    {'name': 'Soul', 'color': const Color(0xFFA855F7), 'icon': Icons.sentiment_satisfied},
    {'name': 'Funk', 'color': const Color(0xFFF97316), 'icon': Icons.celebration},
    {'name': 'Disco', 'color': const Color(0xFFDB2777), 'icon': Icons.nightlife},
    {'name': 'K-Pop', 'color': const Color(0xFFFF6B9D), 'icon': Icons.stars},
    {'name': 'Ambient', 'color': const Color(0xFF14B8A6), 'icon': Icons.cloud},
    {'name': 'Techno', 'color': const Color(0xFF6366F1), 'icon': Icons.flash_on},
    {'name': 'House', 'color': const Color(0xFF8B5CF6), 'icon': Icons.home},
  ];

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

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'All Genres',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),

                // Genres Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _allGenres.length,
                    itemBuilder: (context, index) {
                      final genre = _allGenres[index];
                      return _GenreCard(
                        name: genre['name'],
                        color: genre['color'],
                        icon: genre['icon'],
                        index: index,
                      );
                    },
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

class _GenreCard extends StatefulWidget {
  final String name;
  final Color color;
  final IconData icon;
  final int index;

  const _GenreCard({
    required this.name,
    required this.color,
    required this.icon,
    required this.index,
  });

  @override
  State<_GenreCard> createState() => _GenreCardState();
}

class _GenreCardState extends State<_GenreCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
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
              builder: (context) => GenreDetailScreen(
                genreName: widget.name,
                genreColor: widget.color,
                genreIcon: widget.icon,
              ),
            ),
          );
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color,
                  widget.color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    widget.icon,
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
