import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/colors.dart';

class AudioVisualizerScreen extends StatefulWidget {
  const AudioVisualizerScreen({super.key});

  @override
  State<AudioVisualizerScreen> createState() => _AudioVisualizerScreenState();
}

class _AudioVisualizerScreenState extends State<AudioVisualizerScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  
  int _selectedStyle = 0;
  bool _isPlaying = true;
  
  final List<String> _visualizerStyles = [
    'Bars',
    'Wave',
    'Circle',
    'Particles',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              AppColors.primary.withOpacity(0.3),
              AppColors.secondary.withOpacity(0.3),
              Colors.black,
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
                          color: Colors.white.withOpacity(0.1),
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
                            'Now Playing',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Blinding Lights',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Visualizer
              Expanded(
                child: Center(
                  child: _buildVisualizer(),
                ),
              ),

              // Song Info
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text(
                      'Unknown Artist',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Unknown Track',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Progress Bar
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withOpacity(0.2),
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: 0.4,
                            onChanged: (value) {},
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '1:24',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                '3:20',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(Icons.shuffle_rounded, false),
                        _buildControlButton(Icons.skip_previous_rounded, true),
                        _buildPlayButton(),
                        _buildControlButton(Icons.skip_next_rounded, true),
                        _buildControlButton(Icons.repeat_rounded, false),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Visualizer Style Selector
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _visualizerStyles.length,
                        itemBuilder: (context, index) {
                          return _buildStyleChip(index);
                        },
                      ),
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

  Widget _buildVisualizer() {
    switch (_selectedStyle) {
      case 0:
        return _buildBarsVisualizer();
      case 1:
        return _buildWaveVisualizer();
      case 2:
        return _buildCircleVisualizer();
      case 3:
        return _buildParticlesVisualizer();
      default:
        return _buildBarsVisualizer();
    }
  }

  Widget _buildBarsVisualizer() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(40, (index) {
            final random = math.Random(index);
            final height = _isPlaying
                ? 50 + random.nextDouble() * 200
                : 20.0;
            
            return Container(
              width: 4,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildWaveVisualizer() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(300, 200),
          painter: WaveVisualizerPainter(
            animation: _controller.value,
            isPlaying: _isPlaying,
          ),
        );
      },
    );
  }

  Widget _buildCircleVisualizer() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withOpacity(0.6),
                AppColors.secondary.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(3, (index) {
              final scale = _isPlaying
                  ? 1.0 + (index * 0.2) + (_pulseController.value * 0.3)
                  : 1.0;
              
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 200 - (index * 40),
                  height: 200 - (index * 40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3 - (index * 0.1)),
                      width: 2,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildParticlesVisualizer() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            children: List.generate(20, (index) {
              final random = math.Random(index);
              final angle = (index / 20) * 2 * math.pi;
              final radius = _isPlaying
                  ? 80 + random.nextDouble() * 60
                  : 50.0;
              
              final x = 150 + math.cos(angle + _controller.value * 2 * math.pi) * radius;
              final y = 150 + math.sin(angle + _controller.value * 2 * math.pi) * radius;
              
              return Positioned(
                left: x,
                top: y,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? AppColors.primary : AppColors.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (index % 2 == 0 ? AppColors.primary : AppColors.secondary)
                            .withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildControlButton(IconData icon, bool large) {
    return Container(
      padding: EdgeInsets.all(large ? 12 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: large ? 32 : 24,
      ),
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPlaying = !_isPlaying;
        });
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildStyleChip(int index) {
    final isSelected = _selectedStyle == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStyle = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          _visualizerStyles[index],
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class WaveVisualizerPainter extends CustomPainter {
  final double animation;
  final bool isPlaying;

  WaveVisualizerPainter({required this.animation, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerY = size.height / 2;

    path.moveTo(0, centerY);

    for (double i = 0; i < size.width; i++) {
      final amplitude = isPlaying ? 40.0 : 10.0;
      final y = centerY +
          math.sin((i / size.width * 4 * math.pi) + (animation * 2 * math.pi)) *
              amplitude;
      path.lineTo(i, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveVisualizerPainter oldDelegate) => true;
}
