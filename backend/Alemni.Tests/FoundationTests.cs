using FluentAssertions;
using Xunit;

namespace Alemni.Tests;

public class FoundationTests
{
    [Fact]
    public void Foundation_Projects_Are_Configured_Properly()
    {
        // Assert that test suite runs and assertions work
        var status = "Healthy";
        status.Should().Be("Healthy");
    }
}

