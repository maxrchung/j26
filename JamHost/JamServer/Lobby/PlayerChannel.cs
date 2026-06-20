using System.Net.WebSockets;
using JamServer.RPC;

namespace JamServer.Lobby;

public class PlayerChannel : IRpcListener
{
    private readonly ILogger<PlayerChannel> _logger;
    private readonly LobbyCoordinator _coordinator;
    private readonly RpcPipe _pipe;
    private string _name = "Player";
    private LobbyPlayer? _lobbyPlayer = null;

    public string Name => _name;

    public Task Send(RpcResponse msg) => _pipe.Send(msg);

    public PlayerChannel(IServiceProvider services, WebSocket socket)
    {
        _logger = services.GetRequiredService<ILogger<PlayerChannel>>();
        _coordinator = services.GetRequiredService<LobbyCoordinator>();
        _pipe = new RpcPipe(socket, this);
    }

    public async Task RunAsync()
    {
        await _pipe.RunAsync();
    }


    public ValueTask<OkResponse> ConnectAsync(ConnectRequest req)
    {
        return ValueTask.FromResult(new OkResponse { Message = "ok" });
    }

    public ValueTask<IReadOnlyList<LobbyListEntry>> GetLobbyListAsync()
    {
        return ValueTask.FromResult<IReadOnlyList<LobbyListEntry>>(_coordinator.GetLobbies()
            .Select(x => new LobbyListEntry(x.Id, x.Name)).ToList());
    }


    public async ValueTask<OkResponse> JoinLobbyAsync(Guid lobbyId, string playerName)
    {
        if (_lobbyPlayer != null)
        {
            throw new Exception("Already in lobby");
        }

        _name = playerName;
        if (!_coordinator.TryFindLobby(lobbyId, out var lobby))
        {
            throw new Exception("Lobby not found");
        }

        _lobbyPlayer = await lobby.BindPlayer(playerName, this);
        return new OkResponse { Message = "joined" };
    }

    public void OnError(Exception e)
    {
        _logger.LogError(e, "Error in player channel");
    }
}