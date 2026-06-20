namespace JamServer.Models;

public record LobbyInfo
{
    public required Guid Id { get; init; }
    public required string Name { get; init; }
}

public record LobbyListResponse
{
    public required IReadOnlyList<LobbyInfo> Lobbies { get; init; }
}

public record FullLobbyInfo : LobbyInfo
{
    public required IReadOnlyList<CardInfo> Cards { get; init; }
}
