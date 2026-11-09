using Alemni.Application.Common.Security;
using Alemni.Application.DTOs;
using Alemni.Application.Services;
using Alemni.Infrastructure.Data;
using FluentAssertions;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace Alemni.Tests;

public class AuthServiceTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly AlemniDbContext _dbContext;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly IAuthService _authService;

    public AuthServiceTests()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<AlemniDbContext>()
            .UseSqlite(_connection)
            .Options;

        _dbContext = new AlemniDbContext(options);
        _dbContext.Database.EnsureCreated();

        _passwordHasher = new PasswordHasher();

        var inMemorySettings = new Dictionary<string, string?>
        {
            {"Jwt:SecretKey", "test_secret_key_32_characters_long_for_security_testing!"},
            {"Jwt:Issuer", "TestAlemni"},
            {"Jwt:Audience", "TestAlemniApp"},
            {"Jwt:AccessTokenMinutes", "15"},
            {"Jwt:RefreshTokenDays", "30"}
        };
        var config = new ConfigurationBuilder().AddInMemoryCollection(inMemorySettings).Build();
        _tokenService = new TokenService(config);

        _authService = new AuthService(_dbContext, _passwordHasher, _tokenService);
    }

    public void Dispose()
    {
        _dbContext.Dispose();
        _connection.Close();
    }

    [Fact]
    public async Task Register_WithValidData_CreatesUserAndReturnsTokens()
    {
        var request = new RegisterRequest("learner@alemni.iq", "P@ssw0rd123", "أحمد العراقي");

        var response = await _authService.RegisterAsync(request);

        response.Should().NotBeNull();
        response.AccessToken.Should().NotBeNullOrWhiteSpace();
        response.RefreshToken.Should().NotBeNullOrWhiteSpace();
        response.User.Email.Should().Be("learner@alemni.iq");
        response.User.DisplayName.Should().Be("أحمد العراقي");
        response.User.Xp.Should().Be(0);
        response.User.StreakDays.Should().Be(1);

        var savedUser = await _dbContext.Users.Include(u => u.Stats).FirstOrDefaultAsync(u => u.Email == "learner@alemni.iq");
        savedUser.Should().NotBeNull();
        savedUser!.Stats.Should().NotBeNull();
        _passwordHasher.VerifyPassword("P@ssw0rd123", savedUser.PasswordHash).Should().BeTrue();
    }

    [Fact]
    public async Task Register_WithDuplicateEmail_ThrowsInvalidOperationException()
    {
        var request = new RegisterRequest("duplicate@alemni.iq", "secret123", "User One");
        await _authService.RegisterAsync(request);

        var duplicateAction = async () => await _authService.RegisterAsync(new RegisterRequest("duplicate@alemni.iq", "otherPassword", "User Two"));

        await duplicateAction.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*مسجل مسبقًا*");
    }

    [Fact]
    public async Task Login_WithCorrectCredentials_ReturnsAuthResponse()
    {
        var email = "login@alemni.iq";
        var password = "CorrectPassword123";
        await _authService.RegisterAsync(new RegisterRequest(email, password, "متعلم نشط"));

        var response = await _authService.LoginAsync(new LoginRequest(email, password, "Pixel 8"));

        response.Should().NotBeNull();
        response.AccessToken.Should().NotBeNullOrWhiteSpace();
        response.RefreshToken.Should().NotBeNullOrWhiteSpace();
        response.User.Email.Should().Be(email);
    }

    [Fact]
    public async Task Login_WithWrongPassword_ThrowsUnauthorizedAccessException()
    {
        var email = "wrongpass@alemni.iq";
        await _authService.RegisterAsync(new RegisterRequest(email, "MySecretPass", "سارة"));

        var loginAction = async () => await _authService.LoginAsync(new LoginRequest(email, "WrongPass123"));

        await loginAction.Should().ThrowAsync<UnauthorizedAccessException>()
            .WithMessage("*غير صحيحة*");
    }

    [Fact]
    public async Task RefreshToken_WithValidToken_RotatesTokenAndRevokesOld()
    {
        var registerResponse = await _authService.RegisterAsync(new RegisterRequest("rotate@alemni.iq", "Pass123", "علي"));
        var originalRefreshToken = registerResponse.RefreshToken;

        var refreshResponse = await _authService.RefreshTokenAsync(new RefreshTokenRequest(originalRefreshToken));

        refreshResponse.Should().NotBeNull();
        refreshResponse.AccessToken.Should().NotBeNullOrWhiteSpace();
        refreshResponse.RefreshToken.Should().NotBeNullOrWhiteSpace();
        refreshResponse.RefreshToken.Should().NotBe(originalRefreshToken);

        var oldHash = _tokenService.HashToken(originalRefreshToken);
        var oldToken = await _dbContext.RefreshTokens.FirstOrDefaultAsync(t => t.TokenHash == oldHash);
        oldToken.Should().NotBeNull();
        oldToken!.RevokedAt.Should().NotBeNull();
        oldToken.ReplacedByTokenHash.Should().NotBeNull();
    }

    [Fact]
    public async Task RefreshToken_ReuseDetection_RevokesAllUserSessions()
    {
        // 1. Register & get initial token
        var registerResponse = await _authService.RegisterAsync(new RegisterRequest("victim@alemni.iq", "Pass123", "زينب"));
        var tokenA = registerResponse.RefreshToken;

        // 2. Normal rotation: Token A is consumed -> Token B issued
        var refreshResponse = await _authService.RefreshTokenAsync(new RefreshTokenRequest(tokenA));
        var tokenB = refreshResponse.RefreshToken;

        // 3. An attacker re-uses Token A!
        var reuseAction = async () => await _authService.RefreshTokenAsync(new RefreshTokenRequest(tokenA));

        await reuseAction.Should().ThrowAsync<UnauthorizedAccessException>()
            .WithMessage("*إعادة استخدام رمز*");

        // 4. Verify that Token B (active token) was also invalidated due to reuse detection
        var tokenBHash = _tokenService.HashToken(tokenB);
        var tokenBRecord = await _dbContext.RefreshTokens.FirstOrDefaultAsync(t => t.TokenHash == tokenBHash);
        tokenBRecord.Should().NotBeNull();
        tokenBRecord!.RevokedAt.Should().NotBeNull("All user tokens must be revoked upon reuse detection!");
    }

    [Fact]
    public async Task Logout_RevokesActiveRefreshToken()
    {
        var registerResponse = await _authService.RegisterAsync(new RegisterRequest("logout@alemni.iq", "Pass123", "حسين"));
        var rawToken = registerResponse.RefreshToken;

        await _authService.LogoutAsync(new LogoutRequest(rawToken));

        var hash = _tokenService.HashToken(rawToken);
        var tokenRecord = await _dbContext.RefreshTokens.FirstOrDefaultAsync(t => t.TokenHash == hash);
        tokenRecord.Should().NotBeNull();
        tokenRecord!.RevokedAt.Should().NotBeNull();
    }
}

