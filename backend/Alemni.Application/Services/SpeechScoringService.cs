using System.Text.RegularExpressions;

namespace Alemni.Application.Services;

public record SpeechChip(string Word, bool Ok);
public record SpeechScoreResult(int Score, List<SpeechChip> Chips, bool Passed);

public interface ISpeechScoringService
{
    SpeechScoreResult ScoreSpeech(string target, string said);
}

public class SpeechScoringService : ISpeechScoringService
{
    private static readonly Regex CleanRegex = new(@"[^a-z0-9\s]", RegexOptions.Compiled);
    private static readonly Regex SpacesRegex = new(@"\s+", RegexOptions.Compiled);

    public SpeechScoreResult ScoreSpeech(string target, string said)
    {
        var targetWords = NormalizeSpeech(target).Split(' ', StringSplitOptions.RemoveEmptyEntries);
        var saidWords = NormalizeSpeech(said).Split(' ', StringSplitOptions.RemoveEmptyEntries);

        var used = new bool[saidWords.Length];
        var chips = new List<SpeechChip>();
        var matched = 0;

        foreach (var tw in targetWords)
        {
            var found = -1;
            for (var j = 0; j < saidWords.Length; j++)
            {
                if (used[j]) continue;

                var sw = saidWords[j];
                if (sw == tw || (tw.Length > 3 && sw.Length > 3 && Levenshtein(sw, tw) <= 1))
                {
                    found = j;
                    break;
                }
            }

            if (found >= 0)
            {
                used[found] = true;
                matched++;
                chips.Add(new SpeechChip(tw, true));
            }
            else
            {
                chips.Add(new SpeechChip(tw, false));
            }
        }

        var score = targetWords.Length > 0
            ? (int)Math.Round((double)matched / targetWords.Length * 100)
            : 0;

        return new SpeechScoreResult(score, chips, score >= 80);
    }

    public static string NormalizeSpeech(string? s)
    {
        if (string.IsNullOrWhiteSpace(s)) return string.Empty;

        var clean = s.ToLowerInvariant()
            .Replace("’", "")
            .Replace("'", "");

        clean = CleanRegex.Replace(clean, " ");
        clean = SpacesRegex.Replace(clean, " ");

        return clean.Trim();
    }

    public static int Levenshtein(string a, string b)
    {
        var al = a.Length;
        var bl = b.Length;
        if (al == 0) return bl;
        if (bl == 0) return al;

        var prev = new int[bl + 1];
        for (var j = 0; j <= bl; j++) prev[j] = j;

        for (var i = 1; i <= al; i++)
        {
            var cur = new int[bl + 1];
            cur[0] = i;

            for (var k = 1; k <= bl; k++)
            {
                var cost = a[i - 1] == b[k - 1] ? 0 : 1;
                cur[k] = Math.Min(Math.Min(prev[k] + 1, cur[k - 1] + 1), prev[k - 1] + cost);
            }

            prev = cur;
        }

        return prev[bl];
    }
}

