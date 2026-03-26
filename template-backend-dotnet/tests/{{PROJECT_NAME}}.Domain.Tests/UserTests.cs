namespace {{PROJECT_NAME}}.Domain.Tests;

using FluentAssertions;
using {{PROJECT_NAME}}.Domain.Entities;

public class UserTests
{
    [Fact]
    public void Create_ShouldSetProperties()
    {
        var user = User.Create("test@example.com", "Test User", "hashedpw");

        user.Email.Should().Be("test@example.com");
        user.Name.Should().Be("Test User");
        user.Id.Should().NotBeEmpty();
        user.CreatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(1));
    }

    [Fact]
    public void UpdateProfile_ShouldUpdateFields()
    {
        var user = User.Create("test@example.com", "Old Name", "hashedpw");

        user.UpdateProfile(name: "New Name", bio: "My bio");

        user.Name.Should().Be("New Name");
        user.Bio.Should().Be("My bio");
        user.UpdatedAt.Should().NotBeNull();
    }
}
