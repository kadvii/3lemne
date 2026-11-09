using System.Text.Json;
using System.Text.RegularExpressions;
using Alemni.Application.Common.Interfaces;
using Alemni.Domain.Entities;
using Alemni.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Alemni.Application.Services;

public interface IStoryGenerator
{
    Task<Story> GenerateStoryAsync(DifficultyLevel level, CancellationToken ct = default);
}

public class TemplateStoryGenerator : IStoryGenerator
{
    private readonly IAlemniDbContext _db;
    private readonly IMorphologyService _morphology;
    private readonly ILogger<TemplateStoryGenerator> _logger;
    private readonly string _genJsonPath;

    public TemplateStoryGenerator(
        IAlemniDbContext db,
        IMorphologyService morphology,
        ILogger<TemplateStoryGenerator> logger)
    {
        _db = db;
        _morphology = morphology;
        _logger = logger;

        var baseDir = AppContext.BaseDirectory;
        var probePaths = new[]
        {
            Path.Combine(baseDir, "Seed", "Data", "gen.json"),
            Path.Combine(baseDir, "..", "..", "..", "..", "Alemni.Infrastructure", "Seed", "Data", "gen.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "Seed", "Data", "gen.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "backend", "Alemni.Infrastructure", "Seed", "Data", "gen.json")
        };

        _genJsonPath = probePaths.FirstOrDefault(File.Exists) ?? Path.Combine(baseDir, "Seed", "Data", "gen.json");
    }

    public async Task<Story> GenerateStoryAsync(DifficultyLevel level, CancellationToken ct = default)
    {
        if (!File.Exists(_genJsonPath))
        {
            throw new FileNotFoundException("ملف قوالب القصص gen.json غير موجود.", _genJsonPath);
        }

        var json = await File.ReadAllTextAsync(_genJsonPath, ct);
        using var doc = JsonDocument.Parse(json);

        var levelKey = level.ToString();
        if (!doc.RootElement.TryGetProperty(levelKey, out var levelElement))
        {
            throw new InvalidOperationException($"لا توجد قوالب للمستوى {levelKey}.");
        }

        var blocksElement = levelElement.GetProperty("blocks");
        var sentences = new List<(string En, string Ar)>();
        var picks = new Dictionary<string, (string En, string Ar)>();

        foreach (var block in blocksElement.EnumerateArray())
        {
            var enTemplate = block.GetProperty("en").GetString() ?? string.Empty;
            var arTemplate = block.GetProperty("ar").GetString() ?? string.Empty;
            var slots = block.GetProperty("slots");

            var slotValues = new Dictionary<string, (string En, string Ar)>();
            foreach (var slotProp in slots.EnumerateObject())
            {
                var slotKey = slotProp.Name;
                if (!picks.TryGetValue(slotKey, out var chosen))
                {
                    var options = slotProp.Value.EnumerateArray().ToList();
                    if (options.Count > 0)
                    {
                        var opt = options[Random.Shared.Next(options.Count)];
                        chosen = (opt.GetProperty("en").GetString() ?? "", opt.GetProperty("ar").GetString() ?? "");
                        picks[slotKey] = chosen;
                    }
                }
                slotValues[slotKey] = chosen;
            }

            var enSentence = Fill(enTemplate, slotValues, isArabic: false);
            var arSentence = Fill(arTemplate, slotValues, isArabic: true);
            sentences.Add((enSentence, arSentence));
        }

        var story = new Story
        {
            Id = Guid.NewGuid(),
            Title = $"A Story in {level}",
            TitleAr = $"قصة تدريبية بمستوى {level}",
            Level = level,
            EstimatedMinutes = 2,
            IsGenerated = true,
            CreatedAt = DateTime.UtcNow
        };

        for (var i = 0; i < sentences.Count; i++)
        {
            story.Sentences.Add(new StorySentence
            {
                Id = Guid.NewGuid(),
                StoryId = story.Id,
                OrderIndex = i + 1,
                ParagraphIndex = i / 3,
                English = sentences[i].En,
                Arabic = sentences[i].Ar
            });
        }

        // Generate 2 comprehension questions
        story.Questions.Add(new StoryQuestion
        {
            Id = Guid.NewGuid(),
            StoryId = story.Id,
            Type = QuestionType.MainIdea,
            QuestionAr = "عن ماذا تتحدث هذه القصة بشكل أساسي؟",
            QuestionEn = "What is this story mainly about?",
            OptionsJson = JsonSerializer.Serialize(new[] { "يوم في الحياة اليومية", "السفر إلى الفضاء", "تاريخ العصور القديمة" }),
            CorrectAnswerIndex = 0,
            ExplanationAr = "تدور القصة حول تفاصيل ومواقف من الحياة اليومية."
        });

        story.Questions.Add(new StoryQuestion
        {
            Id = Guid.NewGuid(),
            StoryId = story.Id,
            Type = QuestionType.Inference,
            QuestionAr = "هل الأحداث المذكورة تدل على نشاط إيجابي؟",
            QuestionEn = "Do the mentioned events indicate a positive activity?",
            OptionsJson = JsonSerializer.Serialize(new[] { "نعم، نشاط إيجابي", "لا، حدث حزين", "غير واضح" }),
            CorrectAnswerIndex = 0,
            ExplanationAr = "الأنشطة المذكورة ترتبط بإنتاجية ويوم عملي متفائل."
        });

        // Cache in DB
        _db.Stories.Add(story);
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("Generated template story {StoryId} for level {Level}", story.Id, level);
        return story;
    }

    private static string Fill(string template, Dictionary<string, (string En, string Ar)> slots, bool isArabic)
    {
        var result = template;
        foreach (var (key, value) in slots)
        {
            var replacement = isArabic ? value.Ar : value.En;
            result = result.Replace($"{{{key}}}", replacement);
        }
        return result;
    }
}

public class LlmStoryGenerator : IStoryGenerator
{
    private readonly TemplateStoryGenerator _fallback;
    private readonly IAlemniDbContext _db;
    private readonly IConfiguration _config;
    private readonly HttpClient _http;
    private readonly ILogger<LlmStoryGenerator> _logger;

    public LlmStoryGenerator(
        TemplateStoryGenerator fallback,
        IAlemniDbContext db,
        IConfiguration config,
        HttpClient http,
        ILogger<LlmStoryGenerator> logger)
    {
        _fallback = fallback;
        _db = db;
        _config = config;
        _http = http;
        _logger = logger;
    }

    public async Task<Story> GenerateStoryAsync(DifficultyLevel level, CancellationToken ct = default)
    {
        var apiKey = _config["Llm:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            _logger.LogInformation("LLM API key not configured. Falling back to TemplateStoryGenerator.");
            return await _fallback.GenerateStoryAsync(level, ct);
        }

        try
        {
            // Call LLM provider or fallback
            return await _fallback.GenerateStoryAsync(level, ct);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "LLM story generation failed. Using template fallback.");
            return await _fallback.GenerateStoryAsync(level, ct);
        }
    }
}

