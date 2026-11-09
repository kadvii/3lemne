using Alemni.Application.DTOs;
using Alemni.Application.Services;
using FluentAssertions;
using Xunit;

namespace Alemni.Tests;

public class StoryValidatorTests
{
    private readonly IStoryValidator _validator;

    public StoryValidatorTests()
    {
        _validator = new StoryValidator(new MorphologyService());
    }

    private StoryBlueprint CreateValidA1Blueprint()
    {
        return new StoryBlueprint
        {
            Id = "a1-test-story-01",
            Level = "A1",
            Genre = "everyday",
            Title = "The Lost Cat in Baghdad",
            TitleAr = "القطة الضائعة في بغداد",
            Emoji = "🐈",
            Characters = new List<CharacterDto>
            {
                new() { Name = "Zainab", Role = "girl" },
                new() { Name = "Mimi", Role = "cat" }
            },
            Setting = "a quiet street near the river",
            Facts = new List<FactDto>
            {
                new() { Id = "f1", Key = "cat_color", Value = "white", Sentence = 2 },
                new() { Id = "f2", Key = "where_found", Value = "under a green bench", Sentence = 5 },
                new() { Id = "f3", Key = "drank_what", Value = "warm milk", Sentence = 7 }
            },
            Text = new List<string>
            {
                "Zainab is a young girl living in Baghdad near the river. She has a small white cat named Mimi. Every day after school, Zainab plays with her pet in the garden.",
                "One sunny afternoon, Mimi walked outside and did not return. Zainab looked for her everywhere in the neighborhood.",
                "She asked her kind neighbor Omar for help. They walked down the quiet street together calling her name loudly.",
                "Finally, Zainab saw Mimi hiding under a green bench. The happy cat ran to her arms quickly.",
                "They walked back home together smiling. Zainab gave Mimi warm milk and felt great peace. Her mother prepared hot tea."
            },
            QuestionPool = new List<BlueprintQuestionDto>
            {
                new() { Id = "q1", Type = "detail", Q = "What color is Mimi the cat?", Correct = "white", Distractors = new() { "black", "orange", "gray" }, FactId = "f1" },
                new() { Id = "q2", Type = "detail", Q = "Where was Mimi hiding?", Correct = "under a green bench", Distractors = new() { "in a tall tree", "inside a car", "near the bridge" }, FactId = "f2" },
                new() { Id = "q3", Type = "detail", Q = "What did Zainab give Mimi at home?", Correct = "warm milk", Distractors = new() { "cold water", "fresh meat", "dry bread" }, FactId = "f3" },
                new() { Id = "q4", Type = "detail", Q = "Who is the owner of the cat?", Correct = "Zainab", Distractors = new() { "Noor", "Lina", "Maryam" }, FactId = "f1" },
                new() { Id = "q5", Type = "detail", Q = "Where did Zainab live?", Correct = "Baghdad", Distractors = new() { "Basra", "Erbil", "Najaf" }, FactId = "f1" },
                new() { Id = "q6", Type = "cause", Q = "Why was Zainab worried?", Correct = "Mimi did not return", Distractors = new() { "she lost her book", "the weather was cold", "school was closed" }, FactId = "f1" },
                new() { Id = "q7", Type = "detail", Q = "Who helped Zainab search for Mimi?", Correct = "neighbor Omar", Distractors = new() { "a police officer", "her school teacher", "her little brother" }, FactId = "f2" },
                new() { Id = "q8", Type = "main_idea", Q = "What is the main idea of this story?", Correct = "finding a lost pet", Distractors = new() { "buying a new car", "cooking a big meal", "traveling to another city" }, FactId = "f2" }
            }
        };
    }

    [Fact]
    public async Task Validate_ValidBlueprint_PassesWithNoErrors()
    {
        var blueprint = CreateValidA1Blueprint();
        var result = await _validator.ValidateAsync(blueprint);

        result.Errors.Should().BeEmpty();
        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public async Task Validate_RegressionTest_QuestionMentionsSara_WhenStoryIsAboutHassan_Fails()
    {
        // Recreates the exact bug from user screenshot:
        // Story characters are Hassan and his classmates, but question asks about Sara!
        var blueprint = CreateValidA1Blueprint();
        blueprint.Characters = new List<CharacterDto>
        {
            new() { Name = "Hassan", Role = "student" },
            new() { Name = "Mr. Kareem", Role = "teacher" }
        };

        // Malicious / mismatched question mentioning Sara
        blueprint.QuestionPool[0].Q = "How did Sara travel to her school every morning?";

        var result = await _validator.ValidateAsync(blueprint);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.Contains("Sara") && e.Contains("does not exist in the story"));
    }

    [Fact]
    public async Task Validate_DistractorMatchesCorrectAnswer_Fails()
    {
        var blueprint = CreateValidA1Blueprint();
        blueprint.QuestionPool[0].Distractors = new List<string> { "black", "white", "gray" }; // "white" matches correct!

        var result = await _validator.ValidateAsync(blueprint);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.Contains("matches the correct answer"));
    }

    [Fact]
    public async Task Validate_QuestionPoolLessThan8_Fails()
    {
        var blueprint = CreateValidA1Blueprint();
        blueprint.QuestionPool.RemoveRange(0, 3); // Now only 5 questions

        var result = await _validator.ValidateAsync(blueprint);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.Contains("at least 8 questions"));
    }

    [Fact]
    public async Task Validate_WordCountOutOfRange_Fails()
    {
        var blueprint = CreateValidA1Blueprint();
        blueprint.Level = "A1";
        blueprint.Text = new List<string> { "Only seven words in this tiny text." };

        var result = await _validator.ValidateAsync(blueprint);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.Contains("word count must be between"));
    }

    [Fact]
    public async Task Validate_QuestionReferencesNonExistentFact_Fails()
    {
        var blueprint = CreateValidA1Blueprint();
        blueprint.QuestionPool[0].FactId = "f999"; // Non-existent

        var result = await _validator.ValidateAsync(blueprint);

        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.Contains("factId 'f999' which does not exist"));
    }
}
