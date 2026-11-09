namespace Alemni.Application.DTOs;

public class StoryBlueprint
{
    public string Id { get; set; } = string.Empty;
    public string Level { get; set; } = "A1";
    public string Genre { get; set; } = "everyday";
    public string Title { get; set; } = string.Empty;
    public string TitleAr { get; set; } = string.Empty;
    public string Emoji { get; set; } = "📖";
    public List<CharacterDto> Characters { get; set; } = new();
    public string Setting { get; set; } = string.Empty;
    public List<FactDto> Facts { get; set; } = new();
    public List<string> Text { get; set; } = new(); // Paragraphs in English
    public List<BlueprintQuestionDto> QuestionPool { get; set; } = new();
}

public class CharacterDto
{
    public string Name { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
}

public class FactDto
{
    public string Id { get; set; } = string.Empty;
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public int Sentence { get; set; }
}

public class BlueprintQuestionDto
{
    public string Id { get; set; } = string.Empty;
    public string Type { get; set; } = "detail";
    public string Q { get; set; } = string.Empty;
    public string? QAr { get; set; }
    public string Correct { get; set; } = string.Empty;
    public List<string> Distractors { get; set; } = new();
    public string FactId { get; set; } = string.Empty;
    public string? ExplanationAr { get; set; }
}

public class BlueprintValidationResult
{
    public bool IsValid => Errors.Count == 0;
    public List<string> Errors { get; set; } = new();

    public void AddError(string error) => Errors.Add(error);
}
