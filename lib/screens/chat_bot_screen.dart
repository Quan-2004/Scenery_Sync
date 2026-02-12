import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../theme/colors.dart';
import '../models/music_models.dart';
import '../services/audio_player_service.dart';

class ChatBotScreen extends StatefulWidget {
  final String? imagePath;

  const ChatBotScreen({super.key, this.imagePath});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _animationController;
  ImageLabeler? _imageLabeler;

  final List<String> _quickSuggestions = [
    'Recommend me some chill music',
    'What\'s trending today?',
    'Create a workout playlist',
    'Find songs like Blinding Lights',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize image labeler if needed
    if (widget.imagePath != null) {
      final ImageLabelerOptions options = ImageLabelerOptions(
        confidenceThreshold: 0.5,
      );
      _imageLabeler = ImageLabeler(options: options);
      _handleImageAnalysis();
    } else {
      // Welcome message
      Future.delayed(const Duration(milliseconds: 500), () {
        _addBotMessage(
          'Hi there! 👋 I\'m your music assistant. How can I help you discover amazing music today?',
        );
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _imageLabeler?.close();
    super.dispose();
  }

  Future<void> _handleImageAnalysis() async {
    if (widget.imagePath == null) return;

    // Add user message with image
    _messages.add(
      ChatMessage(
        text: '',
        isUser: true,
        timestamp: DateTime.now(),
        imagePath: widget.imagePath,
      ),
    );

    // Add bot analyzing message
    Future.delayed(const Duration(milliseconds: 300), () {
      _addBotMessage('Analyzing your scenery... 🔍');
    });

    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath!);
      final labels = await _imageLabeler!.processImage(inputImage);

      // Get music recommendations based on labels
      final tracks = _getRecommendationsFromLabels(labels);

      if (mounted) {
        // Build response message
        String response = '';
        if (labels.isNotEmpty) {
          final detectedLabels = labels.map((l) => l.label).take(3).join(', ');
          response += '✨ I detected: $detectedLabels\n\n';
        }

        response +=
            '🎵 Based on your scenery, here are some music recommendations. I\'m playing the best match for you now!';

        // Add message with tracks (custom message type needed or handled in builder)
        // For now, we'll just add the text and handle the list in the UI builder
        // by checking if the message is from bot and has tracks associated (need to update model)

        setState(() {
          _messages.add(
            ChatMessage(
              text: response,
              isUser: false,
              timestamp: DateTime.now(),
              tracks: tracks, // Pass tracks to message
            ),
          );
        });
        _scrollToBottom();

        // Auto-play the first recommended track
        if (tracks.isNotEmpty) {
          try {
            await AudioPlayerService.instance.setQueue(tracks, startIndex: 0);
            await AudioPlayerService.instance.play();
            debugPrint('✅ Auto-playing: ${tracks[0].name}');
          } catch (e) {
            debugPrint('❌ Error auto-playing track: $e');
            _addBotMessage(
              'I had trouble playing the track, but you can try playing it manually from the player.',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      if (mounted) {
        _addBotMessage(
          'Sorry, I had trouble analyzing the image. But I\'m still here to help with music recommendations! 🎧',
        );
      }
    }
  }

  List<Track> _getRecommendationsFromLabels(List<ImageLabel> labels) {
    final keywords = labels.map((l) => l.label.toLowerCase()).toList();

    // Default recommendations
    List<Track> recommendations = [
      Track(
        id: '1',
        name: 'Morning Breeze',
        artistName: 'Nature Sounds',
        artistId: 'art1',
        albumName: 'Morning',
        albumId: 'alb1',
        imageUrl: 'https://picsum.photos/seed/nature/300/300',
        durationMs: 180000,
        popularity: 80,
      ),
      Track(
        id: '2',
        name: 'City Lights',
        artistName: 'Urban Beats',
        artistId: 'art2',
        albumName: 'Night Life',
        albumId: 'alb2',
        imageUrl: 'https://picsum.photos/seed/city/300/300',
        durationMs: 200000,
        popularity: 75,
      ),
      Track(
        id: '3',
        name: 'Ocean Waves',
        artistName: 'Relaxing Vibes',
        artistId: 'art3',
        albumName: 'Ocean',
        albumId: 'alb3',
        imageUrl: 'https://picsum.photos/seed/ocean/300/300',
        durationMs: 240000,
        popularity: 90,
      ),
    ];

    // Simple filtering based on keywords
    if (keywords.any(
      (k) => k.contains('sky') || k.contains('cloud') || k.contains('blue'),
    )) {
      return [recommendations[0], recommendations[2]];
    }
    if (keywords.any(
      (k) => k.contains('building') || k.contains('city') || k.contains('road'),
    )) {
      return [recommendations[1]];
    }

    return recommendations;
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: false, timestamp: DateTime.now()),
      );
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
    });
    _scrollToBottom();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();
    _addUserMessage(text);

    // Simulate bot typing
    setState(() {
      _isTyping = true;
    });

    // Simulate bot response
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _isTyping = false;
      });

      // Generate response based on input
      String response = _generateResponse(text);
      _addBotMessage(response);
    });
  }

  String _generateResponse(String input) {
    final lowerInput = input.toLowerCase();

    if (lowerInput.contains('recommend') || lowerInput.contains('suggest')) {
      return '🎵 Based on your listening history, I can recommend personalized songs for you.\n\nWould you like me to create a playlist?';
    } else if (lowerInput.contains('trending') ||
        lowerInput.contains('popular')) {
      return '🔥 I can show you trending songs.\n\nTap the search icon to discover popular music!';
    } else if (lowerInput.contains('workout') ||
        lowerInput.contains('exercise')) {
      return '💪 I\'ve created a high-energy workout playlist for you!\n\n• 150-180 BPM tracks\n• 45 minutes duration\n• Motivational beats\n\nReady to crush your workout?';
    } else if (lowerInput.contains('like') || lowerInput.contains('similar')) {
      return '✨ I can find songs similar to your favorites.\n\nShall I add these to your queue?';
    } else if (lowerInput.contains('playlist')) {
      return '📝 I can help you create a playlist! What mood or theme are you looking for?\n\n• Chill vibes\n• Party hits\n• Focus & Study\n• Road trip';
    } else if (lowerInput.contains('sleep') || lowerInput.contains('relax')) {
      return '😴 Perfect for relaxation:\n\nI\'ve prepared a calming playlist with ambient sounds and soft melodies. Should I also set a sleep timer?';
    } else {
      return 'I\'m here to help you with music recommendations, playlist creation, artist info, and more! What would you like to explore? 🎧';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withValues(alpha: 0.05), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),

              // Typing Indicator
              if (_isTyping) _buildTypingIndicator(),

              // Quick Suggestions (shown when no messages)
              if (_messages.length <= 1) _buildQuickSuggestions(),

              // Input Area
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF39C4D),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF39C4D).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scenery Sync Fox 🦊',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Your AI Music Companion',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF39C4D),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF39C4D).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🦊', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      )
                    : null,
                color: message.isUser ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(message.imagePath!),
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (message.text.isNotEmpty) const SizedBox(height: 8),
                  ],
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 15,
                        color: message.isUser ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  // Display Tracks if available
                  if (message.tracks != null && message.tracks!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...message.tracks!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final track = entry.value;
                      return GestureDetector(
                        onTap: () async {
                          await AudioPlayerService.instance.setQueue([track]);
                          await AudioPlayerService.instance.play();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  track.imageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      track.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      track.artistName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.play_circle_fill,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isUser
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.black54,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final offset = (value * 3.14159 * 2) + (index * 0.5);
        final scale = 0.5 + (0.5 * (1 + (math.sin(offset) / 2)));

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted && _isTyping) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildQuickSuggestions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick suggestions:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSuggestions.map((suggestion) {
              return GestureDetector(
                onTap: () => _handleSubmitted(suggestion),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Ask me anything about music...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                ),
                onSubmitted: _handleSubmitted,
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _handleSubmitted(_textController.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;
  final List<Track>? tracks;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
    this.tracks,
  });
}
