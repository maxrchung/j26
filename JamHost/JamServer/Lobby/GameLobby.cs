using BalaloGame;
using JamServer.RPC;

namespace JamServer.Lobby;

public class GameLobbyPlayer
{
    public required Guid Id { get; init; }
    public required string Name { get; init; }
    public required PlayerChannel Channel { get; init; }

    public required GamePlayer GamePlayer { get; init; }

    public required GameLobby Lobby { get; init; }
}

public record EmergencyMeetingState
{
    public bool IsActive { get; set; } = false;

    public void Start()
    {
        IsActive = true;
        VotesFor.Clear();
        VotesAgainst.Clear();
    }

    public void Reset() {
        IsActive = false;
        VotesFor.Clear();
        VotesAgainst.Clear();
    }

    public List<GamePlayer> VotesFor { get; init; } = [];
    public List<GamePlayer> VotesAgainst { get; init; } = [];

    public EmergencyMeetingInfo ToRpc() => new()
    {
        IsActive = IsActive,
        VotesFor = VotesFor.Select(x => x.Id).ToList(),
        VotesAgainst = VotesAgainst.Select(x => x.Id).ToList(),
    };
}

public class GameLobby
{
    private readonly GameBoard _board = new();

    private readonly List<GameLobbyPlayer> _players = new();
    private List<GameLobbyPlayer> _active_players = new ();
    private List<GameLobbyPlayer> _inactive_players = new ();
    private int _player_index = 0;
    private int _round_count = 0;

    public readonly string Name;
    public readonly Guid Id;

    private readonly EmergencyMeetingState _emergencyMeeting = new();

    public const int HAND_LIMIT = 6;
    public const int SCORE_LIMIT = 100;


    public GameLobby(string name, Guid id)
    {
        Name = name;
        Id = id;
    }

    private async Task InvokeAll(RpcResponse msg)
    {
        await Task.WhenAll(_players.Select(x => x.Channel.Send(msg)));
    }

    private async Task BroadcastLobbyChange()
    {
        var msg = new RpcResponse
        {
            Id = 0,
            LobbyChange = new LobbyChangeMessage
            {
                Id = Id,
                Name = Name,
                Players = _players.Select(LobbyPlayer.From).ToList()
            }
        };
        await InvokeAll(msg);
    }

    private DeckInfo DeckToRpc() => new()
    {
        Cards = _board.Cards.Select(CardInfo.From).ToList()
    };

    private bool ShouldRevealHandTo(GameLobbyPlayer observer, GameLobbyPlayer target) => observer.Id == target.Id;

    public IReadOnlyList<PlayerHandInfo> HandInfoFor(GameLobbyPlayer player)
    {
        return _players.Select(x => new PlayerHandInfo
        {
            Id = x.Id,
            CardCount = x.GamePlayer.HandSize,
            Cards = ShouldRevealHandTo(player, x)
                ? x.GamePlayer.HandCards.Select(CardInfo.From).ToList()
                : null
        }).ToList();
    }

    public List<GameLobbyPlayer> GetPlayers()
    {
        return _players;
    }

    private async Task UpdateHands()
    {
        await Task.WhenAll(_players.Select(player =>
            player.Channel.Send(new RpcResponse { Id = 0, PlayerHands = HandInfoFor(player) })).ToList());
    }

    // dupe some logic for BACK COMPAT 
    private async Task UpdateGameState()
    {
        var response = new RpcResponse
        {
            Id = 0,
            GameStateUpdateEvent = new GameStateUpdateEvent
            {
                EventType = GameStateUpdateEvent.Type.RoundStart,
                CurrentRound = CreateCurrentRoundInfo()
            }
        };
        await Task.WhenAll(_players.Select(player => player.Channel.Send(response)).ToList());
    }

    public RoundInfo CreateCurrentRoundInfo()
    {
        return new RoundInfo
        {
            RoundNumber = _board.RoundNumber,
            ActivePlayer = LobbyPlayer.From(_players[0]) // TODO replace with actual active player
        };
    }

    public async Task NextRound()
    {
        _board.NextRound();
        _round_count += 1;
        await UpdateHands(); // TODO remove dupe call
        await UpdateGameState();
    }

    public async Task NextTurn() {
        var current_player = _active_players[_player_index];
        await InvokeAll(new RpcResponse { Id = 0, CurrentPlayer = current_player.Id });
        _player_index += 1;
        _player_index = _player_index % _active_players.Count;
    }

    public async Task<bool> ValidateBid(List<Dictionary<string, string>> raw_bid) {
        var bid = new List<Card>();
        foreach (Dictionary<string, string> raw_card in raw_bid)
        {
            foreach (var (suit, value) in raw_card)
            {
                Enum.TryParse<CardSuit>(suit, true, out CardSuit card_suit);
                Enum.TryParse<CardValue>(value, true, out CardValue card_value);
                var new_card = new Card(card_value, card_suit);
                bid.Add(new_card);
            }
        }
        if (_board.ValidateBid(bid))
        {
            _board.SetBid(bid);
            _board.SetBidPlayer(_active_players[_player_index].GamePlayer);
            await InvokeAll(new RpcResponse {Id = 0, Bid = bid });
            await NextTurn();
            return true;
        }
        return false;
    }

    public async Task MeetingEnd() {
        if (_emergencyMeeting.VotesFor.Count + _emergencyMeeting.VotesAgainst.Count < _active_players.Count) {
            return;
        }

        // otherwise meeting has ended
        var meeting_result = _board.CheckBs();
        UpdatePlayers(meeting_result);
        await UpdateGame();
        await UpdateDeck();
        await NextRound();
        await NextTurn();
        _emergencyMeeting.Reset();
    }

    public void UpdatePlayers(bool result) {
        // false == not bs, the bid is valid
        // true == bs, bid is not valid
        if (result) {
            Penalize(new List<GamePlayer>() { _players[_player_index].GamePlayer}); // penalize the person that bid
            Reward(_emergencyMeeting.VotesAgainst);
        }
        else {
            Penalize(_emergencyMeeting.VotesAgainst);
            Reward(_emergencyMeeting.VotesFor);
        }
    }

    public async Task UpdateGame() {
        var new_inactive_players = new List<GameLobbyPlayer>();
        foreach (var player in _active_players) {
            if (player.GamePlayer.Score >= SCORE_LIMIT) {
                await EndGame();
            }
            if (player.GamePlayer.HandSize >= HAND_LIMIT) {
                new_inactive_players.Add(player);
            }
        }

        foreach (var inactive_player in new_inactive_players) {
            _inactive_players.Add(inactive_player);
            _active_players.Remove(inactive_player);
        }
    }

    public void Penalize(List<GamePlayer> players) {
        foreach (var player in players) {
            player.IncreaseHandSize();
            player.DecreasePoints(_board.GetBidValue());
        }
    }

    public void Reward(List<GamePlayer> players) {
        foreach (var player in players) {
            player.IncreasePoints(_board.GetBidValue());
        }
    }

    public async Task UpdateDeck()
    {
        await InvokeAll(new RpcResponse { Id = 0, Deck = DeckToRpc() });
    }

    private async Task BroadcastMeeting()
    {
        await InvokeAll(new RpcResponse { Id = 0, EmergencyMeeting = _emergencyMeeting.ToRpc() });
    }

    private async Task EndGame() {
        await InvokeAll(new RpcResponse { Id = 0 });
    }

    public async Task InvokeCtl(GameLobbyPlayer player, InvokeCtlType type)
    {
        if (type == InvokeCtlType.StartGame)
        {
            _active_players = _players;
            await UpdateDeck();
            await NextRound();
            var current_player = _active_players[_player_index];
            await InvokeAll(new RpcResponse { Id = 0, CurrentPlayer = current_player.Id });
        }
        else if (type == InvokeCtlType.EmergencyMeetingVoteFor)
        {
            if (!_emergencyMeeting.IsActive)
            {
                return;
            }
            _emergencyMeeting.VotesFor.Add(player.GamePlayer);
            await BroadcastMeeting();
            await MeetingEnd();
        }
        else if (type == InvokeCtlType.EmergencyMeetingVoteAgainst)
        {
            if (!_emergencyMeeting.IsActive)
            {
                _emergencyMeeting.Start();
                _emergencyMeeting.VotesFor.Add(_board.GetBidPlayer());
            }

            _emergencyMeeting.VotesAgainst.Add(player.GamePlayer);
            await BroadcastMeeting();
            await MeetingEnd();
        }
    }

    public async ValueTask<GameLobbyPlayer> BindPlayer(string name, PlayerChannel channel)
    {
        var new_id = Guid.NewGuid();
        var player = new GameLobbyPlayer
        {
            Id = new_id,
            Name = name,
            Channel = channel,
            GamePlayer = _board.AddPlayer(new_id),
            Lobby = this,
        };
        _players.Add(player);
        await channel.Send(new RpcResponse
        {
            Id = 0,
            LocalIdChange = player.Id,
            Deck = DeckToRpc(),
        });
        await BroadcastLobbyChange();
        return player;
    }
}