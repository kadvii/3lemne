using System.Text.Json;
using System.Text.RegularExpressions;
using Alemni.Application.Common.Interfaces;
using Alemni.Application.DTOs;
using Alemni.Domain.Entities;
using Alemni.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Alemni.Infrastructure.Seed;

public interface IDbSeeder
{
    Task SeedAsync(CancellationToken ct = default);
}

public class DbSeeder : IDbSeeder
{
    private readonly IAlemniDbContext _db;
    private readonly ILogger<DbSeeder> _logger;
    private readonly string _dataDir;

    public DbSeeder(IAlemniDbContext db, ILogger<DbSeeder> logger)
    {
        _db = db;
        _logger = logger;

        // Locate data directory relative to base directory
        var baseDir = AppContext.BaseDirectory;
        var probePaths = new[]
        {
            Path.Combine(baseDir, "Seed", "Data"),
            Path.Combine(baseDir, "..", "..", "..", "..", "Alemni.Infrastructure", "Seed", "Data"),
            Path.Combine(Directory.GetCurrentDirectory(), "Seed", "Data"),
            Path.Combine(Directory.GetCurrentDirectory(), "backend", "Alemni.Infrastructure", "Seed", "Data")
        };

        _dataDir = probePaths.FirstOrDefault(Directory.Exists) 
                   ?? Path.Combine(baseDir, "Seed", "Data");
    }

    public async Task SeedAsync(CancellationToken ct = default)
    {
        if (!Directory.Exists(_dataDir))
        {
            _logger.LogWarning("Seed data directory not found at: {DataDir}", _dataDir);
            return;
        }

        await SeedVocabAsync(ct);
        await _db.SaveChangesAsync(ct);

        await SeedWritingAsync(ct);
        await _db.SaveChangesAsync(ct);

        await SeedListeningAsync(ct);
        await _db.SaveChangesAsync(ct);

        await SeedSpeakingAsync(ct);
        await _db.SaveChangesAsync(ct);

        await SeedReadingAsync(ct);
        await _db.SaveChangesAsync(ct);

        await SeedPhonicsAsync(ct);
        await _db.SaveChangesAsync(ct);

        await SeedChineseHsk1Async(ct);
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("Database seed completed successfully.");
    }

    private async Task SeedVocabAsync(CancellationToken ct)
    {
        var filePath = Path.Combine(_dataDir, "vocab.json");
        if (!File.Exists(filePath)) return;

        var json = await File.ReadAllTextAsync(filePath, ct);
        var items = JsonSerializer.Deserialize<List<VocabItemDto>>(json);
        if (items == null) return;

        var existingWords = (await _db.Words.Select(w => w.English.ToLower()).ToListAsync(ct)).ToHashSet();

        foreach (var item in items)
        {
            var en = item.english.Trim();
            if (string.IsNullOrWhiteSpace(en) || existingWords.Contains(en.ToLower()))
                continue;

            _db.Words.Add(new Word
            {
                Id = Guid.NewGuid(),
                English = en,
                Arabic = item.arabic.Trim(),
                BaseWord = item.baseWord?.Trim(),
                Level = DifficultyLevel.A1
            });
            existingWords.Add(en.ToLower());
        }
    }

    private async Task SeedWritingAsync(CancellationToken ct)
    {
        var filePath = Path.Combine(_dataDir, "writing.json");
        if (!File.Exists(filePath)) return;

        var json = await File.ReadAllTextAsync(filePath, ct);
        var dict = JsonSerializer.Deserialize<Dictionary<string, List<List<string>>>>(json);
        if (dict == null) return;

        var wordsMap = await _db.Words.ToDictionaryAsync(w => w.English.ToLower(), w => w, ct);
        var existingWriting = (await _db.WritingItems.Select(w => new { w.Level, w.OrderIndex }).ToListAsync(ct))
            .ToHashSet();

        foreach (var (levelStr, pairs) in dict)
        {
            if (!Enum.TryParse<DifficultyLevel>(levelStr, true, out var level))
                continue;

            for (var i = 0; i < pairs.Count; i++)
            {
                var pair = pairs[i];
                if (pair.Count < 2) continue;
                var orderIndex = i + 1;

                if (existingWriting.Contains(new { Level = level, OrderIndex = orderIndex }))
                    continue;

                var en = pair[0].Trim().ToLower();
                var ar = pair[1].Trim();

                if (!wordsMap.TryGetValue(en, out var word))
                {
                    word = new Word
                    {
                        Id = Guid.NewGuid(),
                        English = pair[0].Trim(),
                        Arabic = ar,
                        Level = level
                    };
                    _db.Words.Add(word);
                    wordsMap[en] = word;
                }
                else
                {
                    word.Level = level;
                }

                _db.WritingItems.Add(new WritingItem
                {
                    Id = Guid.NewGuid(),
                    WordId = word.Id,
                    Level = level,
                    OrderIndex = orderIndex
                });

                existingWriting.Add(new { Level = level, OrderIndex = orderIndex });
            }
        }
    }

    private async Task SeedListeningAsync(CancellationToken ct)
    {
        var filePath = Path.Combine(_dataDir, "listening.json");
        if (!File.Exists(filePath)) return;

        var json = await File.ReadAllTextAsync(filePath, ct);
        var dict = JsonSerializer.Deserialize<Dictionary<string, List<ListeningDto>>>(json);
        if (dict == null) return;

        var existingListening = (await _db.ListeningItems.Select(l => l.English.ToLower()).ToListAsync(ct)).ToHashSet();

        foreach (var (levelStr, items) in dict)
        {
            if (!Enum.TryParse<DifficultyLevel>(levelStr, true, out var level))
                continue;

            foreach (var item in items)
            {
                if (existingListening.Contains(item.en.ToLower()))
                    continue;

                _db.ListeningItems.Add(new ListeningItem
                {
                    Id = Guid.NewGuid(),
                    Level = level,
                    English = item.en.Trim(),
                    Arabic = item.ar.Trim(),
                    QuestionAr = item.q.Trim(),
                    OptionsJson = JsonSerializer.Serialize(item.options),
                    CorrectAnswerIndex = item.answer,
                    Type = ListeningType.Sentence
                });

                existingListening.Add(item.en.ToLower());
            }
        }
    }

    private async Task SeedSpeakingAsync(CancellationToken ct)
    {
        var filePath = Path.Combine(_dataDir, "speaking.json");
        if (!File.Exists(filePath)) return;

        var json = await File.ReadAllTextAsync(filePath, ct);
        var dict = JsonSerializer.Deserialize<Dictionary<string, List<SpeakingDto>>>(json);
        if (dict == null) return;

        var existingSpeaking = (await _db.SpeakingItems.Select(s => s.English.ToLower()).ToListAsync(ct)).ToHashSet();

        foreach (var (levelStr, items) in dict)
        {
            if (!Enum.TryParse<DifficultyLevel>(levelStr, true, out var level))
                continue;

            foreach (var item in items)
            {
                if (existingSpeaking.Contains(item.en.ToLower()))
                    continue;

                _db.SpeakingItems.Add(new SpeakingItem
                {
                    Id = Guid.NewGuid(),
                    Level = level,
                    English = item.en.Trim(),
                    Arabic = item.ar.Trim(),
                    PronunciationTipAr = item.tip?.Trim()
                });

                existingSpeaking.Add(item.en.ToLower());
            }
        }
    }

    private static readonly Regex SentenceSplitRegex = new(@"(?<=[.!?])\s+", RegexOptions.Compiled);

    private async Task SeedReadingAsync(CancellationToken ct)
    {
        var storiesPath = Path.Combine(_dataDir, "stories.json");
        if (File.Exists(storiesPath))
        {
            await SeedStoriesBlueprintAsync(storiesPath, ct);
            return;
        }

        var filePath = Path.Combine(_dataDir, "reading.json");
        if (!File.Exists(filePath)) return;

        var json = await File.ReadAllTextAsync(filePath, ct);
        var stories = JsonSerializer.Deserialize<List<ReadingDto>>(json);
        if (stories == null) return;

        var existingStories = await _db.Stories
            .Include(s => s.Sentences)
            .Include(s => s.Questions)
            .ToListAsync(ct);
        var storyMap = existingStories.ToDictionary(s => s.Title.ToLower(), s => s);

        foreach (var s in stories)
        {
            Enum.TryParse<DifficultyLevel>(s.level, true, out var level);
            var titleKey = s.title.Trim().ToLower();

            if (storyMap.ContainsKey(titleKey))
                continue;

            var story = new Story
            {
                Id = Guid.NewGuid(),
                Title = s.title.Trim(),
                TitleAr = s.titleAr.Trim(),
                Level = level,
                IsGenerated = false,
                CreatedAt = DateTime.UtcNow
            };
            _db.Stories.Add(story);
            storyMap[titleKey] = story;

            var globalOrder = 1;
            if (s.paragraphs != null && s.paragraphs.Count > 0)
            {
                for (var pIdx = 0; pIdx < s.paragraphs.Count; pIdx++)
                {
                    var p = s.paragraphs[pIdx];
                    var sents = p.sentences ?? new List<string>();
                    var trans = p.translation ?? new List<string>();

                    for (var i = 0; i < sents.Count; i++)
                    {
                        story.Sentences.Add(new StorySentence
                        {
                            Id = Guid.NewGuid(),
                            StoryId = story.Id,
                            OrderIndex = globalOrder++,
                            ParagraphIndex = pIdx,
                            English = sents[i].Trim(),
                            Arabic = i < trans.Count ? trans[i].Trim() : string.Empty
                        });
                    }
                }
            }
            else if (s.sentences != null)
            {
                var trans = s.translation ?? new List<string>();
                for (var i = 0; i < s.sentences.Count; i++)
                {
                    story.Sentences.Add(new StorySentence
                    {
                        Id = Guid.NewGuid(),
                        StoryId = story.Id,
                        OrderIndex = globalOrder++,
                        ParagraphIndex = i / 3,
                        English = s.sentences[i].Trim(),
                        Arabic = i < trans.Count ? trans[i].Trim() : string.Empty
                    });
                }
            }

            var wordCount = story.Sentences.Sum(sent => sent.English.Split(' ', StringSplitOptions.RemoveEmptyEntries).Length);
            story.EstimatedMinutes = Math.Max(1, (int)Math.Ceiling(wordCount / 120.0));

            if (s.questions != null)
            {
                foreach (var q in s.questions)
                {
                    Enum.TryParse<QuestionType>(q.type, true, out var qType);
                    story.Questions.Add(new StoryQuestion
                    {
                        Id = Guid.NewGuid(),
                        StoryId = story.Id,
                        Type = qType,
                        QuestionAr = q.q.Trim(),
                        QuestionEn = q.qEn?.Trim(),
                        OptionsJson = JsonSerializer.Serialize(q.options),
                        CorrectAnswerIndex = q.answer,
                        EvidenceSentenceIndex = q.evidence,
                        ExplanationAr = q.explanationAr?.Trim()
                    });
                }
            }
        }
    }

    private async Task SeedStoriesBlueprintAsync(string filePath, CancellationToken ct)
    {
        var json = await File.ReadAllTextAsync(filePath, ct);
        var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
        var blueprints = JsonSerializer.Deserialize<List<StoryBlueprint>>(json, options);
        if (blueprints == null) return;

        var existingStories = await _db.Stories
            .Include(s => s.Sentences)
            .Include(s => s.Questions)
            .ToListAsync(ct);
        var storyMap = existingStories.ToDictionary(s => s.Title.Trim().ToLowerInvariant(), s => s);

        foreach (var b in blueprints)
        {
            var titleKey = b.Title.Trim().ToLowerInvariant();
            if (storyMap.ContainsKey(titleKey))
                continue;

            Enum.TryParse<DifficultyLevel>(b.Level, true, out var level);

            var story = new Story
            {
                Id = Guid.NewGuid(),
                Title = b.Title.Trim(),
                TitleAr = b.TitleAr?.Trim() ?? string.Empty,
                Genre = b.Genre?.Trim() ?? "everyday",
                Emoji = b.Emoji?.Trim() ?? "📖",
                Setting = b.Setting?.Trim() ?? string.Empty,
                Level = level,
                CharactersJson = JsonSerializer.Serialize(b.Characters),
                FactsJson = JsonSerializer.Serialize(b.Facts),
                IsGenerated = false,
                CreatedAt = DateTime.UtcNow
            };
            _db.Stories.Add(story);
            storyMap[titleKey] = story;

            var globalOrder = 1;
            var paragraphs = b.Text ?? new List<string>();
            for (var pIdx = 0; pIdx < paragraphs.Count; pIdx++)
            {
                var p = paragraphs[pIdx];
                var sents = SentenceSplitRegex.Split(p.Trim())
                    .Where(s => !string.IsNullOrWhiteSpace(s))
                    .ToList();

                foreach (var sent in sents)
                {
                    story.Sentences.Add(new StorySentence
                    {
                        Id = Guid.NewGuid(),
                        StoryId = story.Id,
                        OrderIndex = globalOrder++,
                        ParagraphIndex = pIdx,
                        English = sent.Trim(),
                        Arabic = string.Empty
                    });
                }
            }

            var wordCount = story.Sentences.Sum(sent => sent.English.Split(' ', StringSplitOptions.RemoveEmptyEntries).Length);
            story.EstimatedMinutes = Math.Max(1, (int)Math.Ceiling(wordCount / 120.0));

            if (b.QuestionPool != null)
            {
                foreach (var q in b.QuestionPool)
                {
                    Enum.TryParse<QuestionType>(q.Type, true, out var qType);

                    var allOptions = new List<string> { q.Correct.Trim() };
                    if (q.Distractors != null)
                    {
                        allOptions.AddRange(q.Distractors.Select(d => d.Trim()));
                    }

                    // Deterministic pseudo-shuffle based on question ID
                    var rng = new Random(q.Id.GetHashCode());
                    var shuffled = allOptions.OrderBy(_ => rng.Next()).ToList();
                    var correctIdx = shuffled.IndexOf(q.Correct.Trim());

                    var fact = b.Facts?.FirstOrDefault(f => f.Id == q.FactId);
                    var evidenceIdx = fact?.Sentence ?? 1;

                    story.Questions.Add(new StoryQuestion
                    {
                        Id = Guid.NewGuid(),
                        StoryId = story.Id,
                        Type = qType,
                        FactId = q.FactId,
                        QuestionEn = q.Q.Trim(),
                        QuestionAr = string.IsNullOrWhiteSpace(q.QAr) ? q.Q.Trim() : q.QAr.Trim(),
                        OptionsJson = JsonSerializer.Serialize(shuffled),
                        DistractorsJson = JsonSerializer.Serialize(q.Distractors),
                        CorrectAnswerIndex = correctIdx,
                        EvidenceSentenceIndex = evidenceIdx,
                        ExplanationAr = q.ExplanationAr?.Trim()
                    });
                }
            }
        }
    }

    private async Task SeedPhonicsAsync(CancellationToken ct)
    {
        var filePath = Path.Combine(_dataDir, "phonics.json");
        if (!File.Exists(filePath)) return;

        var json = await File.ReadAllTextAsync(filePath, ct);
        var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
        var phonics = JsonSerializer.Deserialize<List<PhonicsDto>>(json, options);
        if (phonics == null) return;

        var existingSymbols = (await _db.PhonicsItems.Select(p => p.Symbol.ToLower()).ToListAsync(ct)).ToHashSet();

        foreach (var p in phonics)
        {
            if (existingSymbols.Contains(p.symbol.ToLower()))
                continue;

            Enum.TryParse<PhonicsKind>(p.kind, true, out var kind);

            var exampleJson = p.exampleWords != null
                ? JsonSerializer.Serialize(p.exampleWords)
                : (p.exampleWordsJson ?? "[]");

            var pairsJson = p.minimalPairs != null
                ? JsonSerializer.Serialize(p.minimalPairs)
                : (p.minimalPairsJson ?? "[]");

            _db.PhonicsItems.Add(new PhonicsItem
            {
                Id = Guid.NewGuid(),
                Kind = kind,
                Category = p.category ?? "consonants",
                Symbol = p.symbol,
                IpaOrSpelling = p.ipaOrSpelling,
                ArabicApprox = p.arabicApprox,
                MouthTipAr = p.mouthTipAr,
                MouthDiagramType = p.mouthDiagramType ?? "bilabial_p_b",
                ExampleWordsJson = exampleJson,
                MinimalPairsJson = pairsJson,
                TongueTwister = p.tongueTwister ?? string.Empty,
                TongueTwisterAr = p.tongueTwisterAr ?? string.Empty,
                AudioUrl = p.audioUrl
            });

            existingSymbols.Add(p.symbol.ToLower());
        }
    }

    private async Task SeedChineseHsk1Async(CancellationToken ct)
    {
        var filePath = Path.Combine(_dataDir, "chinese_hsk1.json");
        if (!File.Exists(filePath)) return;

        var json = await File.ReadAllTextAsync(filePath, ct);
        var items = JsonSerializer.Deserialize<List<ChineseHsk1ItemDto>>(json);
        if (items == null) return;

        var existingWords = (await _db.Words
            .Where(w => w.LanguageCode == "zh")
            .Select(w => w.English)
            .ToListAsync(ct))
            .ToHashSet();

        foreach (var item in items)
        {
            var hanzi = item.hanzi.Trim();
            if (string.IsNullOrWhiteSpace(hanzi) || existingWords.Contains(hanzi))
                continue;

            _db.Words.Add(new Word
            {
                Id = Guid.NewGuid(),
                English = hanzi,
                Arabic = item.arabic.Trim(),
                Pinyin = item.pinyin.Trim(),
                EnglishMeaning = item.english.Trim(),
                LanguageCode = item.languageCode?.Trim() ?? "zh",
                Level = DifficultyLevel.A1
            });
            existingWords.Add(hanzi);
        }
    }

    private record ChineseHsk1ItemDto(string hanzi, string pinyin, string arabic, string english, string? level, string? languageCode);
    private record VocabItemDto(string english, string arabic, string? baseWord);
    private record ListeningDto(string en, string ar, string q, List<string> options, int answer);
    private record SpeakingDto(string en, string ar, string? tip);
    private record ReadingDto(string id, string level, string title, string titleAr, int? minutes, List<ParagraphDto>? paragraphs, List<string>? sentences, List<string>? translation, List<QuestionDto>? questions);
    private record ParagraphDto(List<string>? sentences, List<string>? translation);
    private record QuestionDto(string? type, string q, string? qEn, List<string> options, int answer, int? evidence, string? explanationAr);
    private record MinimalPairSeedDto(string word1, string word2, string? meaningAr1, string? meaningAr2);
    private record PhonicsDto(
        string kind,
        string? category,
        string symbol,
        string ipaOrSpelling,
        string arabicApprox,
        string mouthTipAr,
        string? mouthDiagramType,
        List<string>? exampleWords,
        string? exampleWordsJson,
        List<MinimalPairSeedDto>? minimalPairs,
        string? minimalPairsJson,
        string? tongueTwister,
        string? tongueTwisterAr,
        string? audioUrl
    );
}
