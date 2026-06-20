namespace JamServer.Models;

public record LobbyJoinRequest
{
    public required Guid Id { get; init; }
    public required string PlayerName { get; init; }

    public string? Password { get; init; }
}

public record LobbyJoinResponse
{
    public required Guid PlayerKey { get; init; }
    public required FullLobbyInfo Lobby { get; init; }
}

public record LobbyCreateRequest
{
    public required string Name { get; init; }
}