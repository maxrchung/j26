using System.Diagnostics.CodeAnalysis;
using JamServer.Game;
using JamServer.Models;

namespace JamServer.Lobby;

public class GameLobby(LobbyCoordinator coordinator, Guid id, string name)
{
    private readonly Deck _deck = Deck.CreateDefault();

    public record PlayerInfo(string Name);

    private readonly Dictionary<Guid, PlayerInfo> _players = new();
    private readonly Dictionary<Guid, Guid> _playerKeys = new();

    public readonly LobbyInfo Info = new()
    {
        Id = id,
        Name = name,
    };

    public Guid InvitePlayer(string name)
    {
        var id = Guid.NewGuid();
        var key = Guid.NewGuid();
        _players.Add(id, new PlayerInfo(name));
        _playerKeys.Add(key, id);
        coordinator.AssociateKey(key, this);
        return key;
    }

    public bool TryUseKey(Guid key, [MaybeNullWhen(false)] out PlayerInfo player)
    {
        if (!_playerKeys.Remove(key, out var id))
        {
            player = null;
            return false;
        }

        player = _players[id];
        return true;
    }

    public FullLobbyInfo GetFullLobbyInfo()
    {
        return new FullLobbyInfo
        {
            Id = Info.Id,
            Name = Info.Name,
            Cards = _deck.GetCardInfos().ToList(),
        };
    }
}