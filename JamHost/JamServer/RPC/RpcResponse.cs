namespace JamServer.RPC;

public record OkResponse
{
    public required string Message { get; init; } = "";
}

public record LobbyListEntry(string Name, Guid Id);

public record RpcResponse
{
    public required int Id { get; init; }

    public OkResponse? Ok { get; set; }

    public IReadOnlyList<LobbyListEntry>? LobbyList { get; set; }

    public string? Error { get; set; }
}