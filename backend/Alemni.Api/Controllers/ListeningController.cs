using System.Security.Claims;
using Alemni.Application.DTOs;
using Alemni.Application.Services;
using Alemni.Domain.Enums;
using Microsoft.AspNetCore.Mvc;

namespace Alemni.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class ListeningController : ControllerBase
{
    private readonly IListeningService _listeningService;

    public ListeningController(IListeningService listeningService)
    {
        _listeningService = listeningService;
    }

    /// <summary>
    /// جلب تمرين الاستماع التالي (اختيار الجملة المنطوقة أو اختيار المعنى العربي)
    /// </summary>
    [HttpGet("next")]
    [ProducesResponseType(typeof(ListeningNextDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetNext(
        [FromQuery] DifficultyLevel level = DifficultyLevel.A1,
        [FromQuery] ListeningType? type = null,
        CancellationToken ct = default)
    {
        var item = await _listeningService.GetNextAsync(level, type, ct);
        return Ok(item);
    }

    /// <summary>
    /// تسليم إجابة تمرين الاستماع والتحقق من صحتها
    /// </summary>
    [HttpPost("answer")]
    [ProducesResponseType(typeof(ListeningAnswerResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> SubmitAnswer([FromBody] ListeningAnswerRequest request, CancellationToken ct = default)
    {
        var userId = GetUserId();
        var result = await _listeningService.SubmitAnswerAsync(request, userId, ct);
        return Ok(result);
    }

    private Guid? GetUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;
}

