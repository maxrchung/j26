namespace JamServer.Models;

public enum RpcRequestType
{
    Connect,
}

public record RpcRequest
{
    public RpcRequestType Type { get; init; }
}