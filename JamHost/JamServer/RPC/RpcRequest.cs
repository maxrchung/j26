namespace JamServer.RPC;

public record ConnectRequest
{
    public required string Version { get; init; }
}

public enum GetInfoType
{
    Lobbies
}

public record JoinRequest
{
    public required Guid LobbyId { get; init; }
    public required string PlayerName { get; init; }
}

public class RpcRequest
{
    public required int Id { get; init; }
    public ConnectRequest? Connect { get; init; }
    public GetInfoType? GetInfo { get; init; }

    public JoinRequest? Join { get; init; }
}