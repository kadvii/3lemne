class ChineseWord {
  final String id;
  final String hanzi;
  final String? pinyin;
  final String arabic;
  final String? english;
  final String level;

  const ChineseWord({
    required this.id,
    required this.hanzi,
    this.pinyin,
    required this.arabic,
    this.english,
    this.level = 'A1',
  });

  factory ChineseWord.fromJson(Map<String, dynamic> json) {
    return ChineseWord(
      id: json['id']?.toString() ?? '',
      // Backend returns Hanzi in the 'word' field (or fallback to 'hanzi' / 'english')
      hanzi: (json['word'] ?? json['hanzi'] ?? json['english'] ?? '').toString(),
      pinyin: json['pinyin']?.toString(),
      arabic: (json['arabic'] ?? '').toString(),
      english: (json['englishMeaning'] ?? json['english'])?.toString(),
      level: (json['level'] ?? 'A1').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': hanzi,
      'pinyin': pinyin,
      'arabic': arabic,
      'englishMeaning': english,
      'level': level,
      'languageCode': 'zh',
    };
  }
}

