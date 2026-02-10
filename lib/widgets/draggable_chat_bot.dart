import 'package:flutter/material.dart';
import '../screens/chat_bot_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DraggableChatBot extends StatefulWidget {
  const DraggableChatBot({super.key});

  @override
  State<DraggableChatBot> createState() => _DraggableChatBotState();
}

class _DraggableChatBotState extends State<DraggableChatBot> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Default position (bottom right)
  static const double _defaultRight = 20.0;
  static const double _defaultBottom = 128.0;
  
  double _right = _defaultRight;
  double _bottom = _defaultBottom;

  @override
  void initState() {
    super.initState();
    
    // Animation nhấp nháy nhẹ
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _loadPosition();
  }
  
  Future<void> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    // Always reset to default position on app start (simulating login)
    setState(() {
      _right = _defaultRight;
      _bottom = _defaultBottom;
    });
    // Clear any saved position
    await prefs.remove('chatbot_right');
    await prefs.remove('chatbot_bottom');
  }
  
  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('chatbot_right', _right);
    await prefs.setDouble('chatbot_bottom', _bottom);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Positioned(
      right: _right,
      bottom: _bottom + bottomPadding,
      child: Draggable(
        feedback: _buildChatBotButton(),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildChatBotButton(),
        ),
        onDragEnd: (details) {
          setState(() {
            // Calculate position from drag
            final left = details.offset.dx;
            final top = details.offset.dy;
            
            // Determine which side (left or right) based on horizontal position
            final centerX = left + 32; // Half of button width (64/2)
            final isLeftSide = centerX < screenSize.width / 2;
            
            // Calculate vertical position (can move up/down freely)
            _bottom = screenSize.height - top - 64 - bottomPadding;
            
            // Constrain vertical movement
            _bottom = _bottom.clamp(80.0, screenSize.height - 200);
            
            // Lock to either left or right edge
            if (isLeftSide) {
              // Lock to left edge
              _right = screenSize.width - 80; // 16 padding + 64 button width
            } else {
              // Lock to right edge
              _right = 16.0;
            }
          });
          _savePosition();
        },
        child: _buildChatBotButton(),
      ),
    );
  }

  Widget _buildChatBotButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatBotScreen()),
              );
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF9B54),
                    Color(0xFFF47B3C),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF47B3C).withOpacity(0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Shine effect overlay
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  // Fox Emoji
                  const Center(
                    child: Text(
                      '🦊',
                      style: TextStyle(
                        fontSize: 36,
                      ),
                    ),
                  ),
                  
                  // Online badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
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
