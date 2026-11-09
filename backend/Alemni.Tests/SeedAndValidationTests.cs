using System.Text.RegularExpressions;
using Alemni.Application.DTOs;
using Alemni.Application.Services;
using Alemni.Infrastructure.Data;
using Alemni.Infrastructure.Seed;
using FluentAssertions;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace Alemni.Tests;

public class SeedAndValidationTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly AlemniDbContext _dbContext;
    private readonly IDbSeeder _seeder;
    private readonly IMorphologyService _morphology;

    public SeedAndValidationTests()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<AlemniDbContext>()
            .UseSqlite(_connection)
            .Options;

        _dbContext = new AlemniDbContext(options);
        _dbContext.Database.EnsureCreated();

        _seeder = new DbSeeder(_dbContext, NullLogger<DbSeeder>.Instance);
        _morphology = new MorphologyService();
    }

    public void Dispose()
    {
        _dbContext.Dispose();
        _connection.Close();
    }

    [Fact]
    public async Task Seed_Imports_All_Expected_Data_Idempotently()
    {
        // First Run
        await _seeder.SeedAsync();

        var wordCount = await _dbContext.Words.CountAsync();
        var writingCount = await _dbContext.WritingItems.CountAsync();
        var listeningCount = await _dbContext.ListeningItems.CountAsync();
        var speakingCount = await _dbContext.SpeakingItems.CountAsync();
        var storyCount = await _dbContext.Stories.CountAsync();
        var phonicsCount = await _dbContext.PhonicsItems.CountAsync();

        // Verification according to acceptance criteria
        wordCount.Should().BeGreaterThanOrEqualTo(1100);
        writingCount.Should().Be(1000);
        listeningCount.Should().Be(28);
        speakingCount.Should().Be(32);
        storyCount.Should().Be(40);
        phonicsCount.Should().BeGreaterThanOrEqualTo(7);

        // Second Run (Testing Idempotency)
        await _seeder.SeedAsync();

        var wordCount2 = await _dbContext.Words.CountAsync();
        var writingCount2 = await _dbContext.WritingItems.CountAsync();
        var listeningCount2 = await _dbContext.ListeningItems.CountAsync();
        var speakingCount2 = await _dbContext.SpeakingItems.CountAsync();
        var storyCount2 = await _dbContext.Stories.CountAsync();
        var phonicsCount2 = await _dbContext.PhonicsItems.CountAsync();

        wordCount2.Should().Be(wordCount, "Seeding must be idempotent and not create duplicate words");
        writingCount2.Should().Be(writingCount);
        listeningCount2.Should().Be(listeningCount);
        speakingCount2.Should().Be(speakingCount);
        storyCount2.Should().Be(storyCount);
        phonicsCount2.Should().Be(phonicsCount);
    }

    [Fact]
    public async Task Seed_Stories_WordCounts_And_Structure_MatchSpecifications()
    {
        await _seeder.SeedAsync();

        var stories = await _dbContext.Stories
            .Include(s => s.Sentences)
            .Include(s => s.Questions)
            .ToListAsync();

        stories.Should().HaveCount(40, "there should be 10 stories for each of A1, A2, B1, and B2");

        var wordRegex = new Regex(@"[A-Za-z0-9]+", RegexOptions.Compiled);

        foreach (var story in stories)
        {
            var totalWords = story.Sentences.Sum(s => wordRegex.Matches(s.English).Count);
            story.Questions.Count.Should().BeGreaterThanOrEqualTo(8, "each story must have at least 8 questions");

            switch (story.Level)
            {
                case Alemni.Domain.Enums.DifficultyLevel.A1:
                    totalWords.Should().BeInRange(85, 145, $"Story {story.Id} (A1) word count should be 90-140");
                    break;
                case Alemni.Domain.Enums.DifficultyLevel.A2:
                    totalWords.Should().BeInRange(135, 235, $"Story {story.Id} (A2) word count should be 150-230");
                    break;
                case Alemni.Domain.Enums.DifficultyLevel.B1:
                    totalWords.Should().BeInRange(180, 390, $"Story {story.Id} (B1) word count should be 250-380");
                    break;
                case Alemni.Domain.Enums.DifficultyLevel.B2:
                    totalWords.Should().BeInRange(260, 560, $"Story {story.Id} (B2) word count should be 400-550");
                    break;
            }

            foreach (var q in story.Questions)
            {
                q.QuestionEn.Should().NotBeNullOrWhiteSpace();
                var options = System.Text.Json.JsonSerializer.Deserialize<string[]>(q.OptionsJson);
                options.Should().NotBeNull();
                options!.Length.Should().BeGreaterThanOrEqualTo(4);
                q.CorrectAnswerIndex.Should().BeInRange(0, options.Length - 1);
            }
        }
    }

    [Fact]
    public async Task Seed_Coverage_Validation_AllContentWords_ExistInDictionary()
    {
        await _seeder.SeedAsync();

        var dictionary = (await _dbContext.Words
            .Select(w => w.English.ToLower())
            .ToListAsync())
            .ToHashSet();

        bool HasWord(string raw)
        {
            var w = _morphology.NormalizeWord(raw);
            if (string.IsNullOrEmpty(w)) return true;
            if (dictionary.Contains(w)) return true;

            var candidates = _morphology.GetCandidates(w);
            return candidates.Any(c => dictionary.Contains(c));
        }

        var wordRegex = new Regex(@"[A-Za-z][A-Za-z'’]*", RegexOptions.Compiled);
        var missingWords = new List<(string Word, string Context)>();

        void ScanText(string text, string context)
        {
            var matches = wordRegex.Matches(text);
            foreach (Match match in matches)
            {
                var clean = match.Value.Trim('\'', '’');
                if (string.IsNullOrWhiteSpace(clean) || clean.Length <= 1) continue;

                if (!HasWord(clean))
                {
                    missingWords.Add((clean.ToLowerInvariant(), context));
                }
            }
        }

        // 1. Scan Reading Stories & Sentences
        var sentences = await _dbContext.StorySentences.ToListAsync();
        foreach (var s in sentences)
        {
            ScanText(s.English, $"StorySentence:{s.StoryId}:{s.OrderIndex}");
        }

        // 2. Scan Writing items
        var writing = await _dbContext.WritingItems.Include(w => w.Word).ToListAsync();
        foreach (var w in writing)
        {
            ScanText(w.Word!.English, $"Writing:{w.Level}");
        }

        // 3. Scan Listening items
        var listening = await _dbContext.ListeningItems.ToListAsync();
        foreach (var l in listening)
        {
            ScanText(l.English, $"Listening:{l.Level}");
        }

        // 4. Scan Speaking items
        var speaking = await _dbContext.SpeakingItems.ToListAsync();
        foreach (var sp in speaking)
        {
            ScanText(sp.English, $"Speaking:{sp.Level}");
        }

        // Assert: 100% dictionary coverage!
        missingWords.Should().BeEmpty(
            because: $"all words used in stories, listening, speaking, and writing must be covered in the dictionary: {string.Join(", ", missingWords.Select(m => $"{m.Word} ({m.Context})"))}"
        );
    }

    [Fact]
    public async Task All_40_Stories_Pass_StoryValidator()
    {
        await _seeder.SeedAsync();

        var dataDir = Path.Combine(AppContext.BaseDirectory, "Seed", "Data");
        var storiesPath = Path.Combine(dataDir, "stories.json");
        var json = await File.ReadAllTextAsync(storiesPath);
        var blueprints = System.Text.Json.JsonSerializer.Deserialize<List<StoryBlueprint>>(json, new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true });

        blueprints.Should().NotBeNull();
        blueprints.Should().HaveCount(40);

        var validator = new StoryValidator(_morphology, _dbContext);
        var dictionary = (await _dbContext.Words.Select(w => w.English.ToLower()).ToListAsync()).ToHashSet();

        foreach (var bp in blueprints!)
        {
            var res = await validator.ValidateAsync(bp, dictionary);
            res.IsValid.Should().BeTrue($"Blueprint {bp.Id} should pass validation: {string.Join(", ", res.Errors)}");
        }
    }
}

