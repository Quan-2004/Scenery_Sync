import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/draggable_chat_bot.dart';
import '../widgets/dynamic_island_player.dart';
import '../services/app_language.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'camera_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final AppLanguage _appLanguage = AppLanguage();

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    ProfileScreen(),
    CameraScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _appLanguage.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _appLanguage.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          
          // Dynamic Island Player
          const DynamicIslandPlayer(),
          
          // Draggable Chat Bot
          const DraggableChatBot(),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(24),
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 20),
                    blurRadius: 40,
                    spreadRadius: -12,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home_rounded, 0),
                  _buildNavItem(Icons.search_rounded, 1),
                  _buildNavItem(Icons.camera, 4),
                  _buildNavItem(Icons.library_music_rounded, 2),
                  _buildNavItem(Icons.person_rounded, 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        width: 48,
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              )
            : null,
        child: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textMuted,
          size: 26,
        ),
      ),
    );
  }
}
