using System.Security.Claims;
using Alemni.Application.DTOs;
using Alemni.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Alemni.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class WordsController : ControllerBase
{
    private readonly IWordService _wordService;

    public WordsController(IWordService wordService)
    {
        _wordService = wordService;
    }

    /// <summary>
    /// البحث في القاموس وترجمة الكلمة الإنجليزية مع معالجة التصريفات الصرفية (-ing, -ed, الجمع، إلخ)
    /// </summary>
    [HttpGet("lookup")]
    [ProducesResponseType(typeof(LookupResult), StatusCodes.Status200OK)]
    public async Task<IActionResult> Lookup([FromQuery] string q, CancellationToken ct)
    {
        var result = await _wordService.LookupAsync(q, ct);
        return Ok(result);
    }

    /// <summary>
    /// جلب قائمة المفردات المحفوظة للمستخدم المسجل
    /// </summary>
    [HttpGet("saved")]
    [Authorize]
    [ProducesResponseType(typeof(List<SavedWordDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSaved(CancellationToken ct)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var words = await _wordService.GetSavedWordsAsync(userId.Value, ct);
        return Ok(words);
    }

    /// <summary>
    /// حفظ كلمة في «مفرداتي»
    /// </summary>
    [HttpPost("saved")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> SaveWord([FromBody] SaveWordRequest request, CancellationToken ct)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        await _wordService.SaveWordAsync(userId.Value, request.WordId, ct);
        return NoContent();
    }

    /// <summary>
    /// إزالة كلمة من «مفرداتي»
    /// </summary>
    [HttpDelete("saved/{wordId:guid}")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UnsaveWord(Guid wordId, CancellationToken ct)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        await _wordService.UnsaveWordAsync(userId.Value, wordId, ct);
        return NoContent();
    }

    private Guid? GetUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;
}

