using Alemni.Application.DTOs;
using Alemni.Application.Services;
using Alemni.Domain.Enums;
using Microsoft.AspNetCore.Mvc;

namespace Alemni.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class PhonicsController : ControllerBase
{
    private readonly IPhonicsService _phonicsService;

    public PhonicsController(IPhonicsService phonicsService)
    {
        _phonicsService = phonicsService;
    }

    /// <summary>
    /// جلب قائمة مخارج الحروف وحروف العلة والأصوات الصعبة على المتحدث العربي
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(List<PhonicsItemDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(
        [FromQuery] PhonicsKind? kind = null,
        [FromQuery] string? category = null,
        [FromQuery] string? search = null,
        CancellationToken ct = default)
    {
        var items = await _phonicsService.GetPhonicsAsync(kind, category, search, ct);
        return Ok(items);
    }

    /// <summary>
    /// جلب تفاصيل صوت معين مع وضع الفم وأمثلة النطق
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(PhonicsItemDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct = default)
    {
        var item = await _phonicsService.GetByIdAsync(id, ct);
        if (item == null) return NotFound();
        return Ok(item);
    }
}

