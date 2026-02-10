import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/colors.dart';

class SleepTimerScreen extends StatefulWidget {
  const SleepTimerScreen({super.key});

  @override
  State<SleepTimerScreen> createState() => _SleepTimerScreenState();
}

class _SleepTimerScreenState extends State<SleepTimerScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isActive = false;
  bool _fadeOutEnabled = true;
  late AnimationController _pulseController;

  final List<Map<String, int>> _presets = [
    {'label': 5, 'seconds': 300},
    {'label': 15, 'seconds': 900},
    {'label': 30, 'seconds': 1800},
    {'label': 45, 'seconds': 2700},
    {'label': 60, 'seconds': 3600},
    {'label': 90, 'seconds': 5400},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer(int seconds) {
    setState(() {
      _remainingSeconds = seconds;
      _isActive = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopTimer();
          _onTimerComplete();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _remainingSeconds = 0;
    });
  }

  void _onTimerComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Music stopped - Sleep well! 😴'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sleep Timer',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Auto-stop music after time',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 70),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Timer Display
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isActive
                              ? [AppColors.primary, AppColors.secondary]
                              : [
                                  Colors.grey.shade200,
                                  Colors.grey.shade300,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _isActive
                                ? AppColors.primary.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Moon Icon
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isActive ? 1.0 + (_pulseController.value * 0.1) : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(_isActive ? 0.2 : 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.nightlight_round,
                                    size: 64,
                                    color: _isActive ? Colors.white : Colors.grey.shade400,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Time Display
                          Text(
                            _isActive ? _formatTime(_remainingSeconds) : '00:00',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: _isActive ? Colors.white : Colors.grey.shade400,
                              letterSpacing: 2,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            _isActive ? 'Music will stop in' : 'Set a timer',
                            style: TextStyle(
                              fontSize: 16,
                              color: _isActive ? Colors.white70 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Presets
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QUICK TIMERS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: _presets.length,
                            itemBuilder: (context, index) {
                              final preset = _presets[index];
                              return _buildPresetButton(
                                '${preset['label']} min',
                                preset['seconds']!,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Options
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OPTIONS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildOptionCard(
                            icon: Icons.volume_down_rounded,
                            title: 'Fade Out',
                            subtitle: 'Gradually decrease volume',
                            value: _fadeOutEnabled,
                            onChanged: (value) {
                              setState(() {
                                _fadeOutEnabled = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildCustomTimerButton(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Control Button
                    if (_isActive)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _stopTimer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade400,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: Colors.red.withOpacity(0.3),
                                ),
                                icon: const Icon(Icons.stop_rounded),
                                label: const Text(
                                  'Cancel Timer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _remainingSeconds += 300;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: Icon(Icons.add_rounded, color: AppColors.primary),
                                label: Text(
                                  'Add 5 Minutes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, int seconds) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _startTimer(seconds),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.secondary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return Colors.white;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTimerButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showCustomTimerDialog,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.secondary.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.timer_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Custom Timer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomTimerDialog() {
    int hours = 0;
    int minutes = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Custom Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimePicker(
                    'Hours',
                    hours,
                    (val) => setDialogState(() => hours = val),
                    23,
                  ),
                  const SizedBox(width: 20),
                  _buildTimePicker(
                    'Minutes',
                    minutes,
                    (val) => setDialogState(() => minutes = val),
                    59,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final totalSeconds = (hours * 3600) + (minutes * 60);
                if (totalSeconds > 0) {
                  _startTimer(totalSeconds);
                }
                Navigator.pop(context);
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, int value, ValueChanged<int> onChanged, int max) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) => onChanged(index),
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                return Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                );
              },
              childCount: max + 1,
            ),
          ),
        ),
      ],
    );
  }
}
