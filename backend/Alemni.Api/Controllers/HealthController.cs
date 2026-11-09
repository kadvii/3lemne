using Microsoft.AspNetCore.Mvc;

namespace Alemni.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public IActionResult Get()
    {
        return Ok(new
        {
            status = "Healthy",
            app = "Alemni API",
            timestamp = DateTime.UtcNow,
            version = "1.0.0"
        });
    }
}

