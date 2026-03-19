import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AmbientSoundResult {
  final String title;
  final String provider;
  final String query;
  final String? previewUrl;

  const AmbientSoundResult({
    required this.title,
    required this.provider,
    required this.query,
    this.previewUrl,
  });
}

class AmbientSoundService {
  static const String _pixabayApiKey = String.fromEnvironment('PIXABAY_API_KEY');
  static const String _freesoundApiKey = String.fromEnvironment('FREESOUND_API_KEY');
  static final Map<String, List<AmbientSoundResult>> _pixabayCache = {};
  static DateTime? _lastPixabayRequestAt;

  bool get hasPixabay => _pixabayApiKey.isNotEmpty;
  bool get hasFreesound => _freesoundApiKey.isNotEmpty;
  bool get isConfigured => hasPixabay || hasFreesound;

  Future<List<AmbientSoundResult>> fetchHybrid({
    required List<String> queries,
    int limit = 20,
  }) async {
    final normalizedQueries = queries
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toSet()
        .toList();

    if (normalizedQueries.isEmpty || !isConfigured) {
      return [];
    }

    final scopedQueries = normalizedQueries.take(6).toList();
    final pixabayQueries = scopedQueries.take(3).toSet();
    final buckets = <List<AmbientSoundResult>>[];

    for (final query in scopedQueries) {
      final bucket = <AmbientSoundResult>[];
      if (hasPixabay && pixabayQueries.contains(query)) {
        final fromPixabay = await _searchPixabay(query, perQueryLimit: 6);
        _appendUnique(bucket, fromPixabay, cap: 12);
      }
      if (hasFreesound) {
        final fromFreesound = await _searchFreesound(query, perQueryLimit: 6);
        _appendUnique(bucket, fromFreesound, cap: 12);
      }
      if (bucket.isNotEmpty) {
        buckets.add(bucket);
      }
    }

    if (buckets.isEmpty) return [];

    final results = <AmbientSoundResult>[];
    var index = 0;
    while (results.length < limit) {
      var addedInRound = false;
      for (final bucket in buckets) {
        if (index >= bucket.length) continue;
        _appendUnique(results, [bucket[index]], cap: limit);
        addedInRound = true;
        if (results.length >= limit) break;
      }
      if (!addedInRound) break;
      index++;
    }

    return results;
  }

  void _appendUnique(
    List<AmbientSoundResult> target,
    List<AmbientSoundResult> incoming, {
    required int cap,
  }) {
    for (final item in incoming) {
      if (target.length >= cap) break;
      final duplicate = target.any(
        (e) => e.previewUrl == item.previewUrl ||
            (e.title == item.title && e.provider == item.provider),
      );
      if (!duplicate) {
        target.add(item);
      }
    }
  }

  Future<List<AmbientSoundResult>> _searchPixabay(
    String query, {
    int perQueryLimit = 5,
  }) async {
    final normalizedQuery = _normalizePixabayQuery(query);
    final firstTry = await _searchPixabayWithQuery(
      query: normalizedQuery,
      originalQuery: query,
      perQueryLimit: perQueryLimit,
    );
    if (firstTry.isNotEmpty || normalizedQuery == query.trim()) {
      return firstTry;
    }

    return _searchPixabayWithQuery(
      query: query.trim(),
      originalQuery: query,
      perQueryLimit: perQueryLimit,
    );
  }

  Future<List<AmbientSoundResult>> _searchPixabayWithQuery({
    required String query,
    required String originalQuery,
    required int perQueryLimit,
  }) async {
    final cacheKey = '${query.toLowerCase()}|$perQueryLimit';
    final cached = _pixabayCache[cacheKey];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      await _respectPixabayThrottle();
      final uri = Uri.https('pixabay.com', '/api/sounds/', {
        'key': _pixabayApiKey,
        'q': query,
        'per_page': '$perQueryLimit',
        'safesearch': 'true',
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        if (response.statusCode == 429) {
          debugPrint('Pixabay ambient search rate-limited (429) for query: $query');
        }
        return [];
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final hits = (body['hits'] as List?) ?? const [];

      final parsed = hits.map<AmbientSoundResult>((raw) {
        final item = raw as Map<String, dynamic>;
        final title =
            (item['tags'] ?? item['type'] ?? item['id'] ?? 'Pixabay Sound')
                .toString();

        final dynamic previewsRaw = item['previews'];
        String? preview;
        if (previewsRaw is Map<String, dynamic>) {
          preview = (previewsRaw['preview-hq-mp3'] ??
                  previewsRaw['preview-lq-mp3'] ??
                  previewsRaw['preview_hq_mp3'] ??
                  previewsRaw['preview_lq_mp3'] ??
                  previewsRaw['mp3'])
              ?.toString();
        }

        final dynamic audioRaw = item['audio'];
        if ((preview ?? '').isEmpty && audioRaw is Map<String, dynamic>) {
          preview = (audioRaw['mp3'] ?? audioRaw['url'])?.toString();
        }
        preview ??= (item['previewURL'] ?? item['previewUrl'] ?? item['url'])
            ?.toString();

        return AmbientSoundResult(
          title: title,
          provider: 'Pixabay',
          query: originalQuery,
          previewUrl: preview,
        );
      }).where((e) => (e.previewUrl ?? '').isNotEmpty).toList();

      if (parsed.isNotEmpty) {
        _pixabayCache[cacheKey] = parsed;
      }
      return parsed;
    } catch (e) {
      debugPrint('Pixabay ambient search error: $e');
      return [];
    }
  }

  Future<void> _respectPixabayThrottle() async {
    final now = DateTime.now();
    final last = _lastPixabayRequestAt;
    if (last != null) {
      final elapsed = now.difference(last);
      const minGap = Duration(milliseconds: 450);
      if (elapsed < minGap) {
        await Future.delayed(minGap - elapsed);
      }
    }
    _lastPixabayRequestAt = DateTime.now();
  }

  String _normalizePixabayQuery(String query) {
    final lower = query.toLowerCase();
    final compact = lower
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .where(
          (w) => !{
            'ambience',
            'ambient',
            'loop',
            'background',
            'atmosphere',
            'atmospheric',
            'distant',
            'natural',
            'habitat',
            'texture',
          }.contains(w),
        )
        .toList();

    if (compact.isEmpty) return query.trim();
    return compact.take(3).join(' ');
  }

  Future<List<AmbientSoundResult>> _searchFreesound(
    String query, {
    int perQueryLimit = 5,
  }) async {
    try {
      final uri = Uri.https('freesound.org', '/apiv2/search/text/', {
        'query': query,
        'token': _freesoundApiKey,
        'fields': 'id,name,previews',
        'page_size': '$perQueryLimit',
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return [];
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final results = (body['results'] as List?) ?? const [];

      return results.map<AmbientSoundResult>((raw) {
        final item = raw as Map<String, dynamic>;
        final title = (item['name'] ?? item['id'] ?? 'Freesound').toString();

        final dynamic previewsRaw = item['previews'];
        String? preview;
        if (previewsRaw is Map<String, dynamic>) {
          preview = (previewsRaw['preview-hq-mp3'] ??
                  previewsRaw['preview-lq-mp3'] ??
                  previewsRaw['preview_hq_mp3'] ??
                  previewsRaw['preview_lq_mp3'])
              ?.toString();
        }

        return AmbientSoundResult(
          title: title,
          provider: 'Freesound',
          query: query,
          previewUrl: preview,
        );
      }).where((e) => (e.previewUrl ?? '').isNotEmpty).toList();
    } catch (e) {
      debugPrint('Freesound ambient search error: $e');
      return [];
    }
  }
}
