namespace JamServer.RPC;

public record OkResponse
{
    public required string Message { get; init; } = "";
}

public record LobbyListEntry(Guid Id, string Name);

public record LobbyChangeMessage
{
    public required Guid Id { get; init; }
    public required string Name { get; init; }
    public required IReadOnlyList<string> Players { get; init; }
}

public record RpcResponse
{
    public required int Id { get; init; }

    public OkResponse? Ok { get; set; }

    public IReadOnlyList<LobbyListEntry>? LobbyList { get; set; }
    
    public LobbyChangeMessage? LobbyChange { get; set; }

    public string? Error { get; set; }
}