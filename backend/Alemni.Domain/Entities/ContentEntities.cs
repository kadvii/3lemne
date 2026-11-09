using Alemni.Domain.Enums;

namespace Alemni.Domain.Entities;

public class Word
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string English { get; set; } = string.Empty;
    public string Arabic { get; set; } = string.Empty;
    public DifficultyLevel Level { get; set; } = DifficultyLevel.A1;
    public string? PartOfSpeech { get; set; }
    public string? BaseWord { get; set; }
    public string? ExampleEn { get; set; }
    public string? ExampleAr { get; set; }
}

public class SavedWord
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public Guid WordId { get; set; }
    public Word? Word { get; set; }
    public DateTime AddedAt { get; set; } = DateTime.UtcNow;
}

public class WritingItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid WordId { get; set; }
    public Word? Word { get; set; }
    public DifficultyLevel Level { get; set; }
    public int OrderIndex { get; set; }
}

public class Story
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Title { get; set; } = string.Empty;
    public string TitleAr { get; set; } = string.Empty;
    public DifficultyLevel Level { get; set; }
    public string Genre { get; set; } = "everyday";
    public string Emoji { get; set; } = "📖";
    public string Setting { get; set; } = string.Empty;
    public string CharactersJson { get; set; } = "[]";
    public string FactsJson { get; set; } = "[]";
    public int EstimatedMinutes { get; set; } = 2;
    public bool IsGenerated { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<StorySentence> Sentences { get; set; } = new List<StorySentence>();
    public ICollection<StoryQuestion> Questions { get; set; } = new List<StoryQuestion>();
}

public class StorySentence
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid StoryId { get; set; }
    public Story? Story { get; set; }
    public int OrderIndex { get; set; }
    public int ParagraphIndex { get; set; } = 0;
    public string English { get; set; } = string.Empty;
    public string Arabic { get; set; } = string.Empty;
}

public class StoryQuestion
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid StoryId { get; set; }
    public Story? Story { get; set; }
    public QuestionType Type { get; set; } = QuestionType.Detail;
    public string QuestionAr { get; set; } = string.Empty;
    public string? QuestionEn { get; set; }
    public string OptionsJson { get; set; } = "[]";
    public int CorrectAnswerIndex { get; set; }
    public int? EvidenceSentenceIndex { get; set; }
    public string? ExplanationAr { get; set; }
    public string? FactId { get; set; }
    public string? DistractorsJson { get; set; }
}

public class UserStoryHistory
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public Guid StoryId { get; set; }
    public Story? Story { get; set; }
    public int? Score { get; set; }
    public DateTime ReadAt { get; set; } = DateTime.UtcNow;
}

public class ListeningItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public DifficultyLevel Level { get; set; }
    public string English { get; set; } = string.Empty;
    public string Arabic { get; set; } = string.Empty;
    public string QuestionAr { get; set; } = string.Empty;
    public ListeningType Type { get; set; } = ListeningType.Sentence;
    public string OptionsJson { get; set; } = "[]";
    public int CorrectAnswerIndex { get; set; }
}

public class SpeakingItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public DifficultyLevel Level { get; set; }
    public string English { get; set; } = string.Empty;
    public string Arabic { get; set; } = string.Empty;
    public string? PronunciationTipAr { get; set; }
}

public class PhonicsItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public PhonicsKind Kind { get; set; }
    public string Category { get; set; } = "consonants";
    public string Symbol { get; set; } = string.Empty;
    public string IpaOrSpelling { get; set; } = string.Empty;
    public string ArabicApprox { get; set; } = string.Empty;
    public string MouthTipAr { get; set; } = string.Empty;
    public string MouthDiagramType { get; set; } = "bilabial_p_b";
    public string ExampleWordsJson { get; set; } = "[]";
    public string MinimalPairsJson { get; set; } = "[]";
    public string TongueTwister { get; set; } = string.Empty;
    public string TongueTwisterAr { get; set; } = string.Empty;
    public string? AudioUrl { get; set; }
}
