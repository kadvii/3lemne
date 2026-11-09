using System.Security.Claims;
using Alemni.Application.DTOs;
using Alemni.Application.Services;
using Alemni.Domain.Enums;
using Microsoft.AspNetCore.Mvc;

namespace Alemni.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class SpeakingController : ControllerBase
{
    private readonly ISpeakingService _speakingService;

    public SpeakingController(ISpeakingService speakingService)
    {
        _speakingService = speakingService;
    }

    /// <summary>
    /// جلب تمرين التحدث التالي مع نصيحة النطق
    /// </summary>
    [HttpGet("next")]
    [ProducesResponseType(typeof(SpeakingNextDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetNext([FromQuery] DifficultyLevel level = DifficultyLevel.A1, CancellationToken ct = default)
    {
        var item = await _speakingService.GetNextAsync(level, ct);
        return Ok(item);
    }

    /// <summary>
    /// تقييم نطق المستخدم ومقارنة الكلمات كلمة بكلمة
    /// </summary>
    [HttpPost("score")]
    [ProducesResponseType(typeof(SpeakingScoreResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Score([FromBody] SpeakingScoreRequest request, CancellationToken ct = default)
    {
        var userId = GetUserId();
        var result = await _speakingService.ScoreAsync(request, userId, ct);
        return Ok(result);
    }

    private Guid? GetUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;
}

