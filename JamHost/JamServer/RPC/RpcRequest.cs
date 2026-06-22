using BalaloGame;

namespace JamServer.RPC;

public record ConnectRequest
{
    public required string Version { get; init; }
}

public enum GetInfoType
{
    Lobbies,
}

public enum InvokeCtlType
{
    StartGame,
    EmergencyMeetingVoteFor,
    EmergencyMeetingVoteAgainst,
}

public record CreateRequest
{
    public required string PlayerName { get; init; }
}

public record RequestCard(CardSuit Suit, CardValue Value);

public record JoinRequest
{
    public required Guid LobbyId { get; init; }
    public required string PlayerName { get; init; }
}

public record BidRequest
{ 
    public required List<RequestCard> Cards { get; init; }
}

public record TestRequest
{
    public required string Message { get; init; }
}

public class RpcRequest
{
    public required int Id { get; init; }
    public ConnectRequest? Connect { get; init; }
    public GetInfoType? GetInfo { get; init; }
    public InvokeCtlType? InvokeCtl { get; init; }
    public CreateRequest? Create { get; init; }
    public JoinRequest? Join { get; init; }
    public BidRequest? Bid { get; init; }

    public TestRequest? TestRequest {get; init; }
}