import 'package:flutter/material.dart';
import '../services/deezer_service.dart';
import '../models/music_models.dart';
import '../theme/colors.dart';

// Demo screen để test Deezer API (không cần credentials)
class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final DeezerService _deezerService = DeezerService();
  List<Track> _tracks = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChartTracks();
  }

  Future<void> _loadChartTracks() async {
    setState(() => _isLoading = true);
    try {
      final tracks = await _deezerService.getChartTracks(limit: 20);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _searchTracks() async {
    if (_searchQuery.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final tracks = await _deezerService.searchTracks(_searchQuery, limit: 20);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('API Test - Deezer'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: TextField(
              onChanged: (value) => _searchQuery = value,
              onSubmitted: (_) => _searchTracks(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for songs, artists...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    _loadChartTracks();
                  },
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _tracks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_off_rounded,
                              size: 80,
                              color: AppColors.textMuted.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No tracks found',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tracks.length,
                        itemBuilder: (context, index) {
                          final track = _tracks[index];
                          return _TrackCard(track: track);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadChartTracks,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final Track track;

  const _TrackCard({required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: track.imageUrl.isNotEmpty
              ? Image.network(
                  track.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: AppColors.primary.withOpacity(0.2),
                      child: const Icon(
                        Icons.music_note,
                        color: AppColors.primary,
                      ),
                    );
                  },
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: AppColors.primary.withOpacity(0.2),
                  child: const Icon(
                    Icons.music_note,
                    color: AppColors.primary,
                  ),
                ),
        ),
        title: Text(
          track.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              track.artistName,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  track.duration,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (track.previewUrl != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_filled, size: 32),
          color: AppColors.primary,
          onPressed: () {
            if (track.previewUrl != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Preview URL: ${track.previewUrl}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No preview available'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
