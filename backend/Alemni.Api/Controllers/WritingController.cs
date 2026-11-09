using System.Security.Claims;
using Alemni.Application.DTOs;
using Alemni.Application.Services;
using Alemni.Domain.Enums;
using Microsoft.AspNetCore.Mvc;

namespace Alemni.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class WritingController : ControllerBase
{
    private readonly IWritingService _writingService;

    public WritingController(IWritingService writingService)
    {
        _writingService = writingService;
    }

    /// <summary>
    /// جلب كلمة الإملاء التالية حسب مستوى الصعوبة
    /// </summary>
    [HttpGet("next")]
    [ProducesResponseType(typeof(WritingNextDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetNext([FromQuery] DifficultyLevel level = DifficultyLevel.A1, CancellationToken ct = default)
    {
        var userId = GetUserId();
        var item = await _writingService.GetNextAsync(level, userId, ct);
        return Ok(item);
    }

    /// <summary>
    /// التحقق من إجابة المستخدم حرفًا بحرف واحتساب نقاط XP
    /// </summary>
    [HttpPost("check")]
    [ProducesResponseType(typeof(WritingCheckResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Check([FromBody] WritingCheckRequest request, CancellationToken ct = default)
    {
        var userId = GetUserId();
        var result = await _writingService.CheckAnswerAsync(request, userId, ct);
        return Ok(result);
    }

    private Guid? GetUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;
}

