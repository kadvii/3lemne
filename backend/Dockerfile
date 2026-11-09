FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution and csproj files for layer caching
COPY Alemni.sln ./
COPY Alemni.Domain/Alemni.Domain.csproj Alemni.Domain/
COPY Alemni.Application/Alemni.Application.csproj Alemni.Application/
COPY Alemni.Infrastructure/Alemni.Infrastructure.csproj Alemni.Infrastructure/
COPY Alemni.Api/Alemni.Api.csproj Alemni.Api/
COPY Alemni.Tests/Alemni.Tests.csproj Alemni.Tests/

RUN dotnet restore Alemni.sln

# Copy all source files
COPY . .

# Run tests during build
WORKDIR /src/Alemni.Tests
RUN dotnet build -c Release

# Publish API
WORKDIR /src/Alemni.Api
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Development

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Alemni.Api.dll"]

