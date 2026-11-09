using System.Text.Json;
using System.Text.RegularExpressions;
using Alemni.Application.Common.Interfaces;
using Alemni.Application.DTOs;
using Alemni.Domain.Entities;
using Alemni.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Alemni.Application.Services;

public class WordService : IWordService
{
    private readonly IAlemniDbContext _db;
    private readonly IMorphologyService _morphology;

    public WordService(IAlemniDbContext db, IMorphologyService morphology)
    {
        _db = db;
        _morphology = morphology;
    }

    public async Task<LookupResult> LookupAsync(string word, CancellationToken ct = default)
    {
        var raw = word ?? string.Empty;
        var normalized = _morphology.NormalizeWord(raw);

        if (string.IsNullOrEmpty(normalized))
        {
            return new LookupResult(raw, "—", null, false);
        }

        // 1. Direct dictionary match
        var direct = await _db.Words.FirstOrDefaultAsync(w => w.English.ToLower() == normalized, ct);
        if (direct != null)
        {
            return new LookupResult(raw, direct.Arabic, direct.BaseWord, true, direct.Id);
        }

        // 2. Possessive 's removal
        if (normalized.EndsWith("'s"))
        {
            var noPoss = normalized[..^2];
            var possMatch = await _db.Words.FirstOrDefaultAsync(w => w.English.ToLower() == noPoss, ct);
            if (possMatch != null)
            {
                return new LookupResult(raw, possMatch.Arabic, null, true, possMatch.Id);
            }
        }

        // 3. Morphological variations (-ing, -ed, -s, -ies, etc.)
        var candidates = _morphology.GetCandidates(normalized);
        foreach (var c in candidates)
        {
            var candMatch = await _db.Words.FirstOrDefaultAsync(w => w.English.ToLower() == c, ct);
            if (candMatch != null)
            {
                return new LookupResult(raw, candMatch.Arabic, c, true, candMatch.Id);
            }
        }

        return new LookupResult(raw, "لا يوجد معنى محفوظ لهذه الكلمة بعد", null, false, null);
    }

    public async Task<List<SavedWordDto>> GetSavedWordsAsync(Guid userId, CancellationToken ct = default)
    {
        return await _db.SavedWords
            .Where(s => s.UserId == userId)
            .OrderByDescending(s => s.AddedAt)
            .Select(s => new SavedWordDto(s.Id, s.WordId, s.Word!.English, s.Word.Arabic, s.AddedAt))
            .ToListAsync(ct);
    }

    public async Task SaveWordAsync(Guid userId, Guid wordId, CancellationToken ct = default)
    {
        var exists = await _db.SavedWords.AnyAsync(s => s.UserId == userId && s.WordId == wordId, ct);
        if (exists) return;

        _db.SavedWords.Add(new SavedWord
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WordId = wordId,
            AddedAt = DateTime.UtcNow
        });

        await _db.SaveChangesAsync(ct);
    }

    public async Task UnsaveWordAsync(Guid userId, Guid wordId, CancellationToken ct = default)
    {
        var item = await _db.SavedWords.FirstOrDefaultAsync(s => s.UserId == userId && s.WordId == wordId, ct);
        if (item != null)
        {
            _db.SavedWords.Remove(item);
            await _db.SaveChangesAsync(ct);
        }
    }
}

public interface IWordService
{
    Task<LookupResult> LookupAsync(string word, CancellationToken ct = default);
    Task<List<SavedWordDto>> GetSavedWordsAsync(Guid userId, CancellationToken ct = default);
    Task SaveWordAsync(Guid userId, Guid wordId, CancellationToken ct = default);
    Task UnsaveWordAsync(Guid userId, Guid wordId, CancellationToken ct = default);
}

public class WritingService : IWritingService
{
    private readonly IAlemniDbContext _db;
    private readonly IUserStatsService _statsService;

    public WritingService(IAlemniDbContext db, IUserStatsService statsService)
    {
        _db = db;
        _statsService = statsService;
    }

    public async Task<WritingNextDto> GetNextAsync(DifficultyLevel level, Guid? userId = null, CancellationToken ct = default)
    {
        var query = _db.WritingItems.Where(w => w.Level == level);

        if (userId.HasValue)
        {
            var completedIds = await _db.UserProgress
                .Where(p => p.UserId == userId.Value && p.Skill == UserSkill.Writing && p.Level == level)
                .Select(p => p.ItemId)
                .ToListAsync(ct);

            var uncompleted = query.Where(w => !completedIds.Contains(w.Id));
            if (await uncompleted.AnyAsync(ct)) query = uncompleted;
        }

        var count = await query.CountAsync(ct);
        if (count == 0)
        {
            // Fallback to any item of that level
            query = _db.WritingItems.Where(w => w.Level == level);
            count = await query.CountAsync(ct);
        }

        var skip = count > 1 ? Random.Shared.Next(count) : 0;
        var item = await query.Include(w => w.Word).Skip(skip).FirstOrDefaultAsync(ct)
            ?? throw new InvalidOperationException("لا توجد كلمات متاحة لهذا المستوى.");

        var word = item.Word!;
        var vowels = word.English.Count(c => "aeiouAEIOU".Contains(c));
        var maskedExample = string.IsNullOrEmpty(word.ExampleEn)
            ? null
            : Regex.Replace(word.ExampleEn, Regex.Escape(word.English), "_____", RegexOptions.IgnoreCase);

        return new WritingNextDto(
            item.Id,
            item.WordId,
            item.Level.ToString(),
            word.English.Length,
            word.Arabic,
            vowels,
            maskedExample);
    }

    public async Task<WritingCheckResponse> CheckAnswerAsync(WritingCheckRequest request, Guid? userId = null, CancellationToken ct = default)
    {
        var word = await _db.Words.FirstOrDefaultAsync(w => w.Id == request.WordId, ct)
            ?? throw new InvalidOperationException("الكلمة غير موجودة.");

        var expected = word.English.Trim().ToLowerInvariant();
        var actual = (request.Answer ?? string.Empty).Trim().ToLowerInvariant();

        var letters = new List<LetterCheck>();
        for (var i = 0; i < expected.Length; i++)
        {
            char? actChar = i < actual.Length ? actual[i] : null;
            var isCorrect = actChar == expected[i];
            letters.Add(new LetterCheck(expected[i], actChar, isCorrect));
        }

        var allCorrect = expected == actual;
        var xpAwarded = 0;

        if (allCorrect && userId.HasValue)
        {
            // Rule R6: Penalty for hints, minimum 1 XP
            xpAwarded = Math.Max(1, 5 - request.HintsUsed);
            await _statsService.AwardXpAsync(userId.Value, xpAwarded, UserSkill.Writing, word.Id, ct);
        }

        return new WritingCheckResponse(allCorrect, word.English, word.Arabic, letters, xpAwarded, word.ExampleEn, word.ExampleAr);
    }
}

public interface IWritingService
{
    Task<WritingNextDto> GetNextAsync(DifficultyLevel level, Guid? userId = null, CancellationToken ct = default);
    Task<WritingCheckResponse> CheckAnswerAsync(WritingCheckRequest request, Guid? userId = null, CancellationToken ct = default);
}

public class ReadingService : IReadingService
{
    private readonly IAlemniDbContext _db;
    private readonly IUserStatsService _statsService;

    public ReadingService(IAlemniDbContext db, IUserStatsService statsService)
    {
        _db = db;
        _statsService = statsService;
    }

    public async Task<ReadingStoryDto> GetStoryAsync(DifficultyLevel level, Guid? excludeId = null, CancellationToken ct = default)
    {
        var query = _db.Stories.Where(s => s.Level == level);

        if (excludeId.HasValue)
        {
            var filtered = query.Where(s => s.Id != excludeId.Value);
            if (await filtered.AnyAsync(ct))
            {
                query = filtered;
            }
        }

        var stories = await query
            .Include(s => s.Sentences.OrderBy(x => x.OrderIndex))
            .Include(s => s.Questions)
            .ToListAsync(ct);

        if (stories.Count == 0)
        {
            throw new InvalidOperationException("لا توجد قصص متاحة لهذا المستوى بعد.");
        }

        var story = stories[Random.Shared.Next(stories.Count)];

        var sentenceDtos = story.Sentences
            .OrderBy(s => s.OrderIndex)
            .Select(s => new SentenceDto(s.OrderIndex, s.ParagraphIndex, s.English, s.Arabic))
            .ToList();

        var questionDtos = story.Questions.Select(q =>
        {
            var opts = JsonSerializer.Deserialize<List<string>>(q.OptionsJson) ?? new List<string>();
            return new QuestionDto(q.Id, q.Type.ToString(), q.QuestionAr, q.QuestionEn, opts, q.EvidenceSentenceIndex, q.ExplanationAr, q.FactId);
        }).ToList();

        var wordCount = story.Sentences.Sum(s => s.English.Split(' ', StringSplitOptions.RemoveEmptyEntries).Length);
        var estimatedMinutes = Math.Max(1, (int)Math.Ceiling(wordCount / 120.0));

        return new ReadingStoryDto(
            story.Id,
            story.Title,
            story.TitleAr,
            story.Level.ToString(),
            wordCount,
            estimatedMinutes,
            sentenceDtos,
            questionDtos,
            story.Genre,
            story.Emoji,
            story.Setting);
    }

    public async Task<StoryAnswersResponse> SubmitAnswersAsync(Guid storyId, StoryAnswersRequest request, Guid? userId = null, CancellationToken ct = default)
    {
        var story = await _db.Stories
            .Include(s => s.Questions)
            .FirstOrDefaultAsync(s => s.Id == storyId, ct)
            ?? throw new InvalidOperationException("القصة غير موجودة.");

        var questions = story.Questions.ToList();
        var correctCount = 0;
        var correctAnswers = new List<int>();
        var explanations = new List<QuestionExplanationDto>();

        for (var i = 0; i < questions.Count; i++)
        {
            var q = questions[i];
            var correctIdx = q.CorrectAnswerIndex;
            correctAnswers.Add(correctIdx);

            if (i < request.SelectedAnswers.Count && request.SelectedAnswers[i] == correctIdx)
            {
                correctCount++;
            }

            explanations.Add(new QuestionExplanationDto(i, correctIdx, q.ExplanationAr, q.EvidenceSentenceIndex));
        }

        var total = questions.Count;
        var score = total > 0 ? (int)Math.Round((double)correctCount / total * 100) : 0;
        var xpAwarded = 0;

        if (userId.HasValue)
        {
            if (correctCount > 0)
            {
                xpAwarded = correctCount * 5;
                await _statsService.AwardXpAsync(userId.Value, xpAwarded, UserSkill.Reading, storyId, ct);
            }

            _db.UserStoryHistories.Add(new UserStoryHistory
            {
                Id = Guid.NewGuid(),
                UserId = userId.Value,
                StoryId = storyId,
                Score = score,
                ReadAt = DateTime.UtcNow
            });
            await _db.SaveChangesAsync(ct);
        }

        return new StoryAnswersResponse(score, correctCount, total, xpAwarded, correctAnswers, explanations);
    }
}

public interface IReadingService
{
    Task<ReadingStoryDto> GetStoryAsync(DifficultyLevel level, Guid? excludeId = null, CancellationToken ct = default);
    Task<StoryAnswersResponse> SubmitAnswersAsync(Guid storyId, StoryAnswersRequest request, Guid? userId = null, CancellationToken ct = default);
}

public class ListeningService : IListeningService
{
    private readonly IAlemniDbContext _db;
    private readonly IUserStatsService _statsService;

    public ListeningService(IAlemniDbContext db, IUserStatsService statsService)
    {
        _db = db;
        _statsService = statsService;
    }

    public async Task<ListeningNextDto> GetNextAsync(DifficultyLevel level, ListeningType? type = null, CancellationToken ct = default)
    {
        var query = _db.ListeningItems.Where(l => l.Level == level);
        if (type.HasValue) query = query.Where(l => l.Type == type.Value);

        var count = await query.CountAsync(ct);
        if (count == 0)
        {
            query = _db.ListeningItems.Where(l => l.Level == level);
            count = await query.CountAsync(ct);
        }

        if (count == 0) throw new InvalidOperationException("لا توجد تمارين استماع متاحة لهذا المستوى.");

        var skip = count > 1 ? Random.Shared.Next(count) : 0;
        var item = await query.Skip(skip).FirstOrDefaultAsync(ct)!;

        var options = JsonSerializer.Deserialize<List<string>>(item!.OptionsJson) ?? new List<string>();

        return new ListeningNextDto(item.Id, item.Level.ToString(), item.English, item.Arabic, item.QuestionAr, item.Type.ToString(), options);
    }

    public async Task<ListeningAnswerResponse> SubmitAnswerAsync(ListeningAnswerRequest request, Guid? userId = null, CancellationToken ct = default)
    {
        var item = await _db.ListeningItems.FirstOrDefaultAsync(l => l.Id == request.ItemId, ct)
            ?? throw new InvalidOperationException("تمرين الاستماع غير موجود.");

        var isCorrect = request.SelectedIndex == item.CorrectAnswerIndex;
        var xpAwarded = 0;

        if (isCorrect && userId.HasValue)
        {
            xpAwarded = 5;
            await _statsService.AwardXpAsync(userId.Value, xpAwarded, UserSkill.Listening, item.Id, ct);
        }

        return new ListeningAnswerResponse(isCorrect, item.CorrectAnswerIndex, item.English, item.Arabic, xpAwarded);
    }
}

public interface IListeningService
{
    Task<ListeningNextDto> GetNextAsync(DifficultyLevel level, ListeningType? type = null, CancellationToken ct = default);
    Task<ListeningAnswerResponse> SubmitAnswerAsync(ListeningAnswerRequest request, Guid? userId = null, CancellationToken ct = default);
}

public class SpeakingService : ISpeakingService
{
    private readonly IAlemniDbContext _db;
    private readonly ISpeechScoringService _scorer;
    private readonly IUserStatsService _statsService;

    public SpeakingService(IAlemniDbContext db, ISpeechScoringService scorer, IUserStatsService statsService)
    {
        _db = db;
        _scorer = scorer;
        _statsService = statsService;
    }

    public async Task<SpeakingNextDto> GetNextAsync(DifficultyLevel level, CancellationToken ct = default)
    {
        var query = _db.SpeakingItems.Where(s => s.Level == level);
        var count = await query.CountAsync(ct);

        if (count == 0) throw new InvalidOperationException("لا توجد تمارين تحدث متاحة لهذا المستوى.");

        var skip = count > 1 ? Random.Shared.Next(count) : 0;
        var item = await query.Skip(skip).FirstOrDefaultAsync(ct)!;

        return new SpeakingNextDto(item!.Id, item.Level.ToString(), item.English, item.Arabic, item.PronunciationTipAr);
    }

    public async Task<SpeakingScoreResponse> ScoreAsync(SpeakingScoreRequest request, Guid? userId = null, CancellationToken ct = default)
    {
        var item = await _db.SpeakingItems.FirstOrDefaultAsync(s => s.Id == request.ItemId, ct)
            ?? throw new InvalidOperationException("تمرين التحدث غير موجود.");

        var result = _scorer.ScoreSpeech(item.English, request.RecognizedText);
        var xpAwarded = 0;

        if (result.Passed && userId.HasValue)
        {
            xpAwarded = 8;
            await _statsService.AwardXpAsync(userId.Value, xpAwarded, UserSkill.Speaking, item.Id, ct);
        }

        return new SpeakingScoreResponse(result.Score, result.Chips, result.Passed, xpAwarded);
    }
}

public interface ISpeakingService
{
    Task<SpeakingNextDto> GetNextAsync(DifficultyLevel level, CancellationToken ct = default);
    Task<SpeakingScoreResponse> ScoreAsync(SpeakingScoreRequest request, Guid? userId = null, CancellationToken ct = default);
}

public class PhonicsService : IPhonicsService
{
    private readonly IAlemniDbContext _db;

    public PhonicsService(IAlemniDbContext db)
    {
        _db = db;
    }

    public async Task<List<PhonicsItemDto>> GetPhonicsAsync(PhonicsKind? kind = null, string? category = null, string? search = null, CancellationToken ct = default)
    {
        var query = _db.PhonicsItems.AsQueryable();
        if (kind.HasValue) query = query.Where(p => p.Kind == kind.Value);
        if (!string.IsNullOrWhiteSpace(category))
        {
            var cat = category.Trim().ToLower();
            query = query.Where(p => p.Category.ToLower() == cat);
        }
        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(p => p.Symbol.ToLower().Contains(s) ||
                                     p.ArabicApprox.ToLower().Contains(s) ||
                                     p.IpaOrSpelling.ToLower().Contains(s) ||
                                     p.ExampleWordsJson.ToLower().Contains(s));
        }

        var list = await query.ToListAsync(ct);
        return list.Select(MapToDto).ToList();
    }

    public async Task<PhonicsItemDto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var p = await _db.PhonicsItems.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (p == null) return null;
        return MapToDto(p);
    }

    private static PhonicsItemDto MapToDto(PhonicsItem p)
    {
        var examples = JsonSerializer.Deserialize<List<string>>(p.ExampleWordsJson) ?? new List<string>();
        List<MinimalPairDto> minimalPairs;
        try
        {
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            minimalPairs = JsonSerializer.Deserialize<List<MinimalPairDto>>(p.MinimalPairsJson, options) ?? new List<MinimalPairDto>();
        }
        catch
        {
            minimalPairs = new List<MinimalPairDto>();
        }

        return new PhonicsItemDto(
            p.Id,
            p.Kind.ToString(),
            p.Category,
            p.Symbol,
            p.IpaOrSpelling,
            p.ArabicApprox,
            p.MouthTipAr,
            p.MouthDiagramType,
            examples,
            minimalPairs,
            p.TongueTwister,
            p.TongueTwisterAr,
            p.AudioUrl
        );
    }
}

public interface IPhonicsService
{
    Task<List<PhonicsItemDto>> GetPhonicsAsync(PhonicsKind? kind = null, string? category = null, string? search = null, CancellationToken ct = default);
    Task<PhonicsItemDto?> GetByIdAsync(Guid id, CancellationToken ct = default);
}

public class UserStatsService : IUserStatsService
{
    private readonly IAlemniDbContext _db;

    public UserStatsService(IAlemniDbContext db)
    {
        _db = db;
    }

    public async Task<UserStatsDto> GetStatsAsync(Guid userId, CancellationToken ct = default)
    {
        var stats = await _db.UserStats.FirstOrDefaultAsync(s => s.UserId == userId, ct);
        var wordsSaved = await _db.SavedWords.CountAsync(s => s.UserId == userId, ct);
        var completedSkills = await _db.UserProgress.CountAsync(p => p.UserId == userId, ct);

        if (stats == null)
        {
            return new UserStatsDto(0, 0, DateOnly.FromDateTime(DateTime.UtcNow), wordsSaved, completedSkills);
        }

        return new UserStatsDto(stats.Xp, stats.StreakDays, stats.LastActiveDate, wordsSaved, completedSkills);
    }

    public async Task AwardXpAsync(Guid userId, int xp, UserSkill skill, Guid itemId, CancellationToken ct = default)
    {
        var stats = await _db.UserStats.FirstOrDefaultAsync(s => s.UserId == userId, ct);
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        if (stats == null)
        {
            stats = new UserStats
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Xp = xp,
                StreakDays = 1,
                LastActiveDate = today
            };
            _db.UserStats.Add(stats);
        }
        else
        {
            stats.Xp += xp;

            // Streak tracking
            if (stats.LastActiveDate == today.AddDays(-1))
            {
                stats.StreakDays += 1;
                stats.LastActiveDate = today;
            }
            else if (stats.LastActiveDate != today)
            {
                stats.StreakDays = 1;
                stats.LastActiveDate = today;
            }
        }

        // Record UserProgress
        _db.UserProgress.Add(new UserProgress
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Skill = skill,
            ItemId = itemId,
            Score = xp,
            CompletedAt = DateTime.UtcNow
        });

        await _db.SaveChangesAsync(ct);
    }
}

public interface IUserStatsService
{
    Task<UserStatsDto> GetStatsAsync(Guid userId, CancellationToken ct = default);
    Task AwardXpAsync(Guid userId, int xp, UserSkill skill, Guid itemId, CancellationToken ct = default);
}

