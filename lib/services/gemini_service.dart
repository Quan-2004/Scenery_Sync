import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static final GeminiService _instance = GeminiService._();
  factory GeminiService() => _instance;
  GeminiService._();

  GenerativeModel? _model;
  ChatSession? _chat;

  bool get isConfigured => _apiKey.isNotEmpty;

  GenerativeModel _getModel() {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.8,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
    return _model!;
  }

  ChatSession _getChat() {
    _chat ??= _getModel().startChat();
    return _chat!;
  }

  /// Send a message and get AI response.
  Future<String> sendMessage(String message) async {
    if (!isConfigured) throw Exception('Gemini API key is not configured');
    try {
      final chat = _getChat();
      final response = await chat.sendMessage(Content.text(message));
      final text = response.text;
      if (text == null || text.isEmpty) throw Exception('Empty response from Gemini');
      return text;
    } catch (e) {
      debugPrint('❌ Gemini API error: $e');
      rethrow;
    }
  }

  /// Find song name from lyrics using Gemini.
  Future<String> findSongByLyrics(String lyrics, {bool isVietnamese = false}) async {
    if (!isConfigured) throw Exception('Gemini API key is not configured');
    try {
      final prompt = isVietnamese
          ? 'Người dùng nhớ một đoạn lời bài hát nhưng quên tên bài. '
            'Đây là lời họ nhớ: "$lyrics"\n\n'
            'Hãy tìm tên bài hát và ca sĩ. Trả lời ngắn gọn theo format:\n'
            '🎵 Tên bài: [tên bài hát]\n'
            '🎤 Ca sĩ: [tên ca sĩ]\n'
            '💡 Thông tin thêm: [1-2 câu ngắn về bài hát]\n\n'
            'Nếu không chắc chắn, hãy đưa ra 2-3 gợi ý có thể. '
            'Nếu hoàn toàn không biết, hãy nói rõ.'
          : 'The user remembers some lyrics but forgot the song name. '
            'Here are the lyrics they remember: "$lyrics"\n\n'
            'Please find the song name and artist. Reply briefly in this format:\n'
            '🎵 Song: [song name]\n'
            '🎤 Artist: [artist name]\n'
            '💡 Info: [1-2 short sentences about the song]\n\n'
            'If unsure, suggest 2-3 possibilities. '
            'If you truly don\'t know, say so clearly.';

      final model = _getModel();
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.isEmpty) throw Exception('Empty response');
      return text;
    } catch (e) {
      debugPrint('❌ Gemini lyrics search error: $e');
      rethrow;
    }
  }

  /// Analyze user mood from text and suggest music search terms.
  /// Returns a response with mood analysis and Deezer search query.
  Future<MoodAnalysisResult> analyzeMoodForMusic(String text, {bool isVietnamese = false}) async {
    if (!isConfigured) throw Exception('Gemini API key is not configured');
    try {
      final prompt = isVietnamese
          ? 'Phân tích tâm trạng từ tin nhắn sau: "$text"\n\n'
            'Trả lời theo FORMAT CHÍNH XÁC này:\n'
            'MOOD: [tên mood bằng tiếng Anh, ví dụ: sad, happy, tired, energetic, romantic, lonely, angry, peaceful, nostalgic]\n'
            'SEARCH: [cụm từ tìm kiếm nhạc trên Deezer phù hợp mood, bằng tiếng Anh, 3-5 từ]\n'
            'MESSAGE: [1-2 câu phản hồi thân thiện bằng tiếng Việt, đồng cảm với tâm trạng user]\n'
          : 'Analyze the mood from this message: "$text"\n\n'
            'Reply in this EXACT FORMAT:\n'
            'MOOD: [mood name, e.g: sad, happy, tired, energetic, romantic, lonely, angry, peaceful, nostalgic]\n'
            'SEARCH: [Deezer music search query matching this mood, 3-5 words in English]\n'
            'MESSAGE: [1-2 friendly sentences empathizing with the user\'s mood]\n';

      final model = _getModel();
      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';

      final mood = _extractField(raw, 'MOOD') ?? 'chill';
      final search = _extractField(raw, 'SEARCH') ?? 'chill relaxing music';
      final message = _extractField(raw, 'MESSAGE') ?? raw;

      return MoodAnalysisResult(mood: mood, searchQuery: search, message: message);
    } catch (e) {
      debugPrint('❌ Gemini mood analysis error: $e');
      rethrow;
    }
  }

  /// Detect if the input looks like song lyrics (without explicit keywords).
  Future<bool> detectIfLyrics(String text) async {
    if (!isConfigured) return false;
    // Quick heuristic: lyrics tend to be 5+ words, often poetic
    final wordCount = text.trim().split(RegExp(r'\s+')).length;
    if (wordCount < 4 || wordCount > 100) return false;

    try {
      final prompt = 'Does this text look like song lyrics? '
          'Answer ONLY "YES" or "NO".\n\n'
          'Text: "$text"';
      final model = _getModel();
      final response = await model.generateContent([Content.text(prompt)]);
      final answer = (response.text ?? '').trim().toUpperCase();
      return answer.startsWith('YES');
    } catch (e) {
      debugPrint('❌ Gemini lyrics detection error: $e');
      return false;
    }
  }

  /// Generate a music quiz clue using Gemini.
  Future<QuizQuestion> generateQuizQuestion({bool isVietnamese = false}) async {
    if (!isConfigured) throw Exception('Gemini API key is not configured');
    try {
      final prompt = isVietnamese
          ? 'Tạo một câu đố âm nhạc. Chọn một bài hát nổi tiếng (có thể Việt Nam hoặc quốc tế).\n\n'
            'Trả lời theo FORMAT CHÍNH XÁC:\n'
            'SONG: [tên bài hát gốc]\n'
            'ARTIST: [tên ca sĩ]\n'
            'HINT1: [gợi ý 1 - mô tả chủ đề/nội dung bài hát, KHÔNG đề cập tên bài]\n'
            'HINT2: [gợi ý 2 - một đoạn lyrics ngắn 4-8 từ]\n'
            'HINT3: [gợi ý 3 - tên ca sĩ và năm phát hành]\n'
            'FUN_FACT: [1 fun fact thú vị về bài hát]\n'
          : 'Create a music quiz. Pick a famous song (international or popular).\n\n'
            'Reply in this EXACT FORMAT:\n'
            'SONG: [original song name]\n'
            'ARTIST: [artist name]\n'
            'HINT1: [hint 1 - describe the theme/topic, DO NOT mention the song title]\n'
            'HINT2: [hint 2 - short lyrics snippet, 4-8 words]\n'
            'HINT3: [hint 3 - artist name and release year]\n'
            'FUN_FACT: [1 interesting fun fact about the song]\n';

      final model = _getModel();
      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';

      return QuizQuestion(
        songName: _extractField(raw, 'SONG') ?? 'Unknown Song',
        artistName: _extractField(raw, 'ARTIST') ?? 'Unknown Artist',
        hint1: _extractField(raw, 'HINT1') ?? 'A popular song',
        hint2: _extractField(raw, 'HINT2') ?? '...',
        hint3: _extractField(raw, 'HINT3') ?? 'A famous artist',
        funFact: _extractField(raw, 'FUN_FACT') ?? '',
      );
    } catch (e) {
      debugPrint('❌ Gemini quiz generation error: $e');
      rethrow;
    }
  }

  /// Generate Song of the Day recommendation.
  Future<SongOfDayResult> generateSongOfDay({
    required int hour,
    bool isVietnamese = false,
  }) async {
    if (!isConfigured) throw Exception('Gemini API key is not configured');
    try {
      final timeOfDay = hour < 6
          ? 'late night'
          : hour < 12
              ? 'morning'
              : hour < 18
                  ? 'afternoon'
                  : 'evening';

      final prompt = isVietnamese
          ? 'Bây giờ là buổi $timeOfDay. Gợi ý 1 bài hát hay phù hợp với thời điểm này.\n\n'
            'Trả lời theo FORMAT CHÍNH XÁC:\n'
            'SONG: [tên bài hát]\n'
            'ARTIST: [tên ca sĩ]\n'
            'REASON: [1-2 câu ngắn giải thích tại sao bài này hợp với thời điểm hiện tại]\n'
          : 'It\'s currently $timeOfDay. Suggest 1 great song for this time of day.\n\n'
            'Reply in this EXACT FORMAT:\n'
            'SONG: [song name]\n'
            'ARTIST: [artist name]\n'
            'REASON: [1-2 short sentences explaining why this song fits the current time]\n';

      final model = _getModel();
      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';

      return SongOfDayResult(
        songName: _extractField(raw, 'SONG') ?? 'Unknown',
        artistName: _extractField(raw, 'ARTIST') ?? 'Unknown',
        reason: _extractField(raw, 'REASON') ?? '',
      );
    } catch (e) {
      debugPrint('❌ Gemini Song of Day error: $e');
      rethrow;
    }
  }

  /// Helper to extract structured fields from Gemini response.
  String? _extractField(String text, String fieldName) {
    final pattern = RegExp(
      '$fieldName:\\s*(.+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    if (match != null) {
      String value = match.group(1)?.trim() ?? '';
      // Clean up markdown/formatting
      value = value.replaceAll(RegExp(r'[*_`\[\]]'), '').trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  /// Extract song name from Gemini's lyrics response for searching.
  String? extractSongName(String geminiResponse) {
    final patterns = [
      RegExp(r'(?:Song|Tên bài)[:\s]+(.+)', caseSensitive: false),
      RegExp(r'🎵\s*(?:Song|Tên bài)[:\s]+(.+)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(geminiResponse);
      if (match != null) {
        String name = match.group(1)?.trim() ?? '';
        name = name.replaceAll(RegExp(r'[*_`\[\]]'), '').trim();
        name = name.replaceAll(RegExp(r'\s*[-–]\s*.*$'), '').trim();
        name = name.replaceAll(RegExp(r'\s+by\s+.*$', caseSensitive: false), '').trim();
        if (name.isNotEmpty && name.length < 100) return name;
      }
    }
    return null;
  }

  /// Extract artist name from Gemini's lyrics response.
  String? extractArtistName(String geminiResponse) {
    final patterns = [
      RegExp(r'(?:Artist|Ca sĩ)[:\s]+(.+)', caseSensitive: false),
      RegExp(r'🎤\s*(?:Artist|Ca sĩ)[:\s]+(.+)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(geminiResponse);
      if (match != null) {
        String name = match.group(1)?.trim() ?? '';
        name = name.replaceAll(RegExp(r'[*_`\[\]]'), '').trim();
        if (name.isNotEmpty && name.length < 100) return name;
      }
    }
    return null;
  }

  /// Reset chat history to start fresh.
  void resetChat() {
    _chat = null;
  }

  static const String _systemPrompt = '''
You are a friendly and knowledgeable music assistant for the Scenery Sync app.
Scenery Sync is a mobile app that recommends music and ambient sounds based on scenery photos and user mood.

Your capabilities:
- Recommend music based on mood, genre, or activity
- Help users discover new artists and songs
- Provide information about songs, artists, and music genres
- Help find songs when users remember lyrics but forgot the title
- Suggest playlists for different occasions
- Play music quiz games
- Analyze user mood and suggest matching music
- Answer general questions about the app

Guidelines:
- Be concise and helpful. Use emojis sparingly for warmth.
- If the user writes in Vietnamese, respond in Vietnamese.
- If the user writes in English, respond in English.
- Keep responses under 200 words unless the user asks for detailed information.
- When suggesting songs, provide song name and artist.
- Be enthusiastic about music but not overly so.
- If unsure about something, be honest and say so.
- Never make up fake song names or artists.
''';
}

/// Result of mood analysis from Gemini.
class MoodAnalysisResult {
  final String mood;
  final String searchQuery;
  final String message;

  const MoodAnalysisResult({
    required this.mood,
    required this.searchQuery,
    required this.message,
  });
}

/// Quiz question generated by Gemini.
class QuizQuestion {
  final String songName;
  final String artistName;
  final String hint1;
  final String hint2;
  final String hint3;
  final String funFact;

  const QuizQuestion({
    required this.songName,
    required this.artistName,
    required this.hint1,
    required this.hint2,
    required this.hint3,
    required this.funFact,
  });
}

/// Song of the Day result from Gemini.
class SongOfDayResult {
  final String songName;
  final String artistName;
  final String reason;

  const SongOfDayResult({
    required this.songName,
    required this.artistName,
    required this.reason,
  });
}
