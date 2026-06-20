namespace JamServer.Models;

public record PlayerBluff
{
    public required Guid PlayerKey { get; init; }

    public required int ScoresAtLeast { get; init; }

    public required List<CardInfo> SpecificCards { get; init; }
}