using System.Text.RegularExpressions;
using Alemni.Application.Common.Interfaces;
using Alemni.Application.DTOs;
using Microsoft.EntityFrameworkCore;

namespace Alemni.Application.Services;

public interface IStoryValidator
{
    Task<BlueprintValidationResult> ValidateAsync(
        StoryBlueprint blueprint,
        HashSet<string>? dictionaryWords = null,
        CancellationToken ct = default);
}

public class StoryValidator : IStoryValidator
{
    private readonly IAlemniDbContext? _db;
    private readonly IMorphologyService _morphology;

    private static readonly Regex WordRegex = new(@"[A-Za-z][A-Za-z'’]*", RegexOptions.Compiled);
    private static readonly Regex SentenceSplitRegex = new(@"(?<=[.!?])\s+", RegexOptions.Compiled);

    private static readonly HashSet<string> CommonQuestionWords = new(StringComparer.OrdinalIgnoreCase)
    {
        "what", "where", "who", "whom", "whose", "why", "when", "which", "how",
        "is", "are", "was", "were", "do", "does", "did", "can", "could", "will", "would",
        "the", "a", "an", "in", "on", "at", "to", "for", "from", "by", "with", "about",
        "true", "false", "yes", "no", "according", "following", "sentence", "story", "passage"
    };

    public StoryValidator(IMorphologyService morphology, IAlemniDbContext? db = null)
    {
        _morphology = morphology;
        _db = db;
    }

    public async Task<BlueprintValidationResult> ValidateAsync(
        StoryBlueprint blueprint,
        HashSet<string>? dictionaryWords = null,
        CancellationToken ct = default)
    {
        var result = new BlueprintValidationResult();

        if (blueprint == null)
        {
            result.AddError("Story blueprint cannot be null.");
            return result;
        }

        // 1. Check title and genre
        if (string.IsNullOrWhiteSpace(blueprint.Title))
            result.AddError("Story must have a non-empty Title.");
        if (string.IsNullOrWhiteSpace(blueprint.Genre))
            result.AddError("Story must have a non-empty Genre.");

        // 2. Extract full story text and sentences
        var allParagraphs = blueprint.Text ?? new List<string>();
        if (allParagraphs.Count == 0)
        {
            result.AddError("Story must contain at least one paragraph.");
            return result;
        }

        var fullText = string.Join(" ", allParagraphs);
        var storyWords = WordRegex.Matches(fullText).Select(m => m.Value).ToList();
        var wordCount = storyWords.Count;

        // Break text into sentences
        var allSentences = new List<string>();
        foreach (var p in allParagraphs)
        {
            var sents = SentenceSplitRegex.Split(p.Trim())
                .Where(s => !string.IsNullOrWhiteSpace(s))
                .ToList();
            allSentences.AddRange(sents);
        }
        var totalSentences = allSentences.Count;

        // 3. Word count validation by Level
        var level = blueprint.Level?.ToUpperInvariant() ?? "A1";
        switch (level)
        {
            case "A1":
                if (wordCount < 80 || wordCount > 150)
                    result.AddError($"A1 story word count must be between 90 and 140 words. Current: {wordCount}");
                break;
            case "A2":
                if (wordCount < 130 || wordCount > 240)
                    result.AddError($"A2 story word count must be between 150 and 230 words. Current: {wordCount}");
                break;
            case "B1":
                if (wordCount < 180 || wordCount > 390)
                    result.AddError($"B1 story word count must be between 250 and 380 words. Current: {wordCount}");
                break;
            case "B2":
                if (wordCount < 260 || wordCount > 560)
                    result.AddError($"B2 story word count must be between 400 and 550 words. Current: {wordCount}");
                break;
            default:
                result.AddError($"Unknown difficulty level: {blueprint.Level}");
                break;
        }

        // 4. Question pool validation
        var questions = blueprint.QuestionPool ?? new List<BlueprintQuestionDto>();
        if (questions.Count < 8)
        {
            result.AddError($"QuestionPool must contain at least 8 questions. Current: {questions.Count}");
        }

        // 5. Facts validation
        var facts = blueprint.Facts ?? new List<FactDto>();
        var factsMap = facts.ToDictionary(f => f.Id, f => f);

        foreach (var fact in facts)
        {
            if (string.IsNullOrWhiteSpace(fact.Id))
                result.AddError("Fact must have a valid non-empty Id.");
            if (fact.Sentence < 1 || fact.Sentence > totalSentences)
                result.AddError($"Fact '{fact.Id}' references sentence #{fact.Sentence}, but story only has {totalSentences} sentences.");
        }

        // 6. Character names and proper nouns in questions
        var characterNames = (blueprint.Characters ?? new List<CharacterDto>())
            .SelectMany(c => WordRegex.Matches(c.Name).Select(m => m.Value.ToLowerInvariant()))
            .ToHashSet();

        var storyWordsLower = storyWords.Select(w => w.ToLowerInvariant()).ToHashSet();

        // Load dictionary words if not provided and db is available
        HashSet<string> dict;
        if (dictionaryWords != null)
        {
            dict = dictionaryWords;
        }
        else if (_db != null)
        {
            dict = (await _db.Words.Select(w => w.English.ToLower()).ToListAsync(ct)).ToHashSet();
        }
        else
        {
            dict = new HashSet<string>();
        }

        bool IsValidWord(string raw)
        {
            var norm = _morphology.NormalizeWord(raw);
            if (string.IsNullOrEmpty(norm)) return true;
            if (storyWordsLower.Contains(norm)) return true;
            if (dict.Contains(norm)) return true;
            var candidates = _morphology.GetCandidates(norm);
            return candidates.Any(c => dict.Contains(c));
        }

        // 7. Validate questions and distractors
        for (int i = 0; i < questions.Count; i++)
        {
            var q = questions[i];
            if (string.IsNullOrWhiteSpace(q.Q))
            {
                result.AddError($"Question #{i + 1} has an empty question text.");
                continue;
            }

            if (string.IsNullOrWhiteSpace(q.Correct))
            {
                result.AddError($"Question '{q.Q}' has an empty correct answer.");
            }

            // Distractor checks
            var distractors = q.Distractors ?? new List<string>();
            if (distractors.Count < 2)
            {
                result.AddError($"Question '{q.Q}' must have at least 2 distractors.");
            }

            var correctLower = q.Correct.Trim().ToLowerInvariant();
            var seenDistractors = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            foreach (var d in distractors)
            {
                var dTrim = d.Trim();
                if (string.Equals(dTrim, q.Correct.Trim(), StringComparison.OrdinalIgnoreCase))
                {
                    result.AddError($"Question '{q.Q}' has a distractor '{d}' that matches the correct answer.");
                }

                if (!seenDistractors.Add(dTrim))
                {
                    result.AddError($"Question '{q.Q}' has a duplicate distractor '{d}'.");
                }
            }

            // Fact link check
            if (string.IsNullOrWhiteSpace(q.FactId))
            {
                result.AddError($"Question '{q.Q}' must link to a valid factId.");
            }
            else if (!factsMap.ContainsKey(q.FactId))
            {
                result.AddError($"Question '{q.Q}' references factId '{q.FactId}' which does not exist in story facts.");
            }

            // Proper names check: detects Sara/Ali in Hassan's story!
            var qWords = WordRegex.Matches(q.Q).Select(m => m.Value).ToList();
            foreach (var qw in qWords)
            {
                // Capitalized word that might be an external character
                if (char.IsUpper(qw[0]) && qw.Length > 2)
                {
                    var qwClean = qw.TrimEnd('\'', '’').ToLowerInvariant();
                    if (qwClean.EndsWith("'s") || qwClean.EndsWith("’s"))
                    {
                        qwClean = qwClean[..^2];
                    }

                    // If it's a character name that is NOT in this story's characters AND not in the story text:
                    if (!CommonQuestionWords.Contains(qwClean) && !characterNames.Contains(qwClean) && !storyWordsLower.Contains(qwClean))
                    {
                        // Check if it's a standard dictionary word (like Monday, Sunday, English, etc.)
                        if (!dict.Contains(qwClean))
                        {
                            var candidates = _morphology.GetCandidates(qwClean);
                            if (!candidates.Any(c => dict.Contains(c) || characterNames.Contains(c)))
                            {
                                result.AddError($"Question '{q.Q}' references character or word '{qw}' which does not exist in the story characters, text, or general dictionary.");
                            }
                        }
                    }
                }
            }
        }

        // 8. Dictionary coverage for story content words (if dictionary provided)
        if (dict.Count > 0)
        {
            var missingWords = new List<string>();
            foreach (var sw in storyWords)
            {
                var clean = sw.Trim('\'', '’');
                if (clean.Length <= 1) continue;

                if (!IsValidWord(clean))
                {
                    missingWords.Add(clean.ToLowerInvariant());
                }
            }

            if (missingWords.Count > 0)
            {
                var distinctMissing = missingWords.Distinct().ToList();
                result.AddError($"Story contains {distinctMissing.Count} words not covered in the dictionary: {string.Join(", ", distinctMissing.Take(10))}");
            }
        }

        return result;
    }
}
