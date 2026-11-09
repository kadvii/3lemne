using Alemni.Application.Common.Security;
using Alemni.Application.Services;
using FluentValidation;
using Microsoft.Extensions.DependencyInjection;

namespace Alemni.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly);

        services.AddSingleton<IPasswordHasher, PasswordHasher>();
        services.AddSingleton<IMorphologyService, MorphologyService>();
        services.AddSingleton<ISpeechScoringService, SpeechScoringService>();

        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IWordService, WordService>();
        services.AddScoped<IWritingService, WritingService>();
        services.AddScoped<IReadingService, ReadingService>();
        services.AddScoped<IListeningService, ListeningService>();
        services.AddScoped<ISpeakingService, SpeakingService>();
        services.AddScoped<IPhonicsService, PhonicsService>();
        services.AddScoped<IUserStatsService, UserStatsService>();
        services.AddScoped<TemplateStoryGenerator>();
        services.AddScoped<IStoryGenerator, LlmStoryGenerator>();
        services.AddScoped<IStoryValidator, StoryValidator>();
        services.AddHttpClient();

        return services;
    }
}
