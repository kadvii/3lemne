using Alemni.Application.DTOs;
using Alemni.Application.Services;
using Alemni.Domain.Entities;
using Alemni.Domain.Enums;
using Alemni.Infrastructure.Data;
using Alemni.Infrastructure.Seed;
using FluentAssertions;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace Alemni.Tests;

public class SkillsAndEndpointsTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly AlemniDbContext _dbContext;
    private readonly IMorphologyService _morphology;
    private readonly ISpeechScoringService _speechScorer;
    private readonly IWordService _wordService;
    private readonly IWritingService _writingService;
    private readonly IReadingService _readingService;
    private readonly IListeningService _listeningService;
    private readonly ISpeakingService _speakingService;
    private readonly IPhonicsService _phonicsService;
    private readonly IUserStatsService _userStatsService;

    public SkillsAndEndpointsTests()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<AlemniDbContext>()
            .UseSqlite(_connection)
            .Options;

        _dbContext = new AlemniDbContext(options);
        _dbContext.Database.EnsureCreated();

        // Seed data
        var seeder = new DbSeeder(_dbContext, NullLogger<DbSeeder>.Instance);
        seeder.SeedAsync().GetAwaiter().GetResult();

        _morphology = new MorphologyService();
        _speechScorer = new SpeechScoringService();
        _userStatsService = new UserStatsService(_dbContext);
        _wordService = new WordService(_dbContext, _morphology);
        _writingService = new WritingService(_dbContext, _userStatsService);
        _readingService = new ReadingService(_dbContext, _userStatsService);
        _listeningService = new ListeningService(_dbContext, _userStatsService);
        _speakingService = new SpeakingService(_dbContext, _speechScorer, _userStatsService);
        _phonicsService = new PhonicsService(_dbContext);
    }

    public void Dispose()
    {
        _dbContext.Dispose();
        _connection.Close();
    }

    [Theory]
    [InlineData("water", "ماء", true, null)]
    [InlineData("running", null, true, "run")]
    [InlineData("stopped", null, true, "stop")]
    [InlineData("books", null, true, "book")]
    [InlineData("nonexistentword123", "لا يوجد معنى محفوظ لهذه الكلمة بعد", false, null)]
    public async Task Lookup_MorphologicalAndExact_ReturnsCorrectResults(
        string input, string? expectedArabic, bool expectedFound, string? expectedBase)
    {
        var result = await _wordService.LookupAsync(input);

        result.Found.Should().Be(expectedFound);
        if (expectedArabic != null)
        {
            result.Arabic.Should().Contain(expectedArabic);
        }
        if (expectedBase != null)
        {
            result.BaseWord.Should().Be(expectedBase);
        }
    }

    [Fact]
    public void ScoreSpeech_ExactMatch_Returns100Percent()
    {
        var target = "Hello, my name is Sara.";
        var said = "hello my name is sara";

        var result = _speechScorer.ScoreSpeech(target, said);

        result.Score.Should().Be(100);
        result.Passed.Should().BeTrue();
        result.Chips.Should().OnlyContain(c => c.Ok);
    }

    [Fact]
    public void ScoreSpeech_MinorTypo_ToleratesSmallDistance()
    {
        var target = "Every morning I wake up.";
        var said = "every mornin I wake up"; // "mornin" is 1 char difference from "morning" (length > 3)

        var result = _speechScorer.ScoreSpeech(target, said);

        result.Score.Should().Be(100);
        result.Passed.Should().BeTrue();
    }

    [Fact]
    public void ScoreSpeech_WrongWords_ScoresAccurately()
    {
        var target = "The weather is very cold today.";
        var said = "The dog was very hot today";

        var result = _speechScorer.ScoreSpeech(target, said);

        result.Score.Should().BeLessThan(80);
        result.Passed.Should().BeFalse();
        result.Chips.First(c => c.Word == "the").Ok.Should().BeTrue();
        result.Chips.First(c => c.Word == "weather").Ok.Should().BeFalse();
        result.Chips.First(c => c.Word == "cold").Ok.Should().BeFalse();
    }

    [Fact]
    public async Task Writing_CheckAnswer_Correct_AwardsXpAndValidatesLetters()
    {
        var word = await _dbContext.Words.FirstAsync(w => w.English == "school");
        var user = new User { Id = Guid.NewGuid(), Email = "writer@alemni.iq", DisplayName = "كاتب" };
        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync();

        var response = await _writingService.CheckAnswerAsync(
            new WritingCheckRequest(word.Id, "school"),
            user.Id
        );

        response.IsCorrect.Should().BeTrue();
        response.Word.Should().Be("school");
        response.Arabic.Should().Be(word.Arabic);
        response.XpAwarded.Should().Be(5);
        response.Letters.Should().OnlyContain(l => l.IsCorrect);

        var stats = await _userStatsService.GetStatsAsync(user.Id);
        stats.Xp.Should().Be(5);
    }

    [Fact]
    public async Task Writing_CheckAnswer_WithHintsPenalty_AwardsReducedXp()
    {
        var word = await _dbContext.Words.FirstAsync(w => w.English == "school");
        var user = new User { Id = Guid.NewGuid(), Email = "writer2@alemni.iq", DisplayName = "كاتب2" };
        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync();

        var response = await _writingService.CheckAnswerAsync(
            new WritingCheckRequest(word.Id, "school", HintsUsed: 2),
            user.Id
        );

        response.IsCorrect.Should().BeTrue();
        response.XpAwarded.Should().Be(3); // 5 - 2 = 3 XP
    }

    [Fact]
    public async Task Writing_CheckAnswer_Incorrect_ShowsDifferences()
    {
        var word = await _dbContext.Words.FirstAsync(w => w.English == "water");

        var response = await _writingService.CheckAnswerAsync(
            new WritingCheckRequest(word.Id, "wator")
        );

        response.IsCorrect.Should().BeFalse();
        response.Letters[3].Expected.Should().Be('e');
        response.Letters[3].Actual.Should().Be('o');
        response.Letters[3].IsCorrect.Should().BeFalse();
        response.XpAwarded.Should().Be(0);
    }

    [Fact]
    public async Task Listening_SubmitAnswer_ValidatesCorrectIndex()
    {
        var item = await _dbContext.ListeningItems.FirstAsync();

        var correctResponse = await _listeningService.SubmitAnswerAsync(
            new ListeningAnswerRequest(item.Id, item.CorrectAnswerIndex)
        );
        correctResponse.IsCorrect.Should().BeTrue();

        var wrongResponse = await _listeningService.SubmitAnswerAsync(
            new ListeningAnswerRequest(item.Id, (item.CorrectAnswerIndex + 1) % 3)
        );
        wrongResponse.IsCorrect.Should().BeFalse();
    }

    [Fact]
    public async Task Reading_SubmitAnswers_ComputesCorrectPercentage()
    {
        var story = await _dbContext.Stories.Include(s => s.Questions).FirstAsync();
        var correctIndices = story.Questions.Select(q => q.CorrectAnswerIndex).ToList();

        var response = await _readingService.SubmitAnswersAsync(
            story.Id,
            new StoryAnswersRequest(correctIndices)
        );

        response.Score.Should().Be(100);
        response.CorrectCount.Should().Be(story.Questions.Count);
        response.TotalQuestions.Should().Be(story.Questions.Count);
    }

    [Fact]
    public async Task Phonics_ReturnsItemsWithMouthTips()
    {
        var phonics = await _phonicsService.GetPhonicsAsync();

        phonics.Should().NotBeEmpty();
        phonics.Should().Contain(p => p.Symbol.Contains("P vs B"));
        phonics.First().MouthTipAr.Should().NotBeNullOrWhiteSpace();
        phonics.First().ExampleWords.Should().NotBeEmpty();
    }

    [Fact]
    public async Task Phonics_ReturnsAtLeast40Items_WithCategories_AndMinimalPairs()
    {
        var phonics = await _phonicsService.GetPhonicsAsync();

        phonics.Count.Should().BeGreaterThanOrEqualTo(40);

        var categories = phonics.Select(p => p.Category).Distinct().ToList();
        categories.Should().Contain("consonants");
        categories.Should().Contain("vowels");
        categories.Should().Contain("iraqi_challenges");
        categories.Should().Contain("endings_stress");

        foreach (var item in phonics)
        {
            item.MouthDiagramType.Should().NotBeNullOrWhiteSpace();
            item.MouthTipAr.Should().NotBeNullOrWhiteSpace();
            item.ExampleWords.Count.Should().BeGreaterThanOrEqualTo(8);
            item.MinimalPairs.Should().NotBeEmpty();
        }
    }

    [Fact]
    public async Task Phonics_FiltersByCategory_AndSearch()
    {
        var vowelsOnly = await _phonicsService.GetPhonicsAsync(category: "vowels");
        vowelsOnly.Should().NotBeEmpty();
        vowelsOnly.All(p => p.Category == "vowels").Should().BeTrue();

        var searchResult = await _phonicsService.GetPhonicsAsync(search: "school");
        searchResult.Should().NotBeEmpty();
        searchResult.Should().Contain(p => p.Symbol.Contains("sk"));
    }

    [Fact]
    public async Task ChineseWords_SeedAndQueryByLanguage_ReturnsHsk1Words()
    {
        var chineseWords = await _wordService.GetWordsAsync("zh");
        chineseWords.Should().NotBeNull();
        chineseWords.Count.Should().Be(50);

        var helloWord = chineseWords.FirstOrDefault(w => w.Word == "你好");
        helloWord.Should().NotBeNull();
        helloWord!.Pinyin.Should().Be("nǐ hǎo");
        helloWord.Arabic.Should().Be("مرحباً");
        helloWord.LanguageCode.Should().Be("zh");
    }
}

