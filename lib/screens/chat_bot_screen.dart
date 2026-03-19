import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/colors.dart';
import '../models/music_models.dart';
import '../services/audio_player_service.dart';
import '../services/deezer_service.dart';
import 'now_playing_screen.dart';
import '../services/jamendo_service.dart';
import '../services/ambient_sound_service.dart';
import '../services/firebase_service.dart';

enum _SceneMode {
  urbanTraffic,
  natureWild,
  beachWater,
  indoorPet,
  weatherStorm,
  mixed,
}

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
  bool _isPickingImage = false;
  late AnimationController _animationController;
  ImageLabeler? _imageLabeler;
  final AmbientSoundService _ambientSoundService = AmbientSoundService();
  final AudioPlayer _ambientPreviewPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _ambientPlayerStateSub;
  String? _ambientPreviewUrl;
  Map<String, double> _learnedKeywordWeights = const {};

  static const Set<String> _knownContextKeywords = {
    'rain', 'mua', 'mưa', 'drizzle', 'storm', 'thunder', 'lightning',
    'beach', 'ocean', 'sea', 'wave', 'coast', 'shore', 'bien', 'biển',
    'song', 'sóng', 'river', 'stream', 'waterfall', 'suoi', 'suối', 'thac', 'thác',
    'forest', 'jungle', 'tree', 'nature', 'rung', 'rừng', 'thien nhien', 'thiên nhiên',
    'city', 'urban', 'street', 'traffic', 'downtown', 'thanh pho', 'thành phố',
    'duong pho', 'đường phố', 'cafe', 'coffee', 'quan ca phe', 'quán cà phê',
    'night', 'moon', 'star', 'dem', 'đêm', 'sunset', 'sunrise', 'dawn', 'dusk',
    'hoang hon', 'hoàng hôn', 'binh minh', 'bình minh', 'winter', 'snow', 'cold',
    'fog', 'mist', 'wind', 'breeze', 'gio', 'gió', 'calm', 'peaceful', 'relax',
    'chill', 'focus', 'study', 'tap trung', 'tập trung', 'workout', 'gym', 'yoga',
    'romantic', 'happy', 'sad', 'travel', 'roadtrip', 'driving', 'adventure',
    'sky', 'cloud', 'mountain', 'lake', 'flower', 'grass', 'landscape', 'scenery',
  };

  static const Set<String> _keywordNoise = {
    'font', 'text', 'logo', 'brand', 'symbol', 'design', 'graphics',
    'product', 'poster', 'screenshot', 'photo', 'image', 'app', 'website',
    'screen', 'display', 'document', 'interface', 'ui', 'ux',
  };

    bool get _isVietnamese => context.locale.languageCode == 'vi';

    List<String> get _quickSuggestions => _isVietnamese
      ? [
        'Gợi ý cho tôi nhạc chill',
        'Hôm nay có gì đang thịnh hành?',
        'Tạo cho tôi playlist tập luyện',
        'Tìm bài giống Blinding Lights',
      ]
      : [
        'Recommend me some chill music',
        'What\'s trending today?',
        'Create a workout playlist',
        'Find songs like Blinding Lights',
      ];

    String get _welcomeMessage => _isVietnamese
      ? 'Xin chào! 👋 Tôi là trợ lý âm nhạc của bạn. Hôm nay tôi có thể giúp bạn khám phá điều gì?'
      : 'Hi there! 👋 I\'m your music assistant. How can I help you discover amazing music today?';

    String get _analyzingSceneryMessage =>
      _isVietnamese ? 'Đang phân tích khung cảnh của bạn... 🔍' : 'Analyzing your scenery... 🔍';

    String _nonSceneryImageMessage(String preview) => _isVietnamese
      ? 'Ảnh này có vẻ giống ảnh chụp màn hình, poster hoặc giao diện hơn là ảnh phong cảnh thật. Tôi nhận ra: $preview. Hãy thử dùng ảnh ngoài trời hoặc ảnh môi trường thực tế để tôi gợi ý nhạc và âm thanh chính xác hơn.'
      : 'This image looks more like a screenshot, poster, or UI capture than a real scenery photo. I detected: $preview. Please try a real outdoor or environmental photo so I can suggest matching music and ambient sounds more accurately.';

    String _detectedMessage(String preview) =>
      _isVietnamese ? '✨ Tôi nhận ra: $preview\n\n' : '✨ I detected: $preview\n\n';

      String get _musicSuggestionsHeader => _isVietnamese
        ? '🎵 Đây là danh sách nhạc gợi ý cho bạn:'
        : '🎵 Here are your music suggestions:';

      String get _ambientSuggestionsHeader => _isVietnamese
        ? '🌧️ Đây là danh sách âm thanh môi trường gợi ý:'
        : '🌧️ Here are your ambient sound suggestions:';

    String get _manualPlayFallbackMessage => _isVietnamese
      ? 'Tôi gặp sự cố khi phát bài hát, nhưng bạn vẫn có thể thử phát thủ công từ danh sách bên dưới.'
      : 'I had trouble playing the track, but you can try playing it manually from the player.';

    String get _imageAnalysisErrorMessage => _isVietnamese
      ? 'Xin lỗi, tôi gặp sự cố khi phân tích ảnh. Nhưng tôi vẫn có thể giúp bạn gợi ý nhạc nếu bạn mô tả khung cảnh bằng chữ. 🎧'
      : 'Sorry, I had trouble analyzing the image. But I\'m still here to help with music recommendations! 🎧';

    String _textSceneDetectedMessage(String detected) => _isVietnamese
      ? '✨ Tôi hiểu cảm giác bạn muốn là: $detected\n\n'
      : '✨ I understand this vibe as: $detected\n\n';

    String get _textSceneMusicMessage => _isVietnamese
      ? '🎵 Tôi đã tìm được những bài nhạc phù hợp với điều bạn mô tả.'
      : '🎵 I found music that matches what you described.';

    String get _textSceneAmbientMessage => _isVietnamese
      ? '🌧️ Tôi cũng chuẩn bị thêm các gợi ý âm thanh môi trường đúng với mood này.'
      : '🌧️ I also prepared ambient sounds that fit this mood.';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _ambientPlayerStateSub = _ambientPreviewPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _ambientPreviewPlayer.seek(Duration.zero);
        _ambientPreviewPlayer.pause();
      }
      setState(() {});
    });

    Future.microtask(_bootstrapChat);
  }

  Future<void> _bootstrapChat() async {
    final firebaseService = context.read<FirebaseService>();
    if (!firebaseService.isLoggedIn) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    await _loadLearnedKeywordWeights();
    await _restoreChatHistory();

    if (!mounted) return;

    // Initialize image labeler if needed
    if (widget.imagePath != null) {
      final ImageLabelerOptions options = ImageLabelerOptions(
        confidenceThreshold: 0.35,
      );
      _imageLabeler = ImageLabeler(options: options);
      await _handleImageAnalysis();
      return;
    }

    if (_messages.isEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted || _messages.isNotEmpty) return;
        _addBotMessage(_welcomeMessage);
      });
    }
  }

  Future<void> _loadLearnedKeywordWeights() async {
    try {
      final firebaseService = context.read<FirebaseService>();
      _learnedKeywordWeights = await firebaseService.getLearnedKeywordWeights(
        limit: 140,
      );
      if (_learnedKeywordWeights.isNotEmpty) {
        debugPrint(
          '🧠 Loaded learned keywords: ${_learnedKeywordWeights.length}',
        );
      }
    } catch (e) {
      debugPrint('Load learned keywords error: $e');
      _learnedKeywordWeights = const {};
    }
  }

  Future<void> _restoreChatHistory() async {
    final firebaseService = context.read<FirebaseService>();
    if (!firebaseService.isLoggedIn) return;

    try {
      await firebaseService.deleteExpiredChatMessages();
      final docs = await firebaseService.getRecentChatMessages(limit: 120);
      if (docs.isEmpty || !mounted) return;

      final restored = docs.map(_messageFromMap).toList();
      setState(() {
        _messages
          ..clear()
          ..addAll(restored);
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Restore chat history error: $e');
    }
  }

  DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> _trackToMap(Track t) => {
        'id': t.id,
        'name': t.name,
        'artistName': t.artistName,
        'artistId': t.artistId,
        'albumName': t.albumName,
        'albumId': t.albumId,
        'imageUrl': t.imageUrl,
        'previewUrl': t.previewUrl,
        'durationMs': t.durationMs,
        'popularity': t.popularity,
      };

  Track _trackFromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      artistName: map['artistName']?.toString() ?? 'Unknown Artist',
      artistId: map['artistId']?.toString() ?? '',
      albumName: map['albumName']?.toString() ?? '',
      albumId: map['albumId']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      previewUrl: map['previewUrl']?.toString(),
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      popularity: (map['popularity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> _ambientToMap(AmbientSuggestion a) => {
        'title': a.title,
        'query': a.query,
        'provider': a.provider,
        'previewUrl': a.previewUrl,
      };

  AmbientSuggestion _ambientFromMap(Map<String, dynamic> map) {
    final provider = map['provider']?.toString() ?? 'Ambient';
    return AmbientSuggestion(
      title: map['title']?.toString() ?? 'Ambient Sound',
      query: map['query']?.toString() ?? '',
      provider: provider,
      icon: _providerIcon(provider),
      previewUrl: map['previewUrl']?.toString(),
    );
  }

  ChatMessage _messageFromMap(Map<String, dynamic> data) {
    final tracksRaw = (data['tracks'] as List?) ?? const [];
    final ambienceRaw = (data['ambienceSuggestions'] as List?) ?? const [];

    final tracks = tracksRaw
        .whereType<Map>()
        .map((e) => _trackFromMap(Map<String, dynamic>.from(e)))
        .toList();

    final ambience = ambienceRaw
        .whereType<Map>()
        .map((e) => _ambientFromMap(Map<String, dynamic>.from(e)))
        .toList();

    return ChatMessage(
      text: data['text']?.toString() ?? '',
      isUser: data['isUser'] == true,
      timestamp: _parseTimestamp(data['clientCreatedAt'] ?? data['createdAt']),
      imagePath: data['imagePath']?.toString(),
      tracks: tracks.isEmpty ? null : tracks,
      ambienceSuggestions: ambience.isEmpty ? null : ambience,
    );
  }

  Future<void> _persistMessage(ChatMessage message) async {
    final firebaseService = context.read<FirebaseService>();
    if (!firebaseService.isLoggedIn) return;

    try {
      await firebaseService.saveChatMessage({
        'text': message.text,
        'isUser': message.isUser,
        'imagePath': message.imagePath,
        'tracks': (message.tracks ?? []).map(_trackToMap).toList(),
        'ambienceSuggestions':
            (message.ambienceSuggestions ?? []).map(_ambientToMap).toList(),
      });
    } catch (e) {
      debugPrint('Persist chat message error: $e');
    }
  }

  @override
  void dispose() {
    _ambientPlayerStateSub?.cancel();
    _ambientPreviewPlayer.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _imageLabeler?.close();
    super.dispose();
  }

  Future<void> _toggleAmbientPreview(AmbientSuggestion ambient) async {
    final preview = ambient.previewUrl?.trim() ?? '';
    if (preview.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isVietnamese ? 'Mục này chưa có link nghe thử' : 'No preview link for this item'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      if (_ambientPreviewUrl == preview) {
        if (_ambientPreviewPlayer.playing) {
          await _ambientPreviewPlayer.pause();
        } else {
          await _ambientPreviewPlayer.play();
        }
      } else {
        _ambientPreviewUrl = preview;
        await _ambientPreviewPlayer.setUrl(preview);
        await _ambientPreviewPlayer.play();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Ambient preview playback error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isVietnamese ? 'Không phát được bản xem trước' : 'Could not play preview'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleImageAnalysis({String? imagePath}) async {
    final targetImagePath = imagePath ?? widget.imagePath;
    if (targetImagePath == null || targetImagePath.isEmpty) return;

    // Add user message with image
    final imageMessage = ChatMessage(
      text: '',
      isUser: true,
      timestamp: DateTime.now(),
      imagePath: targetImagePath,
    );
    setState(() {
      _messages.add(imageMessage);
    });
    _scrollToBottom();
    unawaited(_persistMessage(imageMessage));

    // Add bot analyzing message
    Future.delayed(const Duration(milliseconds: 300), () {
      _addBotMessage(_analyzingSceneryMessage);
    });

    try {
      final inputImage = InputImage.fromFilePath(targetImagePath);
      final labels = await _imageLabeler!.processImage(inputImage);
      final weightedKeywords = _extractWeightedKeywords(labels);

      if (_looksLikeNonSceneryImage(weightedKeywords)) {
        if (!mounted) return;
        final detectedLabels = weightedKeywords.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final preview = detectedLabels.take(4).map((e) => e.key).join(', ');
        _addBotMessage(_nonSceneryImageMessage(preview));
        return;
      }

      unawaited(_learnKeywordsFromImage(weightedKeywords, targetImagePath));

      // Get music recommendations based on labels
      final tracks = await _getRecommendationsFromLabels(labels);
      final ambience = await _getAmbientSuggestionsFromLabels(labels);

      if (mounted) {
        String detectedPrefix = '';
        if (labels.isNotEmpty) {
          final detectedLabels = weightedKeywords.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final preview = detectedLabels.take(4).map((e) => e.key).join(', ');
          detectedPrefix = _detectedMessage(preview);
        }

        setState(() {
          final musicMessage = ChatMessage(
            text: '$detectedPrefix$_musicSuggestionsHeader',
            isUser: false,
            timestamp: DateTime.now(),
            tracks: tracks,
          );
          _messages.add(musicMessage);
          unawaited(_persistMessage(musicMessage));

          if (ambience.isNotEmpty) {
            final ambienceMessage = ChatMessage(
              text: _ambientSuggestionsHeader,
              isUser: false,
              timestamp: DateTime.now(),
              ambienceSuggestions: ambience,
            );
            _messages.add(ambienceMessage);
            unawaited(_persistMessage(ambienceMessage));
          }
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
            _addBotMessage(_manualPlayFallbackMessage);
          }
        }
      }
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      if (mounted) {
        _addBotMessage(_imageAnalysisErrorMessage);
      }
    }
  }

  Map<String, double> _extractWeightedKeywords(List<ImageLabel> labels) {
    final weighted = <String, double>{};
    const noise = {
      'font', 'text', 'logo', 'brand', 'symbol', 'design', 'graphics',
      'product', 'poster', 'screenshot', 'photo', 'image',
    };

    for (final label in labels) {
      final raw = label.label.toLowerCase().trim();
      final confidence = label.confidence;
      if (raw.isEmpty || confidence < 0.2) continue;

      final normalized = raw.replaceAll(RegExp(r'[^a-z0-9\\s]'), ' ');
      final tokens = normalized
          .split(RegExp(r'\\s+'))
          .where((t) => t.length >= 3 && !noise.contains(t));

      weighted[raw] = (weighted[raw] ?? 0) + confidence;
      for (final t in tokens) {
        weighted[t] = (weighted[t] ?? 0) + confidence;
      }
    }

    _applySceneAliasBoost(weighted);
    _applyLearnedKeywordBoost(weighted);

    return weighted;
  }

  void _applyLearnedKeywordBoost(Map<String, double> weighted) {
    if (_learnedKeywordWeights.isEmpty || weighted.isEmpty) return;

    final existingKeys = weighted.keys.toList();
    for (final entry in _learnedKeywordWeights.entries) {
      final learned = entry.key;
      final learnedWeight = entry.value;
      final matchedKeys = existingKeys
          .where((k) => k.contains(learned) || learned.contains(k))
          .toList();
      if (matchedKeys.isEmpty) continue;

      weighted[learned] = math.max(
        weighted[learned] ?? 0,
        learnedWeight * 0.8,
      );

      for (final key in matchedKeys) {
        weighted[key] = (weighted[key] ?? 0) + (learnedWeight * 0.35);
      }
    }
  }

  List<String> _extractNovelKeywords(Map<String, double> weightedKeywords) {
    final entries = weightedKeywords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final novel = <String>[];
    final seen = <String>{};

    for (final entry in entries) {
      if (entry.value < 0.55) continue;

      final normalized = entry.key
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'[^\p{L}0-9\s]', unicode: true), '')
          .trim();

      if (normalized.length < 4 || normalized.length > 36) continue;
      if (_keywordNoise.contains(normalized)) continue;
      if (_knownContextKeywords.contains(normalized)) continue;
      if (RegExp(r'^\d+$').hasMatch(normalized)) continue;

      final words = normalized.split(' ').where((w) => w.isNotEmpty).toList();
      if (words.isEmpty || words.length > 3) continue;
      if (words.every((w) => _knownContextKeywords.contains(w))) continue;
      if (words.any((w) => _keywordNoise.contains(w))) continue;

      if (seen.add(normalized)) {
        novel.add(normalized);
      }
      if (novel.length >= 6) break;
    }

    return novel;
  }

  Future<void> _learnKeywordsFromImage(
    Map<String, double> weightedKeywords,
    String imagePath,
  ) async {
    final firebaseService = context.read<FirebaseService>();
    if (!firebaseService.isLoggedIn) return;

    final novelKeywords = _extractNovelKeywords(weightedKeywords);
    if (novelKeywords.isEmpty) return;

    try {
      final learned = await firebaseService.reportLearnedKeywords(
        keywords: novelKeywords,
        weightedKeywords: weightedKeywords,
        imagePath: imagePath,
      );
      if (learned.isNotEmpty) {
        debugPrint('🧠 Learned new image keywords: ${learned.join(', ')}');
      }
    } catch (e) {
      debugPrint('Keyword learning report error: $e');
    }
  }

  void _applySceneAliasBoost(Map<String, double> weighted) {
    const aliasGroups = [
      ['rain', 'mua', 'mưa', 'drizzle', 'storm', 'thunder'],
      ['beach', 'ocean', 'sea', 'wave', 'coast', 'bien', 'biển', 'song', 'sóng'],
      ['forest', 'jungle', 'tree', 'nature', 'rung', 'rừng', 'thien nhien', 'thiên nhiên'],
      ['city', 'urban', 'street', 'traffic', 'downtown', 'thanh pho', 'thành phố', 'duong pho', 'đường phố'],
      ['night', 'moon', 'star', 'dem', 'đêm'],
      ['sunset', 'sunrise', 'dawn', 'dusk', 'hoang hon', 'hoàng hôn', 'binh minh', 'bình minh'],
      ['wind', 'breeze', 'fog', 'mist', 'gio', 'gió'],
      ['snow', 'winter', 'cold', 'tuyet', 'tuyết'],
      ['cafe', 'coffee', 'quan ca phe', 'quán cà phê'],
      ['relax', 'chill', 'calm', 'peaceful', 'thu gian', 'thư giãn'],
      ['focus', 'study', 'tap trung', 'tập trung'],
    ];

    for (final group in aliasGroups) {
      double groupMax = 0;
      for (final term in group) {
        groupMax = math.max(groupMax, weighted[term] ?? 0);
      }
      if (groupMax <= 0) continue;
      for (final term in group) {
        final boosted = groupMax * 0.42;
        weighted[term] = math.max(weighted[term] ?? 0, boosted);
      }
    }
  }

  bool _looksLikeNonSceneryImage(Map<String, double> weightedKeywords) {
    const nonSceneryTerms = [
      'screenshot', 'poster', 'flyer', 'document', 'text', 'font', 'logo',
      'website', 'app', 'software', 'interface', 'screen', 'display', 'ad',
      'banner', 'graphic', 'graphics', 'product',
    ];
    const sceneryTerms = [
      'sky', 'cloud', 'tree', 'forest', 'mountain', 'beach', 'ocean', 'river',
      'sunset', 'sunrise', 'rain', 'storm', 'grass', 'nature', 'landscape',
      'night', 'moon', 'star', 'flower', 'lake', 'waterfall', 'road',
    ];

    final nonSceneryScore = _scoreTerms(weightedKeywords, nonSceneryTerms);
    final sceneryScore = _scoreTerms(weightedKeywords, sceneryTerms);
    return nonSceneryScore >= 1.0 && nonSceneryScore > sceneryScore * 1.2;
  }

  double _scoreTerms(Map<String, double> weighted, List<String> terms) {
    double score = 0;
    for (final entry in weighted.entries) {
      final k = entry.key;
      final v = entry.value;
      if (terms.any((t) => k.contains(t) || t.contains(k))) {
        score += v;
      }
    }
    return score;
  }

  _SceneMode _detectSceneMode(Map<String, double> weightedKeywords) {
    final urbanScore = _scoreTerms(weightedKeywords, [
      'city', 'urban', 'street', 'traffic', 'downtown', 'car', 'subway',
      'thanh pho', 'thành phố', 'duong pho', 'đường phố',
    ]);
    final natureScore = _scoreTerms(weightedKeywords, [
      'forest', 'jungle', 'tree', 'nature', 'wildlife', 'bird', 'mountain',
      'river', 'waterfall', 'grass', 'field', 'rung', 'rừng',
    ]);
    final beachScore = _scoreTerms(weightedKeywords, [
      'beach', 'ocean', 'sea', 'coast', 'wave', 'shore', 'lake',
      'bien', 'biển', 'song', 'sóng',
    ]);
    final petIndoorScore = _scoreTerms(weightedKeywords, [
      'cat', 'kitten', 'dog', 'puppy', 'pet', 'fur', 'indoor', 'home',
      'room', 'sofa', 'house',
    ]);
    final weatherScore = _scoreTerms(weightedKeywords, [
      'rain', 'storm', 'thunder', 'lightning', 'snow', 'winter',
      'wind', 'fog', 'mist', 'drizzle', 'mua', 'mưa',
    ]);

    final scored = <MapEntry<_SceneMode, double>>[
      MapEntry(_SceneMode.urbanTraffic, urbanScore),
      MapEntry(_SceneMode.natureWild, natureScore),
      MapEntry(_SceneMode.beachWater, beachScore),
      MapEntry(_SceneMode.indoorPet, petIndoorScore),
      MapEntry(_SceneMode.weatherStorm, weatherScore),
    ]..sort((a, b) => b.value.compareTo(a.value));

    final top = scored.first;
    final second = scored[1];
    if (top.value < 0.9 || top.value < second.value * 1.12) {
      return _SceneMode.mixed;
    }
    return top.key;
  }

  List<String> _sceneIncludeTerms(_SceneMode mode) {
    switch (mode) {
      case _SceneMode.urbanTraffic:
        return ['city', 'urban', 'street', 'traffic', 'car', 'downtown', 'cafe', 'office'];
      case _SceneMode.natureWild:
        return ['forest', 'nature', 'tree', 'wildlife', 'bird', 'river', 'mountain', 'wind'];
      case _SceneMode.beachWater:
        return ['beach', 'ocean', 'sea', 'wave', 'coast', 'shore', 'water'];
      case _SceneMode.indoorPet:
        return ['cat', 'dog', 'pet', 'purring', 'home', 'indoor', 'cozy', 'room'];
      case _SceneMode.weatherStorm:
        return ['rain', 'storm', 'thunder', 'wind', 'snow', 'winter', 'mist', 'fog'];
      case _SceneMode.mixed:
        return const [];
    }
  }

  List<String> _sceneExcludeTerms(_SceneMode mode) {
    switch (mode) {
      case _SceneMode.urbanTraffic:
        return ['forest', 'jungle', 'wildlife', 'bird calls', 'natural habitat', 'waterfall', 'ocean'];
      case _SceneMode.natureWild:
        return ['traffic', 'subway', 'downtown', 'nightclub', 'city drive'];
      case _SceneMode.beachWater:
        return ['traffic', 'city street', 'subway', 'office'];
      case _SceneMode.indoorPet:
        return ['bird calls', 'natural habitat', 'forest birds', 'jungle', 'wildlife', 'city traffic'];
      case _SceneMode.weatherStorm:
        return ['festival crowd', 'nightclub', 'sports hype'];
      case _SceneMode.mixed:
        return const [];
    }
  }

  bool _isTextAllowedForScene(String text, _SceneMode mode) {
    if (mode == _SceneMode.mixed) return true;
    final normalized = text.toLowerCase();
    final excludes = _sceneExcludeTerms(mode);
    if (excludes.any((e) => normalized.contains(e))) {
      return false;
    }

    final includes = _sceneIncludeTerms(mode);
    if (includes.isEmpty) return true;
    return includes.any((e) => normalized.contains(e));
  }

  double _sceneMismatchPenalty(String text, _SceneMode mode) {
    if (mode == _SceneMode.mixed) return 0;
    final normalized = text.toLowerCase();
    final excludes = _sceneExcludeTerms(mode);
    double penalty = 0;
    for (final term in excludes) {
      if (normalized.contains(term)) {
        penalty += 1.6;
      }
    }
    return penalty;
  }

  double _textSceneAffinity(String text, Map<String, double> weightedKeywords) {
    final normalized = text.toLowerCase();
    double score = 0;
    for (final entry in weightedKeywords.entries) {
      final key = entry.key.toLowerCase();
      if (key.length < 3) continue;
      if (normalized.contains(key)) {
        score += entry.value;
      }
    }
    return score;
  }

  List<Track> _rankTracksByScene(
    List<Track> tracks,
    Map<String, double> weightedKeywords,
    _SceneMode sceneMode,
  ) {
    final ranked = List<Track>.from(tracks);
    ranked.sort((a, b) {
      final textA = '${a.name} ${a.artistName} ${a.albumName}'.toLowerCase();
      final textB = '${b.name} ${b.artistName} ${b.albumName}'.toLowerCase();
      final scoreA = _textSceneAffinity(textA, weightedKeywords) +
          ((a.popularity > 0 ? a.popularity : 45) / 1000.0) -
          _sceneMismatchPenalty(textA, sceneMode);
      final scoreB = _textSceneAffinity(textB, weightedKeywords) +
          ((b.popularity > 0 ? b.popularity : 45) / 1000.0) -
          _sceneMismatchPenalty(textB, sceneMode);
      return scoreB.compareTo(scoreA);
    });
    return ranked;
  }

  List<AmbientSuggestion> _rankAmbientByScene(
    List<AmbientSuggestion> suggestions,
    Map<String, double> weightedKeywords,
    _SceneMode sceneMode,
  ) {
    final ranked = List<AmbientSuggestion>.from(suggestions);
    ranked.sort((a, b) {
      final textA = '${a.title} ${a.query} ${a.provider}'.toLowerCase();
      final textB = '${b.title} ${b.query} ${b.provider}'.toLowerCase();

      final scoreA = _textSceneAffinity(textA, weightedKeywords) +
          (a.previewUrl?.isNotEmpty == true ? 1.2 : 0.0) -
          _sceneMismatchPenalty(textA, sceneMode);
      final scoreB = _textSceneAffinity(textB, weightedKeywords) +
          (b.previewUrl?.isNotEmpty == true ? 1.2 : 0.0) -
          _sceneMismatchPenalty(textB, sceneMode);
      return scoreB.compareTo(scoreA);
    });
    return ranked;
  }

  /// Jamendo tags for nature scenes → trả về full song không lời
  List<String> _labelsToJamendoTags(Map<String, double> weightedKeywords) {
    bool has(List<String> terms) => _scoreTerms(weightedKeywords, terms) >= 0.7;

    if (has(['storm', 'thunder', 'lightning', 'rain', 'downpour', 'wet', 'umbrella'])) {
      return ['ambient', 'piano', 'cinematic'];
    }
    if (has(['drizzle', 'mist', 'fog', 'cloudy', 'overcast'])) {
      return ['lofi', 'ambient', 'instrumental'];
    }
    if (has(['snow', 'winter', 'ice', 'frost', 'blizzard', 'cold'])) {
      return ['piano', 'classical', 'instrumental'];
    }
    if (has(['sunset', 'sunrise', 'golden', 'dawn', 'dusk'])) {
      return ['chillout', 'ambient', 'instrumental'];
    }
    if (has(['night', 'moon', 'star', 'milky', 'galaxy', 'aurora'])) {
      return ['ambient', 'downtempo', 'lofi'];
    }
    if (has(['beach', 'sea', 'ocean', 'wave', 'coast', 'lake', 'river', 'water'])) {
      return ['ambient', 'instrumental', 'relaxing'];
    }
    if (has(['waterfall', 'stream', 'creek', 'brook'])) {
      return ['nature', 'meditation', 'ambient'];
    }
    if (has(['forest', 'tree', 'nature', 'leaf', 'green', 'grass', 'plant', 'field'])) {
      return ['nature', 'acoustic', 'instrumental'];
    }
    if (has(['jungle', 'tropical', 'rainforest', 'bamboo'])) {
      return ['ethnic', 'nature', 'ambient'];
    }
    if (has(['mountain', 'hill', 'rock', 'cliff', 'valley', 'landscape'])) {
      return ['cinematic', 'instrumental', 'epic'];
    }
    if (has(['desert', 'sand', 'dune', 'canyon'])) {
      return ['cinematic', 'world', 'instrumental'];
    }
    if (has(['flower', 'garden', 'spring', 'blossom'])) {
      return ['acoustic', 'instrumental', 'happy'];
    }
    if (has(['autumn', 'fall', 'maple', 'harvest'])) {
      return ['acoustic', 'folk', 'instrumental'];
    }
    if (has(['sky', 'cloud', 'blue', 'horizon'])) {
      return ['ambient', 'instrumental', 'chillout'];
    }
    if (has(['bird', 'wildlife', 'deer', 'animal', 'safari'])) {
      return ['nature', 'ambient', 'instrumental'];
    }
    if (has(['travel', 'roadtrip', 'journey', 'adventure', 'camping'])) {
      return ['cinematic', 'indie', 'acoustic'];
    }
    if (has(['calm', 'peace', 'serene', 'meditation', 'spa'])) {
      return ['meditation', 'ambient', 'relaxing'];
    }

    return ['instrumental', 'ambient'];
  }

  /// Deezer query cho cảnh người / urban
  String _labelsToDeezerQuery(Map<String, double> weightedKeywords) {
    bool has(List<String> terms) => _scoreTerms(weightedKeywords, terms) >= 0.7;

    if (has(['rain', 'storm', 'umbrella', 'night', 'neon', 'city'])) {
      return 'rainy night lofi chillhop';
    }
    if (has(['sunset', 'sunrise', 'golden', 'beach', 'coast'])) {
      return 'sunset chill tropical house';
    }
    if (has(['snow', 'winter', 'cold', 'fireplace'])) {
      return 'winter cozy piano acoustic';
    }
    if (has(['smile', 'happy', 'joy', 'laugh'])) return 'happy upbeat pop';
    if (has(['sad', 'cry', 'tear'])) return 'sad emotional ballad';
    if (has(['face', 'person', 'selfie', 'portrait'])) return 'pop rnb hits';
    if (has(['city', 'building', 'street', 'road', 'urban'])) return 'urban hip hop beats';
    if (has(['traffic', 'subway', 'downtown', 'crosswalk'])) {
      return 'city drive synthwave electronic';
    }
    if (has(['nightclub', 'dj', 'laser', 'crowd', 'festival'])) {
      return 'festival edm big room';
    }
    if (has(['fashion', 'runway', 'model', 'style'])) {
      return 'fashion house nu disco';
    }
    if (has(['coffee', 'cafe', 'cup', 'drink'])) return 'cafe jazz lofi';
    if (has(['food', 'restaurant', 'meal', 'eat'])) return 'jazz bossa nova';
    if (has(['office', 'laptop', 'desk', 'study', 'book'])) {
      return 'focus instrumental lofi study';
    }
    if (has(['car', 'highway', 'motorcycle', 'roadtrip', 'driving'])) {
      return 'road trip indie pop rock';
    }
    if (has(['sun', 'park', 'picnic', 'outdoor'])) {
      return 'indie feel good pop';
    }
    if (has(['gym', 'sport', 'exercise', 'fitness', 'run'])) return 'workout motivation';
    if (has(['basketball', 'football', 'match', 'stadium'])) {
      return 'sports hype rap';
    }
    if (has(['party', 'dance', 'club', 'celebration'])) return 'dance party edm';
    if (has(['romance', 'couple', 'wedding', 'date', 'love'])) {
      return 'romantic acoustic love songs';
    }
    if (has(['child', 'kid', 'family', 'baby'])) {
      return 'family happy acoustic pop';
    }
    if (has(['dog', 'cat', 'pet', 'animal'])) return 'cute happy pop';
    if (has(['art', 'museum', 'gallery', 'painting'])) {
      return 'neo classical ambient';
    }

    return 'chill popular';
  }

  Future<List<AmbientSuggestion>> _getAmbientSuggestionsFromLabels(
    List<ImageLabel> labels,
  ) async {
    final weightedKeywords = _extractWeightedKeywords(labels);

    return _getAmbientSuggestionsFromWeightedKeywords(weightedKeywords);
  }

  Future<List<AmbientSuggestion>> _getAmbientSuggestionsFromWeightedKeywords(
    Map<String, double> weightedKeywords,
  ) async {

    bool has(List<String> terms) => _scoreTerms(weightedKeywords, terms) >= 0.7;
    final sceneMode = _detectSceneMode(weightedKeywords);
    final birdScore = _scoreTerms(weightedKeywords, [
      'bird',
      'sparrow',
      'eagle',
      'owl',
      'wildlife',
    ]);
    final petScore = _scoreTerms(weightedKeywords, [
      'cat',
      'kitten',
      'dog',
      'puppy',
      'pet',
      'fur',
      'indoor',
      'home',
    ]);
    final preferPetScene = petScore >= 0.8 && birdScore < (petScore * 0.95);

    final suggestions = <AmbientSuggestion>[];

    void add(String title, String query, String provider, IconData icon) {
      if (suggestions.any((s) => s.query == query && s.provider == provider)) {
        return;
      }
      final sceneText = '$title $query $provider';
      if (!_isTextAllowedForScene(sceneText, sceneMode)) {
        return;
      }
      suggestions.add(
        AmbientSuggestion(
          title: title,
          query: query,
          provider: provider,
          icon: icon,
        ),
      );
    }

    // Weather
    if (has(['rain', 'storm', 'thunder', 'lightning', 'drizzle'])) {
      add('Rain Ambience', 'rain ambience loop', 'Freesound', Icons.grain);
      add('Thunder Atmosphere', 'distant thunder rumble', 'Pixabay', Icons.flash_on);
    }
    if (has(['wind', 'breeze', 'gust', 'fog', 'mist'])) {
      add('Wind Through Trees', 'wind in trees ambience', 'Freesound', Icons.air);
    }
    if (has(['snow', 'winter', 'ice', 'cold', 'frost'])) {
      add('Winter Wind', 'cold winter wind ambience', 'Pixabay', Icons.ac_unit);
      add('Fireplace Crackle', 'fireplace crackling', 'Freesound', Icons.local_fire_department);
    }

    // Nature
    if (has(['forest', 'tree', 'wood', 'jungle', 'rainforest'])) {
      add('Forest Birds', 'forest birds dawn chorus', 'Xeno-canto', Icons.forest);
      add('Forest Atmosphere', 'forest ambience leaves wind', 'Freesound', Icons.park);
    }
    if (!preferPetScene && has(['bird', 'sparrow', 'eagle', 'owl', 'wildlife'])) {
      add('Bird Calls', 'bird calls natural habitat', 'Xeno-canto', Icons.flutter_dash);
    }
    if (has(['river', 'stream', 'creek', 'brook', 'waterfall'])) {
      add('Running Water', 'river stream water ambience', 'Freesound', Icons.waves);
    }
    if (has(['beach', 'sea', 'ocean', 'wave', 'coast'])) {
      add('Ocean Waves', 'ocean waves shoreline', 'Pixabay', Icons.surfing);
      add('Seaside Wind', 'seaside wind ambience', 'Freesound', Icons.wb_sunny);
    }

    // Urban / human scene
    if (has(['city', 'street', 'traffic', 'urban', 'downtown'])) {
      add('City Night', 'city night ambience traffic', 'Pixabay', Icons.location_city);
      add('Street Atmosphere', 'street ambience people footsteps', 'Freesound', Icons.directions_walk);
    }
    if (has(['cafe', 'coffee', 'restaurant', 'indoor'])) {
      add('Cafe Background', 'coffee shop ambience chatter', 'Freesound', Icons.local_cafe);
    }
    if (has(['party', 'dance', 'club', 'festival', 'crowd'])) {
      add('Crowd Atmosphere', 'festival crowd ambience', 'Pixabay', Icons.celebration);
    }

    // Pet / indoor scene
    if (has(['cat', 'kitten', 'dog', 'puppy', 'pet', 'fur'])) {
      add('Cat Purring', 'cat purring cozy room', 'Freesound', Icons.pets);
      add('Home Ambience', 'quiet home indoor ambience', 'Pixabay', Icons.home);
      add('Cozy Room Tone', 'cozy room ambience soft', 'Freesound', Icons.weekend);
    }

    // Time of day
    if (has(['night', 'moon', 'star', 'dark'])) {
      add('Night Crickets', 'night crickets ambience', 'Freesound', Icons.nights_stay);
    }
    if (has(['sunrise', 'dawn', 'morning'])) {
      add('Morning Birds', 'morning bird song', 'Xeno-canto', Icons.wb_sunny_outlined);
    }

    // Fallback for scenes not strongly detected
    if (suggestions.isEmpty) {
      if (preferPetScene) {
        add('Cat Purring', 'cat purring cozy room', 'Freesound', Icons.pets);
        add('Home Ambience', 'quiet home indoor ambience', 'Pixabay', Icons.home);
      }
      add('Soft Nature Bed', 'soft nature ambience loop', 'Pixabay', Icons.spa);
      add('Light Rain Texture', 'light rain ambience', 'Freesound', Icons.umbrella);
    }

    final genericTopUp = <AmbientSuggestion>[
      AmbientSuggestion(
        title: 'Rain Ambience',
        query: 'light rain ambience loop',
        provider: 'Freesound',
        icon: Icons.grain,
      ),
      AmbientSuggestion(
        title: 'Forest Atmosphere',
        query: 'forest ambience birds wind',
        provider: 'Freesound',
        icon: Icons.park,
      ),
      AmbientSuggestion(
        title: 'Ocean Waves',
        query: 'ocean waves relaxing',
        provider: 'Pixabay',
        icon: Icons.waves,
      ),
      AmbientSuggestion(
        title: 'Night Ambience',
        query: 'night ambience crickets',
        provider: 'Freesound',
        icon: Icons.nights_stay,
      ),
      AmbientSuggestion(
        title: 'Cafe Background',
        query: 'coffee shop ambience',
        provider: 'Freesound',
        icon: Icons.local_cafe,
      ),
    ];

    for (final item in genericTopUp) {
      if (suggestions.length >= 10) break;
      if (suggestions.any((s) => s.query == item.query && s.provider == item.provider)) {
        continue;
      }
      suggestions.add(item);
    }

    final localSuggestions = suggestions.take(10).toList();

    if (!_ambientSoundService.isConfigured) {
      return _rankAmbientByScene(localSuggestions, weightedKeywords, sceneMode)
          .take(12)
          .toList();
    }

    final queries = localSuggestions.map((e) => e.query).toList();
    final remoteResults = await _ambientSoundService.fetchHybrid(
      queries: queries,
      limit: 24,
    );

    if (remoteResults.isEmpty) {
      return localSuggestions;
    }

    final merged = <AmbientSuggestion>[];

    // Prefer remote entries first because they contain playable preview URLs.
    for (final r in remoteResults) {
      final sceneText = '${r.title} ${r.query} ${r.provider}';
      if (!_isTextAllowedForScene(sceneText, sceneMode)) {
        continue;
      }
      final exists = merged.any(
        (e) => e.previewUrl == r.previewUrl ||
            (e.title == r.title && e.provider == r.provider),
      );
      if (exists) continue;
      merged.add(
        AmbientSuggestion(
          title: r.title,
          query: r.query,
          provider: r.provider,
          icon: _providerIcon(r.provider),
          previewUrl: r.previewUrl,
        ),
      );
      if (merged.length >= 12) break;
    }

    // Top-up with local templates only when remote results are not enough.
    for (final local in localSuggestions) {
      if (merged.length >= 12) break;
      final exists = merged.any(
        (e) =>
            e.title.toLowerCase() == local.title.toLowerCase() ||
            (e.query == local.query && e.provider == local.provider),
      );
      if (!exists) {
        merged.add(local);
      }
    }

    return _rankAmbientByScene(merged, weightedKeywords, sceneMode)
      .take(12)
      .toList();
  }

  IconData _providerIcon(String provider) {
    final normalized = provider.toLowerCase();
    if (normalized.contains('pixabay')) return Icons.waves;
    if (normalized.contains('freesound')) return Icons.graphic_eq;
    if (normalized.contains('xeno')) return Icons.flutter_dash;
    return Icons.surround_sound;
  }

  Future<List<Track>> _getRecommendationsFromWeightedKeywords(
    Map<String, double> weightedKeywords,
  ) async {
    final sceneMode = _detectSceneMode(weightedKeywords);
    final topKeywords = weightedKeywords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    debugPrint(
      '🔍 weighted keywords: ${topKeywords.take(8).map((e) => '${e.key}:${e.value.toStringAsFixed(2)}').join(', ')}',
    );

    const natureTerms = [
      'beach', 'sea', 'ocean', 'wave', 'coast', 'water', 'lake', 'river',
      'waterfall', 'stream', 'creek', 'brook',
      'forest', 'tree', 'nature', 'leaf', 'green', 'grass', 'plant',
      'jungle', 'rainforest', 'tropical',
      'mountain', 'hill', 'rock', 'cliff', 'valley',
      'sunset', 'sunrise', 'golden', 'dusk', 'dawn',
      'sky', 'cloud', 'horizon',
      'rain', 'storm', 'thunder', 'lightning', 'fog', 'mist', 'drizzle',
      'snow', 'winter', 'ice', 'cold', 'frost',
      'desert', 'sand', 'dune', 'canyon',
      'flower', 'garden', 'spring', 'blossom', 'field',
      'autumn', 'fall',
      'night', 'star', 'moon', 'galaxy',
      'bird', 'wildlife', 'landscape', 'scenery', 'countryside',
      'camping', 'adventure', 'trail', 'hiking', 'serene', 'calm',
      'mưa', 'mua', 'biển', 'bien', 'rừng', 'rung', 'chim', 'đêm', 'dem',
      'gió', 'gio', 'sóng', 'song', 'suối', 'suoi', 'thác', 'thac',
      'hoàng hôn', 'hoang hon', 'tuyết', 'tuyet', 'thư giãn', 'thu gian',
    ];
    const urbanTerms = [
      'person', 'people', 'human', 'man', 'woman', 'face', 'selfie', 'portrait',
      'city', 'building', 'street', 'road', 'traffic', 'urban',
      'subway', 'downtown', 'crosswalk',
      'indoor', 'room', 'office', 'table', 'wall',
      'party', 'dance', 'club', 'fashion', 'shopping', 'festival', 'dj',
      'car', 'highway', 'motorcycle',
      'cafe', 'coffee', 'restaurant', 'meal',
      'gym', 'fitness', 'stadium', 'sport',
      'wedding', 'couple', 'family',
      'thành phố', 'thanh pho', 'đường phố', 'duong pho', 'quán cà phê', 'cafe',
      'tập trung', 'tap trung', 'study', 'focus', 'workout',
    ];

    final natureScore = _scoreTerms(weightedKeywords, natureTerms);
    final urbanScore = _scoreTerms(weightedKeywords, urbanTerms);
    final preferNature = natureScore >= 1.0 && natureScore >= urbanScore * 1.15;
    debugPrint(
      '🌄 text/scene scores => nature: ${natureScore.toStringAsFixed(2)}, urban: ${urbanScore.toStringAsFixed(2)}, preferNature: $preferNature',
    );

    final preferNatureScene = sceneMode == _SceneMode.natureWild ||
        sceneMode == _SceneMode.beachWater ||
        sceneMode == _SceneMode.weatherStorm;

    if ((preferNature || preferNatureScene) && JamendoService().isConfigured) {
      final tags = _labelsToJamendoTags(weightedKeywords);
      debugPrint('🌿 Nature scene → Jamendo tags: $tags');
      final tracks = await JamendoService().getInstrumentalTracks(tags: tags, limit: 35);
      if (tracks.isNotEmpty) {
        return _rankTracksByScene(tracks, weightedKeywords, sceneMode)
            .where((t) => _isTextAllowedForScene('${t.name} ${t.artistName} ${t.albumName}', sceneMode))
            .take(15)
            .toList();
      }
    }

    final query = _labelsToDeezerQuery(weightedKeywords);
    debugPrint('🎵 Urban/people scene → Deezer: "$query"');
    try {
      final tracks = await DeezerService().searchTracks(query, limit: 35);
      if (tracks.isNotEmpty) {
        return _rankTracksByScene(tracks, weightedKeywords, sceneMode)
            .where((t) => _isTextAllowedForScene('${t.name} ${t.artistName} ${t.albumName}', sceneMode))
            .take(15)
            .toList();
      }
      final fallback = await DeezerService().searchTracks('chill', limit: 35);
      return _rankTracksByScene(fallback, weightedKeywords, sceneMode)
          .where((t) => _isTextAllowedForScene('${t.name} ${t.artistName} ${t.albumName}', sceneMode))
          .take(15)
          .toList();
    } catch (e) {
      debugPrint('Error fetching tracks: $e');
      return [];
    }
  }

  /// Maps ML Kit labels → Jamendo (nature/scenery) or Deezer (people/urban)
  Future<List<Track>> _getRecommendationsFromLabels(List<ImageLabel> labels) async {
    if (labels.isEmpty) {
      final fallback = await DeezerService().searchTracks('chill popular', limit: 30);
      return fallback.take(15).toList();
    }

    final weightedKeywords = _extractWeightedKeywords(labels);
    return _getRecommendationsFromWeightedKeywords(weightedKeywords);
  }

  void _addBotMessage(String text) {
    final message = ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
    unawaited(_persistMessage(message));
  }

  void _addUserMessage(String text) {
    final message = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
    unawaited(_persistMessage(message));
  }

  Future<void> _addSceneRecommendationFromText(String text) async {
    final weightedKeywords = _extractWeightedKeywordsFromText(text);
    final tracks = await _getRecommendationsFromWeightedKeywords(weightedKeywords);
    final ambience = await _getAmbientSuggestionsFromWeightedKeywords(weightedKeywords);

    final topKeywords = weightedKeywords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final detected = topKeywords.take(4).map((e) => e.key).join(', ');

    String response = '';
    if (detected.isNotEmpty) {
      response += _textSceneDetectedMessage(detected);
    }

    setState(() {
      final musicMessage = ChatMessage(
        text: '$response$_musicSuggestionsHeader\n\n$_textSceneMusicMessage',
        isUser: false,
        timestamp: DateTime.now(),
        tracks: tracks,
      );
      _messages.add(musicMessage);
      unawaited(_persistMessage(musicMessage));

      if (ambience.isNotEmpty) {
        final ambienceMessage = ChatMessage(
          text: '$_ambientSuggestionsHeader\n\n$_textSceneAmbientMessage',
          isUser: false,
          timestamp: DateTime.now(),
          ambienceSuggestions: ambience,
        );
        _messages.add(ambienceMessage);
        unawaited(_persistMessage(ambienceMessage));
      }
    });
    _scrollToBottom();

    if (tracks.isNotEmpty) {
      try {
        await AudioPlayerService.instance.setQueue(tracks, startIndex: 0);
        await AudioPlayerService.instance.play();
      } catch (e) {
        debugPrint('❌ Error auto-playing text-based track: $e');
      }
    }
  }

  Map<String, double> _extractWeightedKeywordsFromText(String input) {
    final weighted = <String, double>{};
    final lower = input.toLowerCase();

    const phraseWeights = {
      'trời mưa': 1.6,
      'troi mua': 1.6,
      'mưa rào': 1.3,
      'mua rao': 1.3,
      'mưa lớn': 1.4,
      'mua lon': 1.4,
      'sấm chớp': 1.4,
      'sam chop': 1.4,
      'mưa': 1.2,
      'mua': 1.2,
      'rain': 1.2,
      'rainy': 1.2,
      'storm': 1.2,
      'thunder': 1.2,
      'lightning': 1.1,
      'biển': 1.3,
      'bien': 1.3,
      'beach': 1.3,
      'ocean': 1.3,
      'seaside': 1.2,
      'coast': 1.2,
      'shore': 1.1,
      'rừng': 1.3,
      'rung': 1.3,
      'forest': 1.3,
      'jungle': 1.2,
      'rainforest': 1.2,
      'thiên nhiên': 1.2,
      'thien nhien': 1.2,
      'nature': 1.2,
      'chim': 1.1,
      'bird': 1.1,
      'birdsong': 1.1,
      'wildlife': 1.0,
      'đêm': 1.0,
      'dem': 1.0,
      'night': 1.0,
      'midnight': 1.0,
      'moonlight': 1.0,
      'thư giãn': 1.0,
      'thu gian': 1.0,
      'relax': 1.0,
      'chill': 1.0,
      'calm': 1.0,
      'peaceful': 1.0,
      'meditation': 1.0,
      'tập trung': 1.0,
      'tap trung': 1.0,
      'study': 1.0,
      'focus': 1.0,
      'deep focus': 1.0,
      'cafe': 1.0,
      'coffee': 1.0,
      'quán cà phê': 1.0,
      'quan ca phe': 1.0,
      'thành phố': 1.1,
      'thanh pho': 1.1,
      'city': 1.1,
      'đường phố': 1.1,
      'duong pho': 1.1,
      'street': 1.1,
      'urban': 1.1,
      'downtown': 1.1,
      'traffic': 1.0,
      'tuyết': 1.1,
      'tuyet': 1.1,
      'snow': 1.1,
      'winter': 1.1,
      'cold': 1.0,
      'gió': 1.0,
      'gio': 1.0,
      'wind': 1.0,
      'breeze': 0.9,
      'fog': 0.9,
      'mist': 0.9,
      'sóng': 1.2,
      'song': 1.2,
      'wave': 1.2,
      'suối': 1.1,
      'suoi': 1.1,
      'stream': 1.1,
      'thác': 1.1,
      'thac': 1.1,
      'waterfall': 1.1,
      'river': 1.1,
      'lake': 1.1,
      'sunset': 1.0,
      'hoàng hôn': 1.0,
      'hoang hon': 1.0,
      'morning': 0.9,
      'bình minh': 0.9,
      'binh minh': 0.9,
      'sunrise': 0.9,
      'dawn': 0.9,
      'dusk': 0.9,
      'road trip': 1.0,
      'roadtrip': 1.0,
      'driving': 1.0,
      'workout': 1.0,
      'gym': 1.0,
      'run': 1.0,
      'jogging': 1.0,
      'yoga': 0.9,
      'romantic': 0.9,
      'love': 0.9,
      'cozy': 0.9,
      'buồn': 0.9,
      'buon': 0.9,
      'sad': 0.9,
      'happy': 0.9,
      'vui': 0.9,
      'festival': 0.9,
      'party': 0.9,
      'travel': 0.9,
      'adventure': 0.9,
    };

    for (final entry in phraseWeights.entries) {
      if (lower.contains(entry.key)) {
        weighted[entry.key] = (weighted[entry.key] ?? 0) + entry.value;
      }
    }

    final normalized = lower.replaceAll(
      RegExp(r'[^\p{L}0-9\s]', unicode: true),
      ' ',
    );
    final tokens = normalized.split(RegExp(r'\s+')).where((t) => t.length >= 2);
    for (final token in tokens) {
      weighted[token] = (weighted[token] ?? 0) + 0.35;
    }

    _applySceneAliasBoost(weighted);
    _applyLearnedKeywordBoost(weighted);

    return weighted;
  }

  bool _looksLikeSceneTextRequest(String input) {
    final weightedKeywords = _extractWeightedKeywordsFromText(input);
    const sceneTerms = [
      'mưa', 'mua', 'rain', 'rainy', 'storm', 'biển', 'bien', 'beach',
      'ocean', 'forest', 'rừng', 'rung', 'bird', 'chim', 'night', 'đêm',
      'dem', 'city', 'thành phố', 'thanh pho', 'cafe', 'coffee', 'snow',
      'tuyết', 'tuyet', 'wind', 'gió', 'gio', 'wave', 'sóng', 'song',
      'waterfall', 'thác', 'thac', 'stream', 'suối', 'suoi', 'sunset',
      'hoàng hôn', 'hoang hon', 'focus', 'study', 'relax', 'chill',
      'nature', 'thiên nhiên', 'thien nhien', 'urban', 'downtown',
      'traffic', 'winter', 'fog', 'mist', 'river', 'lake', 'sunrise',
      'dawn', 'dusk', 'roadtrip', 'driving', 'gym', 'yoga', 'workout',
      'meditation', 'calm', 'peaceful', 'cozy', 'romantic', 'sad', 'happy',
    ];
    const requestTerms = [
      'muốn', 'muon', 'nghe', 'hear', 'listen', 'want', 'today', 'hôm nay',
      'hom nay', 'related', 'liên quan', 'lien quan',
    ];

    final sceneScore = _scoreTerms(weightedKeywords, sceneTerms);
    final requestScore = _scoreTerms(weightedKeywords, requestTerms);
    return sceneScore >= 0.8 || (sceneScore >= 0.5 && requestScore >= 0.5);
  }

  Future<void> _pickImageFromGallery() async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null || !mounted) return;

      if (_imageLabeler == null) {
        final options = ImageLabelerOptions(confidenceThreshold: 0.35);
        _imageLabeler = ImageLabeler(options: options);
      }

      await _handleImageAnalysis(imagePath: image.path);
    } catch (e) {
      debugPrint('Error picking image from chatbot: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('photo_pick_unsupported'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
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
    Future.delayed(const Duration(milliseconds: 900), () async {
      if (!mounted) return;

      setState(() {
        _isTyping = false;
      });

      if (_looksLikeSceneTextRequest(text)) {
        await _addSceneRecommendationFromText(text);
        return;
      }

      String response = _generateResponse(text);
      _addBotMessage(response);
    });
  }

  String _generateResponse(String input) {
    final lowerInput = input.toLowerCase();

    if (lowerInput.contains('recommend') || lowerInput.contains('suggest')) {
      return _isVietnamese
          ? '🎵 Dựa trên thói quen nghe nhạc của bạn, tôi có thể gợi ý những bài hát phù hợp.\n\nBạn có muốn tôi tạo luôn một playlist không?'
          : '🎵 Based on your listening history, I can recommend personalized songs for you.\n\nWould you like me to create a playlist?';
    } else if (lowerInput.contains('trending') ||
        lowerInput.contains('popular')) {
      return _isVietnamese
          ? '🔥 Tôi có thể gợi ý cho bạn những bài đang thịnh hành.\n\nHãy thử tìm kiếm để khám phá nhạc hot hôm nay!'
          : '🔥 I can show you trending songs.\n\nTap the search icon to discover popular music!';
    } else if (lowerInput.contains('workout') ||
        lowerInput.contains('exercise')) {
      return _isVietnamese
          ? '💪 Tôi đã chuẩn bị một playlist đầy năng lượng cho lúc tập luyện!\n\n• Nhịp 150-180 BPM\n• Thời lượng khoảng 45 phút\n• Giai điệu tạo động lực\n\nSẵn sàng vào buổi tập chưa?'
          : '💪 I\'ve created a high-energy workout playlist for you!\n\n• 150-180 BPM tracks\n• 45 minutes duration\n• Motivational beats\n\nReady to crush your workout?';
    } else if (lowerInput.contains('like') || lowerInput.contains('similar')) {
      return _isVietnamese
          ? '✨ Tôi có thể tìm những bài hát có cảm giác giống với bài bạn thích.\n\nBạn có muốn tôi thêm chúng vào hàng chờ không?'
          : '✨ I can find songs similar to your favorites.\n\nShall I add these to your queue?';
    } else if (lowerInput.contains('playlist')) {
      return _isVietnamese
          ? '📝 Tôi có thể giúp bạn tạo playlist. Bạn đang muốn mood hay chủ đề nào?\n\n• Chill thư giãn\n• Tiệc tùng sôi động\n• Tập trung học tập\n• Road trip'
          : '📝 I can help you create a playlist! What mood or theme are you looking for?\n\n• Chill vibes\n• Party hits\n• Focus & Study\n• Road trip';
    } else if (lowerInput.contains('sleep') || lowerInput.contains('relax')) {
      return _isVietnamese
          ? '😴 Quá hợp để thư giãn:\n\nTôi đã chuẩn bị một playlist êm dịu với âm thanh môi trường và giai điệu nhẹ nhàng. Bạn có muốn tôi đặt luôn hẹn giờ ngủ không?'
          : '😴 Perfect for relaxation:\n\nI\'ve prepared a calming playlist with ambient sounds and soft melodies. Should I also set a sleep timer?';
    } else {
      return _isVietnamese
          ? 'Tôi có thể giúp bạn gợi ý nhạc, tạo playlist, tìm mood theo thời tiết hoặc khung cảnh, và nhiều hơn nữa. Bạn muốn khám phá gì? 🎧'
          : 'I\'m here to help you with music recommendations, playlist creation, artist info, and more! What would you like to explore? 🎧';
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'bot_name'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'bot_subtitle'.tr(),
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
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
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _pickImageFromGallery,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isPickingImage
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.photo_library_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
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
                  if (message.ambienceSuggestions != null &&
                      message.ambienceSuggestions!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'ambient_sounds'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...message.ambienceSuggestions!.map((ambient) {
                      final previewUrl = ambient.previewUrl?.trim() ?? '';
                      final hasPreview = previewUrl.isNotEmpty;
                      final isPlayingThis =
                          hasPreview && _ambientPreviewUrl == previewUrl && _ambientPreviewPlayer.playing;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(ambient.icon, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ambient.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${ambient.provider}: ${ambient.query}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (hasPreview)
                                    Text(
                                      _isVietnamese
                                          ? 'Có bản xem trước âm thanh'
                                          : 'Preview available',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: hasPreview ? () => _toggleAmbientPreview(ambient) : null,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: hasPreview
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : Colors.grey.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPlayingThis ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 20,
                                  color: hasPreview ? AppColors.primary : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  // Display Tracks after ambience so ambient suggestions are visible immediately
                  if (message.tracks != null && message.tracks!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...message.tracks!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final track = entry.value;
                      return GestureDetector(
                        onTap: () async {
                          try {
                            final allTracks = message.tracks!;
                            await AudioPlayerService.instance.setQueue(
                              allTracks,
                              startIndex: index,
                            );
                            await AudioPlayerService.instance.play();
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NowPlayingScreen(),
                              ),
                            );
                          } catch (e) {
                            debugPrint('❌ Play error: $e');
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('cannot_play_track'.tr()),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
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
                    }),
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
          Text(
            'quick_suggestions'.tr(),
            style: const TextStyle(
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
          GestureDetector(
            onTap: _pickImageFromGallery,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.image_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'chat_hint'.tr(),
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
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
  final List<AmbientSuggestion>? ambienceSuggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
    this.tracks,
    this.ambienceSuggestions,
  });
}

class AmbientSuggestion {
  final String title;
  final String query;
  final String provider;
  final IconData icon;
  final String? previewUrl;

  const AmbientSuggestion({
    required this.title,
    required this.query,
    required this.provider,
    required this.icon,
    this.previewUrl,
  });
}
