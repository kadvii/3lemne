using System.Text.RegularExpressions;

namespace Alemni.Application.Services;

public interface IMorphologyService
{
    string NormalizeWord(string raw);
    List<string> GetCandidates(string word);
}

public class MorphologyService : IMorphologyService
{
    private static readonly Regex CleanRegex = new(@"^[^a-z']+|[^a-z']+$", RegexOptions.Compiled);

    public string NormalizeWord(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return string.Empty;

        var w = raw.ToLowerInvariant()
            .Replace("’", "'")
            .Trim();

        return CleanRegex.Replace(w, string.Empty);
    }

    public List<string> GetCandidates(string word)
    {
        var candidates = new List<string>();
        var w = NormalizeWord(word);

        if (string.IsNullOrEmpty(w) || w.Length <= 1) return candidates;

        void Add(string? c)
        {
            if (!string.IsNullOrEmpty(c) && c.Length > 1 && !candidates.Contains(c))
            {
                candidates.Add(c);
            }
        }

        // Possessive 's
        if (w.EndsWith("'s"))
        {
            Add(w[..^2]);
        }

        // -ies -> -y
        if (w.EndsWith("ies") && w.Length > 3)
        {
            Add(w[..^3] + "y");
        }

        // -ves -> -f
        if (w.EndsWith("ves") && w.Length > 3)
        {
            Add(w[..^3] + "f");
        }

        // -es
        if (w.EndsWith("es") && w.Length > 2)
        {
            Add(w[..^2]);
            Add(w[..^1]);
        }

        // -s (not -ss)
        if (w.EndsWith("s") && !w.EndsWith("ss") && w.Length > 2)
        {
            Add(w[..^1]);
        }

        // -ied -> -y
        if (w.EndsWith("ied") && w.Length > 3)
        {
            Add(w[..^3] + "y");
        }

        // -ed
        if (w.EndsWith("ed") && w.Length > 2)
        {
            var baseEd = w[..^2];
            Add(baseEd);
            Add(baseEd + "e");
            if (baseEd.Length > 2 && baseEd[^1] == baseEd[^2])
            {
                Add(baseEd[..^1]);
            }
        }

        // -ing
        if (w.EndsWith("ing") && w.Length > 3)
        {
            var baseIng = w[..^3];
            Add(baseIng);
            Add(baseIng + "e");
            if (baseIng.Length > 2 && baseIng[^1] == baseIng[^2])
            {
                Add(baseIng[..^1]);
            }
        }

        // -ier -> -y
        if (w.EndsWith("ier") && w.Length > 3)
        {
            Add(w[..^3] + "y");
        }

        // -est
        if (w.EndsWith("est") && w.Length > 3)
        {
            var baseEst = w[..^3];
            Add(baseEst);
            Add(baseEst + "e");
            if (baseEst.Length > 2 && baseEst[^1] == baseEst[^2])
            {
                Add(baseEst[..^1]);
            }
        }

        // -er
        if (w.EndsWith("er") && w.Length > 2)
        {
            var baseEr = w[..^2];
            Add(baseEr);
            Add(baseEr + "e");
            if (baseEr.Length > 2 && baseEr[^1] == baseEr[^2])
            {
                Add(baseEr[..^1]);
            }
        }

        // -ily -> -y
        if (w.EndsWith("ily") && w.Length > 3)
        {
            Add(w[..^3] + "y");
        }

        return candidates;
    }
}

