using Alemni.Application.Common.Interfaces;
using Alemni.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Alemni.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection") 
            ?? "Host=localhost;Port=5432;Database=alemni_db;Username=alemni_user;Password=alemni_secret";

        services.AddDbContext<AlemniDbContext>(options =>
        {
            if (connectionString.Contains("Data Source=", StringComparison.OrdinalIgnoreCase) || 
                connectionString.EndsWith(".db", StringComparison.OrdinalIgnoreCase))
            {
                options.UseSqlite(connectionString);
            }
            else
            {
                options.UseNpgsql(connectionString);
            }
        });

        services.AddScoped<IAlemniDbContext>(provider => provider.GetRequiredService<AlemniDbContext>());
        services.AddScoped<Alemni.Infrastructure.Seed.IDbSeeder, Alemni.Infrastructure.Seed.DbSeeder>();

        return services;
    }
}
