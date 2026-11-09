using Alemni.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Alemni.Application.Common.Interfaces;

public interface IAlemniDbContext
{
    DbSet<User> Users { get; }
    DbSet<RefreshToken> RefreshTokens { get; }
    DbSet<UserStats> UserStats { get; }
    DbSet<UserProgress> UserProgress { get; }
    DbSet<Word> Words { get; }
    DbSet<SavedWord> SavedWords { get; }
    DbSet<WritingItem> WritingItems { get; }
    DbSet<Story> Stories { get; }
    DbSet<StorySentence> StorySentences { get; }
    DbSet<StoryQuestion> StoryQuestions { get; }
    DbSet<ListeningItem> ListeningItems { get; }
    DbSet<SpeakingItem> SpeakingItems { get; }
    DbSet<PhonicsItem> PhonicsItems { get; }
    DbSet<UserStoryHistory> UserStoryHistories { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}

