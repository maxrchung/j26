namespace JamServer.Models;

public record LobbyPlayer
{
    public required string Name { get; init; }

    public required int HeldCards { get; init; }
}

public record LobbySelfPlayer : LobbyPlayer
{
    public required List<CardInfo> Hand { get; init; }
}