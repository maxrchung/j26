using BalaloGame;
using JamServer.RPC;
using BalaloGame.Scoring;

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

    public void Reset()
    {
        IsActive = false;
        VotesFor.Clear();
        VotesAgainst.Clear();
        MeetingCaller = null;
    }

    public List<GamePlayer> VotesFor { get; init; } = [];
    public List<GamePlayer> VotesAgainst { get; init; } = [];
    public GamePlayer MeetingCaller { get; set; }

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
    private int _player_index = 0;

    public readonly string Name;
    public readonly Guid Id;

    private readonly EmergencyMeetingState _emergencyMeeting = new();

    public const int HAND_LIMIT = 67; // Setting this real high to avoid some weird die cases
    public const int SCORE_LIMIT = 1000;
    public const int MAX_ROUNDS = 6;


    public GameLobby(string name, Guid id)
    {
        Name = name;
        Id = id;
    }

    public bool IsActive => _board.RoundNumber > 0;

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
                : null,
            Name = x.Name,
            Score = x.GamePlayer.GetScore()
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
    private async Task UpdateGameState(GameStateUpdateEvent.Type eventType)
    {
        var response = new RpcResponse
        {
            Id = 0,
            GameStateUpdateEvent = CreateGameStateUpdateEvent(eventType)
        };
        await Task.WhenAll(_players.Select(player => player.Channel.Send(response)).ToList());
    }

    private GameStateUpdateEvent CreateGameStateUpdateEvent(GameStateUpdateEvent.Type eventType)
    {
        return eventType switch
        {
            GameStateUpdateEvent.Type.RoundStart =>
                new GameStateUpdateEvent
                {
                    EventType = GameStateUpdateEvent.Type.RoundStart,
                    CurrentRound = CreateCurrentRoundInfo(),
                    Players = _players.Select(LobbyPlayer.From).ToList()
                },
            GameStateUpdateEvent.Type.GameOver =>
                new GameStateUpdateEvent
                {
                    EventType = GameStateUpdateEvent.Type.GameOver,
                    Winner = CalculateWinner(_players),
                    CurrentRound = CreateCurrentRoundInfo(),
                    Players = _players.Select(LobbyPlayer.From).ToList()
                },
            _ => throw new ArgumentException("Invalid GameStateUpdateEvent.Type")
        };
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
        if (_board.RoundNumber > MAX_ROUNDS)
        {
            await UpdateGameState(GameStateUpdateEvent.Type.GameOver);
        }
        else
        {
            await UpdateHands(); // TODO remove dupe call
            await UpdateGameState(GameStateUpdateEvent.Type.RoundStart);
            await InvokeAll(new RpcResponse { Bid = new List<Card>() });
        }
    }

    public async Task SetTurn(GamePlayer loser)
    {
        var player_ids = new List<Guid>();
        foreach (var player in _players)
        {
            player_ids.Add(player.Id);
        }

        if (player_ids.Contains(loser.Id))
        {
            _player_index = player_ids.IndexOf(loser.Id);
            var current_player = _players[_player_index];
            if (_board.GetBidPlayer() is null)
            {
                await InvokeAll(new RpcResponse { Id = 0, CurrentPlayer = current_player.Id });
            }
            else
            {
                await InvokeAll(new RpcResponse
                    { Id = 0, CurrentPlayer = current_player.Id, BidPlayer = _board.GetBidPlayer().Id });
            }
        }
        else
        {
            _player_index += 1;
            _player_index = _player_index % _players.Count;
            var current_player = _players[_player_index];
            if (_board.GetBidPlayer() is null)
            {
                await InvokeAll(new RpcResponse { Id = 0, CurrentPlayer = current_player.Id });
            }
            else
            {
                await InvokeAll(new RpcResponse
                    { Id = 0, CurrentPlayer = current_player.Id, BidPlayer = _board.GetBidPlayer().Id });
            }
        }
    }

    public async Task NextTurn()
    {
        _player_index += 1;
        _player_index = _player_index % _players.Count;
        var current_player = _players[_player_index];
        if (_board.GetBidPlayer() is null)
        {
            await InvokeAll(new RpcResponse { Id = 0, CurrentPlayer = current_player.Id });
        }
        else
        {
            await InvokeAll(new RpcResponse
                { Id = 0, CurrentPlayer = current_player.Id, BidPlayer = _board.GetBidPlayer().Id });
        }
    }

    public async Task<bool> ValidateBid(List<RequestCard> rawBid)
    {
        if (rawBid.Count < 1) return false;
        var bid = rawBid.Select(x => new Card(x.Value, x.Suit)).ToList();

        if (_board.ValidateBid(bid))
        {
            _board.SetBid(bid);
            _board.SetBidPlayer(_players[_player_index].GamePlayer);
            await InvokeAll(new RpcResponse { Id = 0, Bid = bid });
            await NextTurn();
            return true;
        }

        return false;
    }

    public async Task MeetingEnd()
    {
        if (_emergencyMeeting.VotesFor.Count + _emergencyMeeting.VotesAgainst.Count < _players.Count)
        {
            return;
        }

        // otherwise meeting has ended
        var meeting_result = _board.CheckBs();
        // calculate the next player, should be the person who lost
        // if it was bs, then the person who bid starts, if it wasn't bs then the person who called the meeting starts
        GamePlayer loser = meeting_result ? _board.GetBidPlayer() : _emergencyMeeting.MeetingCaller;
        UpdatePlayers(meeting_result);
        await UpdateGame();
        await UpdateDeck();
        await NextRound();
        await SetTurn(loser);
        _emergencyMeeting.Reset();
    }

    public void UpdatePlayers(bool result)
    {
        // false == not bs, the bid is valid
        // true == bs, bid is not valid
        if (result)
        {
            Penalize(new List<GamePlayer>() { _board.GetBidPlayer() }); // penalize the person that bid
            Reward(_emergencyMeeting.VotesAgainst);
        }
        else
        {
            Penalize(_emergencyMeeting.VotesAgainst);
            Reward(_emergencyMeeting.VotesFor);
        }
    }

    public async Task UpdateGame()
    {
        foreach (var player in _players)
        {
            if (player.GamePlayer.Score >= SCORE_LIMIT)
            {
                await UpdateGameState(GameStateUpdateEvent.Type.GameOver);
            }
        }
    }

    public void Penalize(List<GamePlayer> players)
    {
        var points = _board.GetBidValue() / players.Count;
        foreach (var player in players)
        {
            player.IncreaseHandSize();
            player.DecreasePoints(points);
        }
    }

    public void Reward(List<GamePlayer> players)
    {
        var points = _board.GetBidValue() / players.Count;
        foreach (var player in players)
        {
            player.IncreasePoints(points);
        }
    }

    public Guid CalculateWinner(List<GameLobbyPlayer> players)
    {
        var maxScore = double.NegativeInfinity;
        var winningGuid = new Guid();
        foreach (var player in players)
        {
            var score = player.GamePlayer.GetScore();
            if (score > maxScore)
            {
                winningGuid = player.Id;
                maxScore = score;
            }
        }

        return winningGuid;
    }

    public async Task UpdateDeck()
    {
        await InvokeAll(new RpcResponse { Id = 0, Deck = DeckToRpc() });
    }

    private async Task BroadcastMeeting()
    {
        await InvokeAll(new RpcResponse { Id = 0, EmergencyMeeting = _emergencyMeeting.ToRpc() });
    }

    public async Task InvokeCtl(GameLobbyPlayer player, InvokeCtlType type)
    {
        if (type == InvokeCtlType.StartGame)
        {
            await UpdateDeck();
            await NextRound();
            var current_player = _players[_player_index];
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
                _emergencyMeeting.MeetingCaller = player.GamePlayer;
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