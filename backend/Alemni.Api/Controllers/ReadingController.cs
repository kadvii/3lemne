using System.Security.Claims;
using Alemni.Application.DTOs;
using Alemni.Application.Services;
using Alemni.Domain.Enums;
using Microsoft.AspNetCore.Mvc;

namespace Alemni.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class ReadingController : ControllerBase
{
    private readonly IReadingService _readingService;
    private readonly IStoryGenerator _storyGenerator;

    public ReadingController(IReadingService readingService, IStoryGenerator storyGenerator)
    {
        _readingService = readingService;
        _storyGenerator = storyGenerator;
    }

    /// <summary>
    /// جلب قصة متدرجة جاهزة حسب المستوى مع الجمل وترجماتها وأسئلة الفهم
    /// </summary>
    [HttpGet("story")]
    [ProducesResponseType(typeof(ReadingStoryDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetStory([FromQuery] DifficultyLevel level = DifficultyLevel.A1, [FromQuery] Guid? excludeId = null, CancellationToken ct = default)
    {
        var story = await _readingService.GetStoryAsync(level, excludeId, ct);
        return Ok(story);
    }

    /// <summary>
    /// توليد قصة جديدة عند الطلب (عبر القوالب أو الذكاء الاصطناعي مع التحقق والـ Cache)
    /// </summary>
    [HttpPost("story/generate")]
    [ProducesResponseType(typeof(ReadingStoryDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GenerateStory([FromQuery] DifficultyLevel level = DifficultyLevel.A1, CancellationToken ct = default)
    {
        var story = await _storyGenerator.GenerateStoryAsync(level, ct);

        var sentenceDtos = story.Sentences.OrderBy(s => s.OrderIndex)
            .Select(s => new SentenceDto(s.OrderIndex, s.ParagraphIndex, s.English, s.Arabic)).ToList();
        var questionDtos = story.Questions.Select(q =>
        {
            var opts = System.Text.Json.JsonSerializer.Deserialize<List<string>>(q.OptionsJson) ?? new List<string>();
            return new QuestionDto(q.Id, q.Type.ToString(), q.QuestionAr, q.QuestionEn, opts, q.EvidenceSentenceIndex, q.ExplanationAr);
        }).ToList();

        var wordCount = story.Sentences.Sum(s => s.English.Split(' ', StringSplitOptions.RemoveEmptyEntries).Length);
        var estimatedMinutes = Math.Max(1, (int)Math.Ceiling(wordCount / 120.0));

        var dto = new ReadingStoryDto(story.Id, story.Title, story.TitleAr, story.Level.ToString(), wordCount, estimatedMinutes, sentenceDtos, questionDtos);
        return Ok(dto);
    }

    /// <summary>
    /// تسليم إجابات أسئلة الفهم للقصة واحتساب النتيجة والنقاط
    /// </summary>
    [HttpPost("story/{id:guid}/answers")]
    [ProducesResponseType(typeof(StoryAnswersResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> SubmitAnswers(Guid id, [FromBody] StoryAnswersRequest request, CancellationToken ct = default)
    {
        var userId = GetUserId();
        var result = await _readingService.SubmitAnswersAsync(id, request, userId, ct);
        return Ok(result);
    }

    private Guid? GetUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;
}
