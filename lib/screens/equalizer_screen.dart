import 'package:flutter/material.dart';
import '../theme/colors.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  String _selectedPreset = 'Flat';
  bool _isEnabled = true;
  
  final Map<String, List<double>> _presets = {
    'Flat': [0, 0, 0, 0, 0, 0, 0, 0],
    'Pop': [2, 4, 6, 4, 2, -1, -2, -2],
    'Rock': [5, 3, -2, -3, -1, 2, 5, 6],
    'Jazz': [4, 3, 1, 2, -1, -1, 0, 2],
    'Classical': [5, 4, 3, 0, -1, -1, 2, 4],
    'Hip Hop': [6, 5, 1, 0, -1, -1, 2, 3],
    'Electronic': [5, 4, 2, 0, -2, 2, 4, 5],
    'Bass Boost': [8, 6, 4, 2, 0, 0, 0, 0],
  };

  List<double> _currentValues = [0, 0, 0, 0, 0, 0, 0, 0];
  final List<String> _frequencies = ['60', '150', '400', '1K', '2.4K', '6K', '15K', '20K'];

  double _bassBoost = 0;
  double _virtualizer = 0;

  @override
  void initState() {
    super.initState();
    _currentValues = List.from(_presets['Flat']!);
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
                          'Equalizer',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Customize your sound',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isEnabled = value;
                      });
                    },
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
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 70),
                child: Column(
                  children: [
                    // Presets
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRESETS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _presets.length,
                              itemBuilder: (context, index) {
                                final preset = _presets.keys.elementAt(index);
                                return _buildPresetChip(preset);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Equalizer Sliders
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Frequency Bands',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 280,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(8, (index) {
                                return _buildEQSlider(index);
                              }),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(8, (index) {
                              return SizedBox(
                                width: 32,
                                child: Text(
                                  _frequencies[index],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Audio Effects
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AUDIO EFFECTS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildEffectCard(
                            'Bass Boost',
                            Icons.graphic_eq_rounded,
                            _bassBoost,
                            (value) => setState(() => _bassBoost = value),
                          ),
                          const SizedBox(height: 12),
                          _buildEffectCard(
                            'Virtualizer',
                            Icons.surround_sound_rounded,
                            _virtualizer,
                            (value) => setState(() => _virtualizer = value),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Reset Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _resetToDefault,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Icon(Icons.restore_rounded, color: AppColors.primary),
                          label: Text(
                            'Reset to Default',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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

  Widget _buildPresetChip(String preset) {
    final isSelected = _selectedPreset == preset;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPreset = preset;
          _currentValues = List.from(_presets[preset]!);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          preset,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEQSlider(int index) {
    return SizedBox(
      width: 32,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            _currentValues[index] >= 0
                ? '+${_currentValues[index].toInt()}'
                : '${_currentValues[index].toInt()}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: AppColors.primary,
                ),
                child: Slider(
                  value: _currentValues[index],
                  min: -10,
                  max: 10,
                  onChanged: _isEnabled
                      ? (value) {
                          setState(() {
                            _currentValues[index] = value;
                            _selectedPreset = 'Custom';
                          });
                        }
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectCard(
    String title,
    IconData icon,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: AppColors.primary,
            ),
            child: Slider(
              value: value,
              onChanged: _isEnabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }

  void _resetToDefault() {
    setState(() {
      _selectedPreset = 'Flat';
      _currentValues = List.from(_presets['Flat']!);
      _bassBoost = 0;
      _virtualizer = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Equalizer reset to default'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
