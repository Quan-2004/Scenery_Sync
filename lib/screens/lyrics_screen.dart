import 'package:flutter/material.dart';
import '../theme/colors.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  int _currentLineIndex = 0;

  final List<Map<String, dynamic>> _lyrics = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _startLyricSync();
  }

  void _startLyricSync() {
    // Simulate song progress
    Future.delayed(const Duration(seconds: 1), () {
      _updateCurrentLine();
    });
  }

  void _updateCurrentLine() {
    if (!mounted) return;

    setState(() {
      _currentLineIndex = (_currentLineIndex + 1) % _lyrics.length;
    });

    // Auto scroll to current line
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _currentLineIndex * 80.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    // Continue updating
    Future.delayed(const Duration(seconds: 3), _updateCurrentLine);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.8),
              AppColors.secondary.withValues(alpha: 0.9),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Lyrics',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ho Hey - The Lumineers',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleFullscreen,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fullscreen_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Album Art (Small)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Lyrics List
              Expanded(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.1, 0.9, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 40,
                    ),
                    itemCount: _lyrics.isEmpty ? 1 : _lyrics.length,
                    itemBuilder: (context, index) {
                      if (_lyrics.isEmpty) {
                        return const Center(
                          child: Text(
                            'No lyrics available',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      final isActive = index == _currentLineIndex;
                      final isPast = index < _currentLineIndex;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentLineIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontSize: isActive ? 28 : 20,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isActive
                                  ? Colors.white
                                  : isPast
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.3),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                            child: Text(_lyrics[index]['text'] ?? ''),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Controls
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.share_rounded,
                      onTap: _shareLyrics,
                    ),
                    _buildControlButton(
                      icon: Icons.text_fields_rounded,
                      onTap: _changeFontSize,
                    ),
                    _buildControlButton(
                      icon: Icons.translate_rounded,
                      onTap: _translateLyrics,
                    ),
                    _buildControlButton(
                      icon: Icons.download_rounded,
                      onTap: _downloadLyrics,
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

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  void _toggleFullscreen() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fullscreen mode'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareLyrics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share lyrics'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _changeFontSize() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Font size adjusted'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _translateLyrics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Translation available'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _downloadLyrics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lyrics downloaded'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
