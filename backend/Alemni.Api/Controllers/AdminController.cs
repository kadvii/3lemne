using Alemni.Application.Common.Interfaces;
using Alemni.Application.DTOs;
using Alemni.Domain.Entities;
using Alemni.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Alemni.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
[Produces("application/json")]
public class AdminController : ControllerBase
{
    private readonly IAlemniDbContext _db;

    public AdminController(IAlemniDbContext db)
    {
        _db = db;
    }

    /// <summary>
    /// جلب إحصائيات لوحة التحكم وتحليلات المنصة
    /// </summary>
    [HttpGet("analytics")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAnalytics(CancellationToken ct)
    {
        var totalUsers = await _db.Users.CountAsync(ct);
        var totalWords = await _db.Words.CountAsync(ct);
        var totalStories = await _db.Stories.CountAsync(ct);
        var totalListening = await _db.ListeningItems.CountAsync(ct);
        var totalSpeaking = await _db.SpeakingItems.CountAsync(ct);
        var totalProgress = await _db.UserProgress.CountAsync(ct);

        var skillBreakdown = await _db.UserProgress
            .GroupBy(p => p.Skill)
            .Select(g => new { Skill = g.Key.ToString(), Count = g.Count() })
            .ToListAsync(ct);

        return Ok(new
        {
            totalUsers,
            totalWords,
            totalStories,
            totalListening,
            totalSpeaking,
            totalExercisesCompleted = totalProgress,
            skillBreakdown
        });
    }

    /// <summary>
    /// جلب قائمة المستخدمين والنشاط
    /// </summary>
    [HttpGet("users")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetUsers([FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken ct = default)
    {
        var query = _db.Users
            .Include(u => u.Stats)
            .OrderByDescending(u => u.CreatedAt);

        var total = await query.CountAsync(ct);
        var users = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new
            {
                u.Id,
                u.Email,
                u.DisplayName,
                Role = u.Role.ToString(),
                u.CreatedAt,
                Xp = u.Stats != null ? u.Stats.Xp : 0,
                StreakDays = u.Stats != null ? u.Stats.StreakDays : 0,
                LastActiveDate = u.Stats != null ? u.Stats.LastActiveDate.ToString() : null
            })
            .ToListAsync(ct);

        return Ok(new { total, page, pageSize, users });
    }

    /// <summary>
    /// إدارة الكلمات: قائمة وتصفية
    /// </summary>
    [HttpGet("words")]
    public async Task<IActionResult> GetWords([FromQuery] string? search, [FromQuery] DifficultyLevel? level, [FromQuery] int page = 1, [FromQuery] int pageSize = 50, CancellationToken ct = default)
    {
        var query = _db.Words.AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(w => w.English.ToLower().Contains(s) || w.Arabic.Contains(s));
        }

        if (level.HasValue)
        {
            query = query.Where(w => w.Level == level.Value);
        }

        var total = await query.CountAsync(ct);
        var items = await query.OrderBy(w => w.English).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return Ok(new { total, page, pageSize, items });
    }

    /// <summary>
    /// إضافة كلمة جديدة للقاموس
    /// </summary>
    [HttpPost("words")]
    public async Task<IActionResult> CreateWord([FromBody] Word word, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(word.English) || string.IsNullOrWhiteSpace(word.Arabic))
        {
            return BadRequest("الكلمة الإنجليزية والترجمة العربية مطلوبتان.");
        }

        word.Id = Guid.NewGuid();
        _db.Words.Add(word);
        await _db.SaveChangesAsync(ct);
        return Created($"/api/admin/words/{word.Id}", word);
    }

    /// <summary>
    /// حذف كلمة
    /// </summary>
    [HttpDelete("words/{id:guid}")]
    public async Task<IActionResult> DeleteWord(Guid id, CancellationToken ct)
    {
        var word = await _db.Words.FirstOrDefaultAsync(w => w.Id == id, ct);
        if (word == null) return NotFound();

        _db.Words.Remove(word);
        await _db.SaveChangesAsync(ct);
        return NoContent();
    }
}

