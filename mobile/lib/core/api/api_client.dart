import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return 'http://localhost:5104';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://192.168.0.10:5104';
    return 'http://localhost:5104';
  }

  static Future<void> updateBaseUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_api_url', newUrl.trim());
    instance.dio.options.baseUrl = newUrl.trim();
  }

  static Future<String> getCurrentBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString('custom_api_url');
    if (customUrl != null && customUrl.isNotEmpty) return customUrl;
    return baseUrl;
  }

  static final ApiClient instance = ApiClient();

  final Dio dio;

  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final customUrl = prefs.getString('custom_api_url');
          if (customUrl != null && customUrl.isNotEmpty) {
            options.baseUrl = customUrl;
          }
          final token = prefs.getString('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            final refreshToken = prefs.getString('refresh_token');
            if (refreshToken != null) {
              try {
                final refreshRes = await Dio().post(
                  '$baseUrl/api/auth/refresh',
                  data: {'refreshToken': refreshToken},
                );
                final newAccessToken = refreshRes.data['accessToken'];
                final newRefreshToken = refreshRes.data['refreshToken'];

                await prefs.setString('access_token', newAccessToken);
                await prefs.setString('refresh_token', newRefreshToken);

                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccessToken';
                final cloneReq = await dio.request(
                  opts.path,
                  options: Options(method: opts.method, headers: opts.headers),
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                );
                return handler.resolve(cloneReq);
              } catch (_) {
                await prefs.remove('access_token');
                await prefs.remove('refresh_token');
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // --- Reading API ---

  Future<ReadingStoryModel> getReadingStory({required String level, String? excludeId}) async {
    final query = <String, dynamic>{'level': level};
    if (excludeId != null && excludeId.isNotEmpty) {
      query['excludeId'] = excludeId;
    }
    final res = await dio.get('/api/reading/story', queryParameters: query);
    return ReadingStoryModel.fromJson(res.data);
  }

  Future<StoryAnswersResult> submitReadingAnswers({
    required String storyId,
    required List<int> selectedAnswers,
  }) async {
    final res = await dio.post(
      '/api/reading/story/$storyId/answers',
      data: {'selectedAnswers': selectedAnswers},
    );
    return StoryAnswersResult.fromJson(res.data);
  }

  // --- Words & Dictionary API ---

  Future<List<dynamic>> getWords({String languageCode = 'zh', String? level, int limit = 100}) async {
    final queryParams = <String, dynamic>{
      'languageCode': languageCode,
      'limit': limit,
    };
    if (level != null) queryParams['level'] = level;
    final res = await dio.get('/api/words', queryParameters: queryParams);
    return res.data as List<dynamic>;
  }

  Future<WordLookupResult> lookupWord(String word) async {
    final res = await dio.get('/api/words/lookup', queryParameters: {'q': word});
    return WordLookupResult.fromJson(res.data);
  }

  Future<bool> saveWord(String wordId) async {
    try {
      await dio.post('/api/words/saved', data: {'wordId': wordId});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<SavedWordModel>> getSavedWords() async {
    try {
      final res = await dio.get('/api/words/saved');
      final list = res.data as List<dynamic>;
      return list.map((item) => SavedWordModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> unsaveWord(String wordId) async {
    try {
      await dio.delete('/api/words/saved/$wordId');
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Writing API ---

  Future<WritingNextItem> getWritingNext({required String level}) async {
    final res = await dio.get('/api/writing/next', queryParameters: {'level': level});
    return WritingNextItem.fromJson(res.data);
  }

  Future<WritingCheckResult> checkWritingAnswer({
    required String wordId,
    required String answer,
    int hintsUsed = 0,
  }) async {
    final res = await dio.post(
      '/api/writing/check',
      data: {'wordId': wordId, 'answer': answer, 'hintsUsed': hintsUsed},
    );
    return WritingCheckResult.fromJson(res.data);
  }

  // --- Listening & Sentence Dictation API ---

  Future<ListeningNextItem> getListeningNext({required String level}) async {
    final res = await dio.get('/api/listening/next', queryParameters: {'level': level});
    return ListeningNextItem.fromJson(res.data);
  }

  // --- Phonics API ---

  Future<List<PhonicsItemModel>> getPhonics({
    String? kind,
    String? category,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (kind != null && kind.isNotEmpty) query['kind'] = kind;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final res = await dio.get('/api/phonics', queryParameters: query);
    final list = res.data as List<dynamic>;
    return list.map((item) => PhonicsItemModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}

// ================= Model Classes =================

class ReadingStoryModel {
  final String id;
  final String title;
  final String titleAr;
  final String level;
  final int wordCount;
  final int estimatedMinutes;
  final String genre;
  final String emoji;
  final String setting;
  final List<StorySentenceModel> sentences;
  final List<StoryQuestionModel> questions;

  ReadingStoryModel({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.level,
    required this.wordCount,
    required this.estimatedMinutes,
    this.genre = 'everyday',
    this.emoji = '📖',
    this.setting = '',
    required this.sentences,
    required this.questions,
  });

  factory ReadingStoryModel.fromJson(Map<String, dynamic> json) {
    return ReadingStoryModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      titleAr: json['titleAr'] ?? '',
      level: json['level'] ?? 'A1',
      wordCount: json['wordCount'] ?? 0,
      estimatedMinutes: json['estimatedMinutes'] ?? 1,
      genre: json['genre'] ?? 'everyday',
      emoji: json['emoji'] ?? '📖',
      setting: json['setting'] ?? '',
      sentences: (json['sentences'] as List<dynamic>? ?? [])
          .map((s) => StorySentenceModel.fromJson(s))
          .toList(),
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => StoryQuestionModel.fromJson(q))
          .toList(),
    );
  }

  /// Groups sentences by paragraph index
  Map<int, List<StorySentenceModel>> get paragraphs {
    final map = <int, List<StorySentenceModel>>{};
    for (final s in sentences) {
      map.putIfAbsent(s.paragraphIndex, () => []).add(s);
    }
    return map;
  }
}

class StorySentenceModel {
  final int orderIndex;
  final int paragraphIndex;
  final String english;
  final String arabic;

  StorySentenceModel({
    required this.orderIndex,
    required this.paragraphIndex,
    required this.english,
    required this.arabic,
  });

  factory StorySentenceModel.fromJson(Map<String, dynamic> json) {
    return StorySentenceModel(
      orderIndex: json['orderIndex'] ?? 0,
      paragraphIndex: json['paragraphIndex'] ?? 0,
      english: json['english'] ?? '',
      arabic: json['arabic'] ?? '',
    );
  }
}

class StoryQuestionModel {
  final String id;
  final String type;
  final String questionAr;
  final String? questionEn;
  final List<String> options;
  final int? evidenceSentenceIndex;
  final String? explanationAr;
  final String? factId;

  StoryQuestionModel({
    required this.id,
    required this.type,
    required this.questionAr,
    this.questionEn,
    required this.options,
    this.evidenceSentenceIndex,
    this.explanationAr,
    this.factId,
  });

  factory StoryQuestionModel.fromJson(Map<String, dynamic> json) {
    return StoryQuestionModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'detail',
      questionAr: json['questionAr'] ?? '',
      questionEn: json['questionEn'],
      options: (json['options'] as List<dynamic>? ?? []).map((o) => o.toString()).toList(),
      evidenceSentenceIndex: json['evidenceSentenceIndex'],
      explanationAr: json['explanationAr'],
      factId: json['factId'],
    );
  }
}

class StoryAnswersResult {
  final int score;
  final int correctCount;
  final int totalQuestions;
  final int xpAwarded;
  final List<int> correctAnswers;
  final List<QuestionExplanationModel> explanations;

  StoryAnswersResult({
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.xpAwarded,
    required this.correctAnswers,
    required this.explanations,
  });

  factory StoryAnswersResult.fromJson(Map<String, dynamic> json) {
    return StoryAnswersResult(
      score: json['score'] ?? 0,
      correctCount: json['correctCount'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      xpAwarded: json['xpAwarded'] ?? 0,
      correctAnswers: (json['correctAnswers'] as List<dynamic>? ?? []).map((a) => (a as num).toInt()).toList(),
      explanations: (json['explanations'] as List<dynamic>? ?? [])
          .map((e) => QuestionExplanationModel.fromJson(e))
          .toList(),
    );
  }
}

class QuestionExplanationModel {
  final int questionIndex;
  final int correctAnswerIndex;
  final String? explanationAr;
  final int? evidenceSentenceIndex;

  QuestionExplanationModel({
    required this.questionIndex,
    required this.correctAnswerIndex,
    this.explanationAr,
    this.evidenceSentenceIndex,
  });

  factory QuestionExplanationModel.fromJson(Map<String, dynamic> json) {
    return QuestionExplanationModel(
      questionIndex: json['questionIndex'] ?? 0,
      correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
      explanationAr: json['explanationAr'],
      evidenceSentenceIndex: json['evidenceSentenceIndex'],
    );
  }
}

class WordLookupResult {
  final String word;
  final String arabic;
  final String? baseWord;
  final bool found;
  final String? wordId;

  WordLookupResult({
    required this.word,
    required this.arabic,
    this.baseWord,
    required this.found,
    this.wordId,
  });

  factory WordLookupResult.fromJson(Map<String, dynamic> json) {
    return WordLookupResult(
      word: json['word'] ?? '',
      arabic: json['arabic'] ?? '',
      baseWord: json['baseWord'],
      found: json['found'] ?? false,
      wordId: json['wordId'],
    );
  }
}

class SavedWordModel {
  final String id;
  final String wordId;
  final String english;
  final String arabic;
  final DateTime addedAt;

  SavedWordModel({
    required this.id,
    required this.wordId,
    required this.english,
    required this.arabic,
    required this.addedAt,
  });

  factory SavedWordModel.fromJson(Map<String, dynamic> json) {
    return SavedWordModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      wordId: (json['wordId'] ?? json['WordId'] ?? '').toString(),
      english: json['english'] ?? json['English'] ?? '',
      arabic: json['arabic'] ?? json['Arabic'] ?? '',
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get srsStageLabel {
    final diff = DateTime.now().difference(addedAt).inDays;
    if (diff < 1) return 'مراجعة Day 1';
    if (diff < 3) return 'مراجعة Day 3';
    if (diff < 7) return 'مراجعة Day 7';
    if (diff < 14) return 'مراجعة Day 14';
    return 'متقنة 🏆';
  }
}

class WritingNextItem {
  final String id;
  final String wordId;
  final String level;
  final int length;
  final String hintAr;
  final int? vowelCount;
  final String? exampleEn;

  WritingNextItem({
    required this.id,
    required this.wordId,
    required this.level,
    required this.length,
    required this.hintAr,
    this.vowelCount,
    this.exampleEn,
  });

  factory WritingNextItem.fromJson(Map<String, dynamic> json) {
    return WritingNextItem(
      id: json['id'] ?? '',
      wordId: json['wordId'] ?? '',
      level: json['level'] ?? 'A1',
      length: json['length'] ?? 0,
      hintAr: json['hintAr'] ?? '',
      vowelCount: json['vowelCount'],
      exampleEn: json['exampleEn'],
    );
  }
}

class LetterCheckResult {
  final String expected;
  final String? actual;
  final bool isCorrect;

  LetterCheckResult({
    required this.expected,
    this.actual,
    required this.isCorrect,
  });

  factory LetterCheckResult.fromJson(Map<String, dynamic> json) {
    return LetterCheckResult(
      expected: json['expected'] ?? '',
      actual: json['actual'],
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}

class WritingCheckResult {
  final bool isCorrect;
  final String word;
  final String arabic;
  final List<LetterCheckResult> letters;
  final int xpAwarded;
  final String? exampleEn;
  final String? exampleAr;

  WritingCheckResult({
    required this.isCorrect,
    required this.word,
    required this.arabic,
    required this.letters,
    required this.xpAwarded,
    this.exampleEn,
    this.exampleAr,
  });

  factory WritingCheckResult.fromJson(Map<String, dynamic> json) {
    return WritingCheckResult(
      isCorrect: json['isCorrect'] ?? false,
      word: json['word'] ?? '',
      arabic: json['arabic'] ?? '',
      letters: (json['letters'] as List<dynamic>? ?? [])
          .map((l) => LetterCheckResult.fromJson(l))
          .toList(),
      xpAwarded: json['xpAwarded'] ?? 0,
      exampleEn: json['exampleEn'],
      exampleAr: json['exampleAr'],
    );
  }
}

class ListeningNextItem {
  final String id;
  final String level;
  final String english;
  final String arabic;
  final String questionAr;
  final String type;
  final List<String> options;

  ListeningNextItem({
    required this.id,
    required this.level,
    required this.english,
    required this.arabic,
    required this.questionAr,
    required this.type,
    required this.options,
  });

  factory ListeningNextItem.fromJson(Map<String, dynamic> json) {
    return ListeningNextItem(
      id: json['id'] ?? '',
      level: json['level'] ?? 'A1',
      english: json['english'] ?? '',
      arabic: json['arabic'] ?? '',
      questionAr: json['questionAr'] ?? '',
      type: json['type'] ?? 'sentence',
      options: (json['options'] as List<dynamic>? ?? []).map((o) => o.toString()).toList(),
    );
  }
}

class MinimalPairModel {
  final String word1;
  final String word2;
  final String meaningAr1;
  final String meaningAr2;

  MinimalPairModel({
    required this.word1,
    required this.word2,
    required this.meaningAr1,
    required this.meaningAr2,
  });

  factory MinimalPairModel.fromJson(Map<String, dynamic> json) {
    return MinimalPairModel(
      word1: json['word1'] ?? json['Word1'] ?? '',
      word2: json['word2'] ?? json['Word2'] ?? '',
      meaningAr1: json['meaningAr1'] ?? json['MeaningAr1'] ?? json['ar1'] ?? '',
      meaningAr2: json['meaningAr2'] ?? json['MeaningAr2'] ?? json['ar2'] ?? '',
    );
  }
}

class PhonicsItemModel {
  final String id;
  final String kind;
  final String category;
  final String symbol;
  final String ipaOrSpelling;
  final String arabicApprox;
  final String mouthTipAr;
  final String mouthDiagramType;
  final List<String> exampleWords;
  final List<MinimalPairModel> minimalPairs;
  final String tongueTwister;
  final String tongueTwisterAr;
  final String? audioUrl;

  PhonicsItemModel({
    required this.id,
    required this.kind,
    required this.category,
    required this.symbol,
    required this.ipaOrSpelling,
    required this.arabicApprox,
    required this.mouthTipAr,
    required this.mouthDiagramType,
    required this.exampleWords,
    required this.minimalPairs,
    required this.tongueTwister,
    required this.tongueTwisterAr,
    this.audioUrl,
  });

  factory PhonicsItemModel.fromJson(Map<String, dynamic> json) {
    final rawExamples = json['exampleWords'] ?? json['ExampleWords'];
    List<String> examples = [];
    if (rawExamples is List) {
      examples = rawExamples.map((e) => e.toString()).toList();
    }

    final rawPairs = json['minimalPairs'] ?? json['MinimalPairs'];
    List<MinimalPairModel> pairs = [];
    if (rawPairs is List) {
      pairs = rawPairs.map((p) => MinimalPairModel.fromJson(p as Map<String, dynamic>)).toList();
    }

    return PhonicsItemModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      kind: json['kind'] ?? json['Kind'] ?? 'Sound',
      category: json['category'] ?? json['Category'] ?? 'consonants',
      symbol: json['symbol'] ?? json['Symbol'] ?? '',
      ipaOrSpelling: json['ipaOrSpelling'] ?? json['IpaOrSpelling'] ?? '',
      arabicApprox: json['arabicApprox'] ?? json['ArabicApprox'] ?? '',
      mouthTipAr: json['mouthTipAr'] ?? json['MouthTipAr'] ?? '',
      mouthDiagramType: json['mouthDiagramType'] ?? json['MouthDiagramType'] ?? 'bilabial_p_b',
      exampleWords: examples,
      minimalPairs: pairs,
      tongueTwister: json['tongueTwister'] ?? json['TongueTwister'] ?? '',
      tongueTwisterAr: json['tongueTwisterAr'] ?? json['TongueTwisterAr'] ?? '',
      audioUrl: json['audioUrl'] ?? json['AudioUrl'],
    );
  }
}
