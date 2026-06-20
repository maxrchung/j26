namespace JamServer.Models;

public enum GameUpdateType
{
    PlayerBluff,
    PlayerJoin,
}

public record GameUpdate
{
    public required GameUpdateType Type { get; init; }
}