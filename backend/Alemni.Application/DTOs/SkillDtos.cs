using Alemni.Application.Services;

namespace Alemni.Application.DTOs;

// Words & Vocab
public record LookupResult(string Word, string Arabic, string? BaseWord, bool Found, Guid? WordId = null);
public record SavedWordDto(Guid Id, Guid WordId, string English, string Arabic, DateTime AddedAt);
public record SaveWordRequest(Guid WordId);

// Writing
public record WritingNextDto(Guid Id, Guid WordId, string Level, int Length, string HintAr, int? VowelCount = null, string? ExampleEn = null);
public record WritingCheckRequest(Guid WordId, string Answer, int HintsUsed = 0);
public record LetterCheck(char Expected, char? Actual, bool IsCorrect);
public record WritingCheckResponse(bool IsCorrect, string Word, string Arabic, List<LetterCheck> Letters, int XpAwarded, string? ExampleEn = null, string? ExampleAr = null);

// Reading
public record ReadingStoryDto(Guid Id, string Title, string TitleAr, string Level, int WordCount, int EstimatedMinutes, List<SentenceDto> Sentences, List<QuestionDto> Questions, string? Genre = "everyday", string? Emoji = "📖", string? Setting = null);
public record SentenceDto(int OrderIndex, int ParagraphIndex, string English, string Arabic);
public record QuestionDto(Guid Id, string Type, string QuestionAr, string? QuestionEn, List<string> Options, int? EvidenceSentenceIndex, string? ExplanationAr, string? FactId = null);
public record StoryAnswersRequest(List<int> SelectedAnswers);
public record QuestionExplanationDto(int QuestionIndex, int CorrectAnswerIndex, string? ExplanationAr, int? EvidenceSentenceIndex);
public record StoryAnswersResponse(int Score, int CorrectCount, int TotalQuestions, int XpAwarded, List<int> CorrectAnswers, List<QuestionExplanationDto> Explanations);

// Listening
public record ListeningNextDto(Guid Id, string Level, string English, string Arabic, string QuestionAr, string Type, List<string> Options);
public record ListeningAnswerRequest(Guid ItemId, int SelectedIndex);
public record ListeningAnswerResponse(bool IsCorrect, int CorrectAnswerIndex, string English, string Arabic, int XpAwarded);

// Speaking
public record SpeakingNextDto(Guid Id, string Level, string English, string Arabic, string? PronunciationTipAr);
public record SpeakingScoreRequest(Guid ItemId, string RecognizedText);
public record SpeakingScoreResponse(int Score, List<SpeechChip> Chips, bool Passed, int XpAwarded);

// Phonics
public record MinimalPairDto(string Word1, string Word2, string MeaningAr1, string MeaningAr2);

public record PhonicsItemDto(
    Guid Id,
    string Kind,
    string Category,
    string Symbol,
    string IpaOrSpelling,
    string ArabicApprox,
    string MouthTipAr,
    string MouthDiagramType,
    List<string> ExampleWords,
    List<MinimalPairDto> MinimalPairs,
    string TongueTwister,
    string TongueTwisterAr,
    string? AudioUrl
);

// User Stats & Progress
public record UserStatsDto(int Xp, int StreakDays, DateOnly LastActiveDate, int WordsSavedCount, int CompletedSkillsCount);

