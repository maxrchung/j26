using BalaloGame;
using JamServer.Lobby;

namespace JamServer.RPC;

public record OkResponse
{
    public required string Message { get; init; } = "";
}

public record LobbyPlayer(Guid Id, string Name)
{
    public static LobbyPlayer From(GameLobbyPlayer p)
    {
        return new LobbyPlayer(p.Id, p.Name);
    }
}

public record LobbyChangeMessage
{
    public required Guid Id { get; init; }
    public required string Name { get; init; }
    public required IReadOnlyList<LobbyPlayer> Players { get; init; }
}

public record CardInfo
{
    public required CardSuit Suit { get; init; }
    public required CardValue Value { get; init; }

    public static CardInfo From(Card c)
    {
        return new CardInfo
        {
            Suit = c.Suit,
            Value = c.Value
        };
    }
}

public record DeckInfo
{
    public required IReadOnlyList<CardInfo> Cards { get; init; }
}

public record PlayerHandInfo
{
    public required Guid Id { get; init; }
    public required int CardCount { get; init; }
    public IReadOnlyList<CardInfo>? Cards { get; init; }
    public required string Name { get; init; }
}

public record EmergencyMeetingInfo
{
    public required bool IsActive { get; init; }
    public required IReadOnlyList<Guid> VotesFor { get; init; } = [];
    public required IReadOnlyList<Guid> VotesAgainst { get; init; } = [];
}

public record RoundInfo
{
    public required int RoundNumber { get; init; }
    public required LobbyPlayer ActivePlayer { get; init; }
}

public record GameStateUpdateEvent
{

    public enum Type
    {
        RoundStart,
        GameOver,
    }
    public required Type EventType { get; init; }
    public int? MaxRounds { get; init; }
    public RoundInfo? CurrentRound { get; init; }
    public IReadOnlyList<LobbyPlayer>? ActivePlayers { get; init; }
    public Guid? Winner {get; init; }

}

public record RpcResponse
{
    public required int Id { get; init; }

    public OkResponse? Ok { get; set; }

    public IReadOnlyList<LobbyListEntry>? LobbyList { get; set; }

    public LobbyChangeMessage? LobbyChange { get; set; }

    public Guid? CurrentPlayer { get; set; }

    public Guid? BidPlayer { get; set; }

    public DeckInfo? Deck { get; set; }

    public IReadOnlyList<PlayerHandInfo>? PlayerHands { get; set; }

    public Guid? LocalIdChange { get; set; }

    public EmergencyMeetingInfo? EmergencyMeeting { get; set; }

    public IReadOnlyList<Card>? Bid { get; set; }
    public GameStateUpdateEvent? GameStateUpdateEvent { get; set; }

    public string? Error { get; set; }
}