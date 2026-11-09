using Alemni.Application.Common.Interfaces;
using Alemni.Application.Common.Security;
using Alemni.Application.DTOs;
using Alemni.Domain.Entities;
using Alemni.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Alemni.Application.Services;

public interface IAuthService
{
    Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken ct = default);
    Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken ct = default);
    Task<AuthResponse> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken ct = default);
    Task LogoutAsync(LogoutRequest request, CancellationToken ct = default);
}

public class AuthService : IAuthService
{
    private readonly IAlemniDbContext _db;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;

    public AuthService(
        IAlemniDbContext db,
        IPasswordHasher passwordHasher,
        ITokenService tokenService)
    {
        _db = db;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();

        var exists = await _db.Users.AnyAsync(u => u.Email.ToLower() == normalizedEmail, ct);
        if (exists)
        {
            throw new InvalidOperationException("البريد الإلكتروني مسجل مسبقًا.");
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = normalizedEmail,
            DisplayName = request.DisplayName.Trim(),
            PasswordHash = _passwordHasher.HashPassword(request.Password),
            Role = UserRole.Learner,
            CreatedAt = DateTime.UtcNow,
            Stats = new UserStats
            {
                Id = Guid.NewGuid(),
                Xp = 0,
                StreakDays = 1,
                LastActiveDate = DateOnly.FromDateTime(DateTime.UtcNow)
            }
        };

        _db.Users.Add(user);

        var (rawRefreshToken, tokenHash, expiresAt) = _tokenService.GenerateRefreshToken();
        var refreshToken = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = tokenHash,
            ExpiresAt = expiresAt,
            CreatedAt = DateTime.UtcNow
        };

        _db.RefreshTokens.Add(refreshToken);
        await _db.SaveChangesAsync(ct);

        var accessToken = _tokenService.GenerateAccessToken(user);
        var userDto = new UserDto(user.Id, user.Email, user.DisplayName, user.Role.ToString(), user.Stats.Xp, user.Stats.StreakDays);

        return new AuthResponse(accessToken, rawRefreshToken, expiresAt, userDto);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();

        var user = await _db.Users
            .Include(u => u.Stats)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == normalizedEmail, ct);

        if (user == null || !_passwordHasher.VerifyPassword(request.Password, user.PasswordHash))
        {
            throw new UnauthorizedAccessException("البريد الإلكتروني أو كلمة المرور غير صحيحة.");
        }

        var (rawRefreshToken, tokenHash, expiresAt) = _tokenService.GenerateRefreshToken();
        var refreshToken = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = tokenHash,
            ExpiresAt = expiresAt,
            DeviceInfo = request.DeviceInfo,
            CreatedAt = DateTime.UtcNow
        };

        _db.RefreshTokens.Add(refreshToken);
        await _db.SaveChangesAsync(ct);

        var accessToken = _tokenService.GenerateAccessToken(user);
        var stats = user.Stats ?? new UserStats();
        var userDto = new UserDto(user.Id, user.Email, user.DisplayName, user.Role.ToString(), stats.Xp, stats.StreakDays);

        return new AuthResponse(accessToken, rawRefreshToken, expiresAt, userDto);
    }

    public async Task<AuthResponse> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken ct = default)
    {
        var incomingHash = _tokenService.HashToken(request.RefreshToken);

        var tokenRecord = await _db.RefreshTokens
            .Include(t => t.User)
            .ThenInclude(u => u!.Stats)
            .FirstOrDefaultAsync(t => t.TokenHash == incomingHash, ct);

        if (tokenRecord == null)
        {
            throw new UnauthorizedAccessException("رمز التحديث غير صالح.");
        }

        // Reuse detection: إذا تم استخدام رمز تم إبطاله أو استبداله مسبقًا، يتم إلغاء كل جلسات المستخدم!
        if (tokenRecord.IsRevoked || tokenRecord.ReplacedByTokenHash != null)
        {
            var compromisedUserId = tokenRecord.UserId;
            var activeTokens = await _db.RefreshTokens
                .Where(t => t.UserId == compromisedUserId && t.RevokedAt == null)
                .ToListAsync(ct);

            foreach (var activeToken in activeTokens)
            {
                activeToken.RevokedAt = DateTime.UtcNow;
            }

            await _db.SaveChangesAsync(ct);

            throw new UnauthorizedAccessException("تم اكتشاف محاولة إعادة استخدام رمز منتهٍ — تم إلغاء جميع الجلسات النشطة لحماية حسابك.");
        }

        if (tokenRecord.IsExpired)
        {
            throw new UnauthorizedAccessException("انتهت صلاحية رمز التحديث، يرجى تسجيل الدخول مجددًا.");
        }

        // Token Rotation: إلغاء الرمز القديم وإصدار رمز جديد مرتبط به
        var (newRawToken, newTokenHash, newExpiresAt) = _tokenService.GenerateRefreshToken();

        tokenRecord.RevokedAt = DateTime.UtcNow;
        tokenRecord.ReplacedByTokenHash = newTokenHash;

        var newRefreshToken = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = tokenRecord.UserId,
            TokenHash = newTokenHash,
            ExpiresAt = newExpiresAt,
            DeviceInfo = request.DeviceInfo ?? tokenRecord.DeviceInfo,
            CreatedAt = DateTime.UtcNow
        };

        _db.RefreshTokens.Add(newRefreshToken);
        await _db.SaveChangesAsync(ct);

        var user = tokenRecord.User!;
        var stats = user.Stats ?? new UserStats();
        var accessToken = _tokenService.GenerateAccessToken(user);
        var userDto = new UserDto(user.Id, user.Email, user.DisplayName, user.Role.ToString(), stats.Xp, stats.StreakDays);

        return new AuthResponse(accessToken, newRawToken, newExpiresAt, userDto);
    }

    public async Task LogoutAsync(LogoutRequest request, CancellationToken ct = default)
    {
        var incomingHash = _tokenService.HashToken(request.RefreshToken);

        var tokenRecord = await _db.RefreshTokens
            .FirstOrDefaultAsync(t => t.TokenHash == incomingHash && t.RevokedAt == null, ct);

        if (tokenRecord != null)
        {
            tokenRecord.RevokedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync(ct);
        }
    }
}

