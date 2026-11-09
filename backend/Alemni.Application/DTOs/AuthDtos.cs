namespace Alemni.Application.DTOs;

public record RegisterRequest(string Email, string Password, string DisplayName);

public record LoginRequest(string Email, string Password, string? DeviceInfo = null);

public record RefreshTokenRequest(string RefreshToken, string? DeviceInfo = null);

public record LogoutRequest(string RefreshToken);

public record UserDto(Guid Id, string Email, string DisplayName, string Role, int Xp, int StreakDays);

public record AuthResponse(string AccessToken, string RefreshToken, DateTime ExpiresAt, UserDto User);

