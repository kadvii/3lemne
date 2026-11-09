using System.Security.Claims;
using Alemni.Application.DTOs;
using Alemni.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Alemni.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
[Produces("application/json")]
public class MeController : ControllerBase
{
    private readonly IUserStatsService _statsService;

    public MeController(IUserStatsService statsService)
    {
        _statsService = statsService;
    }

    /// <summary>
    /// جلب إحصائيات المستخدم الحالي (نقاط XP، أيام الاستمرار Streak، عدد الكلمات المحفوظة)
    /// </summary>
    [HttpGet("stats")]
    [ProducesResponseType(typeof(UserStatsDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetStats(CancellationToken ct)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var stats = await _statsService.GetStatsAsync(userId.Value, ct);
        return Ok(stats);
    }

    private Guid? GetUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;
}

