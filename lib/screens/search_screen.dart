import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/colors.dart';
import '../services/deezer_service.dart';
import '../services/audio_player_service.dart';
import '../models/music_models.dart';
import 'now_playing_screen.dart';
import 'artist_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final DeezerService _deezerService = DeezerService();
  Timer? _debounce;

  List<Track> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _isSearchFocused = false;
  String _selectedFilter = 'All';

  // Grouped data for different filters
  Map<String, List<Track>> _artistsMap = {};
  Map<String, List<Track>> _albumsMap = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimations = List.generate(
      4,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.15,
            0.4 + (index * 0.15),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _slideAnimations = List.generate(
      4,
      (index) => Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.15,
            0.4 + (index * 0.15),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _controller.forward();

    // Listen to search input changes
    _searchController.addListener(_onSearchChanged);
    
    // Listen to focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
          _selectedFilter = 'All'; // Reset filter when clearing search
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _deezerService.searchTracks(query, limit: 50);

      // Group results by artist and album
      final artistsMap = <String, List<Track>>{};
      final albumsMap = <String, List<Track>>{};

      for (var track in results) {
        // Group by artist
        if (!artistsMap.containsKey(track.artistName)) {
          artistsMap[track.artistName] = [];
        }
        artistsMap[track.artistName]!.add(track);

        // Group by album
        final albumKey = '${track.albumName}_${track.artistName}';
        if (!albumsMap.containsKey(albumKey)) {
          albumsMap[albumKey] = [];
        }
        albumsMap[albumKey]!.add(track);
      }

      setState(() {
        _searchResults = results;
        _artistsMap = artistsMap;
        _albumsMap = albumsMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
        );
      }
    }
  }

  Widget _buildFilteredContent() {
    switch (_selectedFilter) {
      case 'Artists':
        return _ArtistResults(artistsMap: _artistsMap);
      case 'Albums':
        return _AlbumResults(albumsMap: _albumsMap);
      case 'Playlists':
        return _PlaylistSuggestions(searchQuery: _searchController.text);
      default: // 'All' or 'Songs'
        return _SearchResults(results: _searchResults);
    }
  }



  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
    });
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
                    AppColors.secondary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                FadeTransition(
                  opacity: _fadeAnimations[0],
                  child: SlideTransition(
                    position: _slideAnimations[0],
                    child: const _Header(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 70),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _fadeAnimations[1],
                          child: SlideTransition(
                            position: _slideAnimations[1],
                            child: _SearchBar(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onClear: _clearSearch,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Show filter chips only when there are results
                        if (_hasSearched && _searchResults.isNotEmpty)
                          FadeTransition(
                            opacity: _fadeAnimations[2],
                            child: SlideTransition(
                              position: _slideAnimations[2],
                              child: _FilterChips(
                                selectedFilter: _selectedFilter,
                                onFilterChanged: (filter) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Content based on state
                        if (_isLoading)
                          const _LoadingState()
                        else if (_hasSearched && _searchResults.isEmpty)
                          const _EmptyState()
                        else if (_hasSearched && _searchResults.isNotEmpty)
                          _buildFilteredContent()
                        else if (_isSearchFocused && _searchController.text.isEmpty)
                          // Show suggestions when search bar is focused
                          FadeTransition(
                            opacity: _fadeAnimations[3],
                            child: SlideTransition(
                              position: _slideAnimations[3],
                              child: _SearchSuggestionsSection(
                                onSuggestionTap: (query) {
                                  _searchController.text = query;
                                  _onSearchChanged();
                                },
                              ),
                            ),
                          )
                        else
                          // Show discover section when not focused
                          FadeTransition(
                            opacity: _fadeAnimations[3],
                            child: SlideTransition(
                              position: _slideAnimations[3],
                              child: const _DiscoverSection(),
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Search',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceLight, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuD4zTvs1ZSng5Zs-6SN5e6BY4THURyLABqJuRzTseMfznR7cdc845lQnuxW_Byz_ueROCw2Hi8LXbQB_UR16NDwRAkvGIQGq4UYgSDdkZwtqAhbJSSR0LO4GYw1U9XAcqiEZUIrpVEOh07cioPqi1a42PawaVEWvSbkbqTmdUHo7oM-W1uR3o5oWQZPdph52lmM_rZAKUB2TtCdBP82GoLoClCKT7MmwfYAq0qdj7O6Unr5NCwYW8o4kMrGa1m_DtQjKdF2xDxXSw',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.search,
              color: AppColors.textMuted,
              size: 24,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Artists, Songs, Lyrics and more',
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: const Icon(
                Icons.clear,
                color: AppColors.textMuted,
                size: 20,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.mic,
                color: AppColors.textMuted,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const _FilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Songs', 'Artists', 'Albums', 'Playlists'];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              onFilterChanged(filter);
              // Show feedback
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    filter == 'All'
                        ? 'Showing all results'
                        : 'Filtered by $filter',
                    textAlign: TextAlign.center,
                  ),
                  duration: const Duration(milliseconds: 800),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: AnimatedScale(
              scale: isSelected ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primary : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: isSelected ? 12 : 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                    ),
                    child: Text(filter),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Loading State Widget
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        const SizedBox(height: 24),
        Text(
          'Searching...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// Empty State Widget
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search_off_rounded,
            size: 60,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'No Results Found',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Try searching with different keywords',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// Search Results Widget
class _SearchResults extends StatelessWidget {
  final List<Track> results;

  const _SearchResults({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.filter_list_off,
              size: 60,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No results for this filter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different filter',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                '${results.length} ${results.length == 1 ? 'Result' : 'Results'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Songs',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final track = results[index];
            return _SearchResultItem(track: track);
          },
        ),
      ],
    );
  }
}

// Search Result Item Widget
class _SearchResultItem extends StatelessWidget {
  final Track track;

  const _SearchResultItem({required this.track});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // Phát nhạc ngay khi tap
        final player = AudioPlayerService.instance;
        try {
          await player.setTrack(track);
          await player.play();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không phát được bài này: $e')),
            );
          }
          return;
        }
        
        // Navigate đến Now Playing
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NowPlayingScreen(),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Album Art
            Hero(
              tag: 'search_${track.id}',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: track.imageUrl.isNotEmpty
                      ? Image.network(
                          track.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.secondary,
                              child: const Icon(
                                Icons.music_note,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.secondary,
                          child: const Icon(
                            Icons.music_note,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Track Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      // Navigate to Artist Detail Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArtistDetailScreen(
                            artistName: track.artistName,
                            artistImage: track.imageUrl,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            track.artistName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  AppColors.textMuted.withValues(alpha: 0.3),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Duration & More Button
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  track.duration,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.more_vert,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSuggestionsSection extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const _SearchSuggestionsSection({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final trendingSearches = [
      {'icon': Icons.trending_up, 'text': 'Trending now'},
      {'icon': Icons.star, 'text': 'Top hits 2024'},
      {'icon': Icons.music_note, 'text': 'New releases'},
      {'icon': Icons.favorite, 'text': 'Popular artists'},
      {'icon': Icons.album, 'text': 'Viral playlists'},
    ];

    final popularSearches = <String>[];

    final suggestedSongs = <Map<String, String>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Suggested Songs
        const Text(
          'Suggested Songs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        ...suggestedSongs.map((song) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(song['image'] as String),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(
                  song['title'] as String,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song['artist'] as String,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(
                  Icons.play_circle_outline,
                  color: AppColors.primary,
                  size: 32,
                ),
                onTap: () => onSuggestionTap(song['title'] as String),
              ),
            )),
        const SizedBox(height: 24),
        
        // Trending Searches
        const Text(
          'Trending Searches',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 16),
        ...trendingSearches.map((item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                item['icon'] as IconData,
                color: AppColors.primary,
                size: 24,
              ),
              title: Text(
                item['text'] as String,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textMain,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: () => onSuggestionTap(item['text'] as String),
            )),
        const SizedBox(height: 24),
        
        // Popular Searches
        const Text(
          'Popular Artists',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popularSearches.map((search) => ActionChip(
            label: Text(search),
            labelStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textMain,
            ),
            backgroundColor: AppColors.cardBackground,
            side: BorderSide(color: AppColors.divider.withValues(alpha: 0.3)),
            onPressed: () => onSuggestionTap(search),
          )).toList(),
        ),
      ],
    );
  }
}

class _DiscoverSection extends StatelessWidget {
  const _DiscoverSection();

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        'title': 'Chill\nVibes',
        'searchQuery': 'chill lofi',
        'bgColor': const Color(0xFFFFD8D8).withValues(alpha: 0.6),
        'textColor': const Color(0xFF8B4848),
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuD9fxCh6ix0aWLgour1YPDsqEAdkSI_q85A_PQ-r-IpV15bFAnCSroUA2hJvtpfEecrMtv6AED61ldXvgn4uH-IiRnElltY4h_YrxbBlPx3BnrGwXGEC9aE1okxT9imLOMmawLxC-IYRS_ABtMvc3IXv7FwqF2kmLHHLjcq9SxUET6r8oSBK48CJcInyPnZPeWVO9owgW3QrGXXfzWiJtRErdJyzR2cQ_vRGO1JqxYeoT2y70dxJyRIhCrL-u-OB3Ed4A9wPIaxQw',
      },
      {
        'title': 'Pop\nHits',
        'searchQuery': 'pop hits',
        'bgColor': const Color(0xFFD8E6FF).withValues(alpha: 0.6),
        'textColor': const Color(0xFF485E8B),
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuD4zTvs1ZSng5Zs-6SN5e6BY4THURyLABqJuRzTseMfznR7cdc845lQnuxW_Byz_ueROCw2Hi8LXbQB_UR16NDwRAkvGIQGq4UYgSDdkZwtqAhbJSSR0LO4GYw1U9XAcqiEZUIrpVEOh07cioPqi1a42PawaVEWvSbkbqTmdUHo7oM-W1uR3o5oWQZPdph52lmM_rZAKUB2TtCdBP82GoLoClCKT7MmwfYAq0qdj7O6Unr5NCwYW8o4kMrGa1m_DtQjKdF2xDxXSw',
      },
      {
        'title': 'Focus\nFlow',
        'searchQuery': 'study focus',
        'bgColor': const Color(0xFFE6FFD8).withValues(alpha: 0.6),
        'textColor': const Color(0xFF538B48),
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAmtFifzozcQm7xAGiCL7_6Icz5OfmgQWrbVoM4jjIdaOwTrkGuVQBLHWYPVVl9KRG_eGN6qkbhIRxMzltH10xZUD1QvtBeAwFhEMq66Mk7TPZUgzzMy9oj9_OTYdmYXISguXLBSZp4MDLLhyrM7XuBFnhroFY7-npxaToy02371fr_CCidrCgPkI6CeLJPaz0JXvkLQR52PbbKa83XvoNM2l4F5Z0FYd3xtzsQF5Wj-ydFhTa2lHb92aaWFpkPlJAzR_1vTDVaVQ',
      },
      {
        'title': 'Jazz\nClub',
        'searchQuery': 'jazz',
        'bgColor': const Color(0xFFFFF4D8).withValues(alpha: 0.6),
        'textColor': const Color(0xFF8B7848),
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuC0twC4bcYkDO_Ks18aY0qp5CTNDlfne1DHEy86WFtTl5AGTHEcFCOIBANtP_w1AmYviNfj9jrQ4svLAER01_WSQ9mTnYs4199WII8b2ASOEJp2SPHkjL88UbfbXPsHM85vqFl3uDkzkGQ6BvMzTbp6RqE0jWYOE2z7Ppsq_MfOCjK84lhjE0oBxxPbnnGLNw9WjIDH6fCXfMqWe43k0EmAHbLqNZXgLGDXaPXnk6QSWMI2rcRmPPHoavM7RqKKPYmpV4-2KLxUGg',
      },
      {
        'title': 'Rock\nLegends',
        'searchQuery': 'rock',
        'bgColor': const Color(0xFFFFE6D8).withValues(alpha: 0.6),
        'textColor': const Color(0xFF8B5E48),
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuD9fxCh6ix0aWLgour1YPDsqEAdkSI_q85A_PQ-r-IpV15bFAnCSroUA2hJvtpfEecrMtv6AED61ldXvgn4uH-IiRnElltY4h_YrxbBlPx3BnrGwXGEC9aE1okxT9imLOMmawLxC-IYRS_ABtMvc3IXv7FwqF2kmLHHLjcq9SxUET6r8oSBK48CJcInyPnZPeWVO9owgW3QrGXXfzWiJtRErdJyzR2cQ_vRGO1JqxYeoT2y70dxJyRIhCrL-u-OB3Ed4A9wPIaxQw',
      },
      {
        'title': 'Hip Hop\nBeats',
        'searchQuery': 'hip hop',
        'bgColor': const Color(0xFFE8D8FF).withValues(alpha: 0.6),
        'textColor': const Color(0xFF5E488B),
        'image':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuD4zTvs1ZSng5Zs-6SN5e6BY4THURyLABqJuRzTseMfznR7cdc845lQnuxW_Byz_ueROCw2Hi8LXbQB_UR16NDwRAkvGIQGq4UYgSDdkZwtqAhbJSSR0LO4GYw1U9XAcqiEZUIrpVEOh07cioPqi1a42PawaVEWvSbkbqTmdUHo7oM-W1uR3o5oWQZPdph52lmM_rZAKUB2TtCdBP82GoLoClCKT7MmwfYAq0qdj7O6Unr5NCwYW8o4kMrGa1m_DtQjKdF2xDxXSw',
      },
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Discover',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            TextButton(
              onPressed: () {
                // Show more categories in a dialog or navigate to browse screen
                _showAllCategories(context, categories);
              },
              child: const Text(
                'SEE ALL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: categories.length > 4 ? 4 : categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryCard(
              title: category['title'] as String,
              searchQuery: category['searchQuery'] as String,
              bgColor: category['bgColor'] as Color,
              textColor: category['textColor'] as Color,
              imageUrl: category['image'] as String,
            );
          },
        ),
      ],
    );
  }

  void _showAllCategories(
      BuildContext context, List<Map<String, dynamic>> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AllCategoriesSheet(categories: categories),
    );
  }
}

// All Categories Bottom Sheet
class _AllCategoriesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> categories;

  const _AllCategoriesSheet({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Categories',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Categories Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryCard(
                  title: category['title'] as String,
                  searchQuery: category['searchQuery'] as String,
                  bgColor: category['bgColor'] as Color,
                  textColor: category['textColor'] as Color,
                  imageUrl: category['image'] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String title;
  final String searchQuery;
  final Color bgColor;
  final Color textColor;
  final String imageUrl;

  const _CategoryCard({
    required this.title,
    required this.searchQuery,
    required this.bgColor,
    required this.textColor,
    required this.imageUrl,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isPressed = false;

  void _onTap(BuildContext context) async {
    // Navigate to Genre Detail Screen or trigger search
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _GenreDetailScreen(
          title: widget.title.replaceAll('\n', ' '),
          searchQuery: widget.searchQuery,
          bgColor: widget.bgColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => _onTap(context),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.02 : 0.05),
                blurRadius: _isPressed ? 5 : 10,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor,
                    height: 1.1,
                  ),
                ),
              ),
              Positioned(
                bottom: -8,
                right: -8,
                child: Transform.rotate(
                  angle: 0.26, // ~15 degrees
                  child: Container(
                    height: 96,
                    width: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Genre Detail Screen (mini screen for category details)
class _GenreDetailScreen extends StatefulWidget {
  final String title;
  final String searchQuery;
  final Color bgColor;

  const _GenreDetailScreen({
    required this.title,
    required this.searchQuery,
    required this.bgColor,
  });

  @override
  State<_GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends State<_GenreDetailScreen> {
  final DeezerService _deezerService = DeezerService();
  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    try {
      final results =
          await _deezerService.searchTracks(widget.searchQuery, limit: 30);
      setState(() {
        _tracks = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tracks: $e')),
        );
      }
    }
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
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.bgColor,
                    AppColors.backgroundLight,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
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
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
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
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tracks List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        )
                      : _tracks.isEmpty
                          ? const Center(
                              child: Text(
                                'No tracks found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _tracks.length,
                              itemBuilder: (context, index) {
                                return _SearchResultItem(track: _tracks[index]);
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

// Artist Results Widget
class _ArtistResults extends StatelessWidget {
  final Map<String, List<Track>> artistsMap;

  const _ArtistResults({required this.artistsMap});

  @override
  Widget build(BuildContext context) {
    final artists = artistsMap.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                '${artists.length} ${artists.length == 1 ? 'Artist' : 'Artists'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Artists',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artistName = artists[index].key;
            final tracks = artists[index].value;
            final firstTrack = tracks.first;

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArtistDetailScreen(
                      artistName: artistName,
                      artistImage: firstTrack.imageUrl,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Artist Image
                    Hero(
                      tag: 'artist_$artistName',
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: firstTrack.imageUrl.isNotEmpty
                              ? Image.network(
                                  firstTrack.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.secondary,
                                      child: const Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: AppColors.secondary,
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Artist Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artistName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Album Results Widget
class _AlbumResults extends StatelessWidget {
  final Map<String, List<Track>> albumsMap;

  const _AlbumResults({required this.albumsMap});

  @override
  Widget build(BuildContext context) {
    final albums = albumsMap.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                '${albums.length} ${albums.length == 1 ? 'Album' : 'Albums'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.album,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Albums',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final tracks = albums[index].value;
            final firstTrack = tracks.first;

            return InkWell(
              onTap: () {
                // Navigate to album detail or now playing
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NowPlayingScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Album Art
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: firstTrack.imageUrl.isNotEmpty
                            ? Image.network(
                                firstTrack.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.secondary,
                                    child: const Icon(
                                      Icons.album,
                                      color: AppColors.primary,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: AppColors.secondary,
                                child: const Icon(
                                  Icons.album,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Album Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstTrack.albumName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            firstTrack.artistName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Track count
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${tracks.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Playlist Suggestions Widget
class _PlaylistSuggestions extends StatelessWidget {
  final String searchQuery;

  const _PlaylistSuggestions({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    // For now, show suggested playlists based on search
    final suggestions = [
      {'name': 'Top $searchQuery Hits', 'count': '50 songs'},
      {'name': '$searchQuery Mix', 'count': '30 songs'},
      {'name': 'Best of $searchQuery', 'count': '40 songs'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                'Suggested Playlists',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.queue_music,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Playlists',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final playlist = suggestions[index];

            return InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Playlist Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.8),
                            AppColors.secondary,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.queue_music,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Playlist Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist['name']!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            playlist['count']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Play button
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
