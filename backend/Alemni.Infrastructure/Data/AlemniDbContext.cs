using Alemni.Application.Common.Interfaces;
using Alemni.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Alemni.Infrastructure.Data;

public class AlemniDbContext : DbContext, IAlemniDbContext
{
    public AlemniDbContext(DbContextOptions<AlemniDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<UserStats> UserStats => Set<UserStats>();
    public DbSet<UserProgress> UserProgress => Set<UserProgress>();
    public DbSet<Word> Words => Set<Word>();
    public DbSet<SavedWord> SavedWords => Set<SavedWord>();
    public DbSet<WritingItem> WritingItems => Set<WritingItem>();
    public DbSet<Story> Stories => Set<Story>();
    public DbSet<StorySentence> StorySentences => Set<StorySentence>();
    public DbSet<StoryQuestion> StoryQuestions => Set<StoryQuestion>();
    public DbSet<ListeningItem> ListeningItems => Set<ListeningItem>();
    public DbSet<SpeakingItem> SpeakingItems => Set<SpeakingItem>();
    public DbSet<PhonicsItem> PhonicsItems => Set<PhonicsItem>();
    public DbSet<UserStoryHistory> UserStoryHistories => Set<UserStoryHistory>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // User
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Email).IsUnique();
            entity.Property(e => e.Email).IsRequired().HasMaxLength(256);
            entity.Property(e => e.DisplayName).IsRequired().HasMaxLength(100);
            entity.Property(e => e.PasswordHash).IsRequired();
            entity.Property(e => e.Role).HasConversion<string>();

            entity.HasOne(e => e.Stats)
                  .WithOne(e => e.User)
                  .HasForeignKey<UserStats>(e => e.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // RefreshToken
        modelBuilder.Entity<RefreshToken>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.TokenHash).IsUnique();
            entity.HasIndex(e => e.UserId);
            entity.Property(e => e.TokenHash).IsRequired().HasMaxLength(128);

            entity.HasOne(e => e.User)
                  .WithMany(e => e.RefreshTokens)
                  .HasForeignKey(e => e.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // Word
        modelBuilder.Entity<Word>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.English);
            entity.Property(e => e.English).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Arabic).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Level).HasConversion<string>();
        });

        // SavedWord
        modelBuilder.Entity<SavedWord>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.UserId, e.WordId }).IsUnique();

            entity.HasOne(e => e.User)
                  .WithMany(e => e.SavedWords)
                  .HasForeignKey(e => e.UserId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Word)
                  .WithMany()
                  .HasForeignKey(e => e.WordId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // WritingItem
        modelBuilder.Entity<WritingItem>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Level).HasConversion<string>();

            entity.HasOne(e => e.Word)
                  .WithMany()
                  .HasForeignKey(e => e.WordId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // Story
        modelBuilder.Entity<Story>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Level).HasConversion<string>();
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            entity.Property(e => e.TitleAr).IsRequired().HasMaxLength(200);

            entity.HasMany(e => e.Sentences)
                  .WithOne(e => e.Story)
                  .HasForeignKey(e => e.StoryId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasMany(e => e.Questions)
                  .WithOne(e => e.Story)
                  .HasForeignKey(e => e.StoryId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // StoryQuestion
        modelBuilder.Entity<StoryQuestion>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Type).HasConversion<string>();
        });

        // ListeningItem
        modelBuilder.Entity<ListeningItem>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Level).HasConversion<string>();
            entity.Property(e => e.Type).HasConversion<string>();
        });

        // SpeakingItem
        modelBuilder.Entity<SpeakingItem>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Level).HasConversion<string>();
        });

        // PhonicsItem
        modelBuilder.Entity<PhonicsItem>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Kind).HasConversion<string>();
        });

        // UserProgress
        modelBuilder.Entity<UserProgress>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Skill).HasConversion<string>();
            entity.Property(e => e.Level).HasConversion<string>();
            entity.HasIndex(e => new { e.UserId, e.Skill, e.Level });

            entity.HasOne(e => e.User)
                  .WithMany(e => e.Progress)
                  .HasForeignKey(e => e.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
