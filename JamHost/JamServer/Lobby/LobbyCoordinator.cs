using System.Diagnostics.CodeAnalysis;
using JamServer.Models;

namespace JamServer.Lobby;

public class LobbyCoordinator
{
    private readonly ILogger<LobbyCoordinator> _logger;
    private readonly Dictionary<Guid, GameLobby> _lobbies = new();
    private readonly Dictionary<Guid, GameLobby> _playerKeys = new();

    public LobbyCoordinator(ILogger<LobbyCoordinator> logger)
    {
        _logger = logger;
        _logger.LogInformation("Lobby coordinator started");

        // DEBUG
        CreateLobby("hi");
    }

    public bool TryFindLobby(Guid id, [MaybeNullWhen(false)] out GameLobby lobby) =>
        _lobbies.TryGetValue(id, out lobby);

    public GameLobby CreateLobby(string name)
    {
        var id = Guid.NewGuid();
        var lobby = new GameLobby(this, id, name);
        _lobbies.Add(id, lobby);
        return lobby;
    }

    public void AssociateKey(Guid playerKey, GameLobby lobby)
    {
        _playerKeys.Add(playerKey, lobby);
    }

    public bool TryUseKey(Guid playerKey, [MaybeNullWhen(false)] out GameLobby.PlayerInfo player)
    {
        if (!_playerKeys.Remove(playerKey, out var lobby))
        {
            player = null;
            return false;
        }

        return lobby.TryUseKey(playerKey, out player);
    }

    public IEnumerable<LobbyInfo> GetLobbies() => _lobbies.Select(x => x.Value.Info);
}