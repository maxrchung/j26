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

    public IEnumerable<LobbyInfo> GetLobbies() => _lobbies.Select(x => x.Value.Info);
}