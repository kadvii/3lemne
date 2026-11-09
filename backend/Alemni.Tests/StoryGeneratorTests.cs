using Alemni.Application.Services;
using Alemni.Domain.Enums;
using Alemni.Infrastructure.Data;
using Alemni.Infrastructure.Seed;
using FluentAssertions;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace Alemni.Tests;

public class StoryGeneratorTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly AlemniDbContext _dbContext;
    private readonly TemplateStoryGenerator _generator;

    public StoryGeneratorTests()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<AlemniDbContext>()
            .UseSqlite(_connection)
            .Options;

        _dbContext = new AlemniDbContext(options);
        _dbContext.Database.EnsureCreated();

        var seeder = new DbSeeder(_dbContext, NullLogger<DbSeeder>.Instance);
        seeder.SeedAsync().GetAwaiter().GetResult();

        var morphology = new MorphologyService();
        _generator = new TemplateStoryGenerator(_dbContext, morphology, NullLogger<TemplateStoryGenerator>.Instance);
    }

    public void Dispose()
    {
        _dbContext.Dispose();
        _connection.Close();
    }

    [Theory]
    [InlineData(DifficultyLevel.A1)]
    [InlineData(DifficultyLevel.A2)]
    [InlineData(DifficultyLevel.B1)]
    [InlineData(DifficultyLevel.B2)]
    public async Task GenerateStory_CreatesValidStory_CachedInDb(DifficultyLevel level)
    {
        var story = await _generator.GenerateStoryAsync(level);

        story.Should().NotBeNull();
        story.Level.Should().Be(level);
        story.IsGenerated.Should().BeTrue();
        story.Sentences.Should().NotBeEmpty();
        story.Questions.Count.Should().BeGreaterThanOrEqualTo(2);

        var savedStory = await _dbContext.Stories
            .Include(s => s.Sentences)
            .Include(s => s.Questions)
            .FirstOrDefaultAsync(s => s.Id == story.Id);

        savedStory.Should().NotBeNull();
        savedStory!.Sentences.Count.Should().Be(story.Sentences.Count);
    }
}
