using System.Diagnostics.CodeAnalysis;
using JamServer.Game;
using JamServer.Models;
using JamServer.RPC;

namespace JamServer.Lobby;

public class LobbyPlayer
{
    public required string Name { get; init; }
    public required PlayerChannel Channel { get; init; }
}

public class GameLobby(LobbyCoordinator coordinator, Guid id, string name)
{
    private readonly Deck _deck = Deck.CreateDefault();

    private readonly List<LobbyPlayer> _players = new();

    public readonly LobbyInfo Info = new()
    {
        Id = id,
        Name = name,
    };

    private async Task InvokeAll(RpcResponse msg)
    {
        await Task.WhenAll(_players.Select(x => x.Channel.Send(msg)));
    }

    private async Task BroadcastLobbyChange()
    {
        var msg = new RpcResponse
        {
            Id = -1,
            LobbyChange = new LobbyChangeMessage
            {
                Id = Info.Id,
                Name = Info.Name,
                Players = _players.Select(x => x.Name).ToList()
            }
        };
        await InvokeAll(msg);
    }

    public async ValueTask<LobbyPlayer> BindPlayer(string name, PlayerChannel channel)
    {
        var player = new LobbyPlayer
        {
            Name = name,
            Channel = channel,
        };
        _players.Add(player);
        await BroadcastLobbyChange();
        return player;
    }
}