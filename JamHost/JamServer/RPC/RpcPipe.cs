using JamServer.Lobby;
using System.Diagnostics;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace JamServer.RPC;

public interface IRpcListener
{
    public ValueTask<OkResponse> ConnectAsync(ConnectRequest req);

    public ValueTask<IReadOnlyList<LobbyListEntry>> GetLobbyListAsync();

    public ValueTask<IReadOnlyList<PlayerHandInfo>> GetPlayerHandsAsync(Guid lobbyId, Guid playerId);

    public ValueTask<OkResponse> JoinLobbyAsync(Guid lobbyId, string playerName);

    public ValueTask<Guid> CreateLobbyAsync(string lobbyName);

    public ValueTask<OkResponse> InvokeCtlAsync(InvokeCtlType type);

    public ValueTask<OkResponse> AcceptBidAsync(List<RequestCard> cards);

    public void OnError(Exception e);
}

public class RpcPipe
{
    private readonly WebSocket _socket;
    private readonly CancellationToken _token;
    private readonly IRpcListener _server;


    public RpcPipe(WebSocket socket, IRpcListener server, CancellationToken token = default)
    {
        _socket = socket;
        _server = server;
        _token = token;
    }

    private async ValueTask<RpcResponse> Invoke(RpcRequest req)
    {
        var rsp = new RpcResponse { Id = req.Id };

        if (req.Connect != null)
        {
            rsp.Ok = await _server.ConnectAsync(req.Connect);
        }
        else if (req.Create != null)
        {
            var newId = await _server.CreateLobbyAsync(req.Create.PlayerName);
            rsp.LobbyList = new LobbyListResponse { Lobbies = await _server.GetLobbyListAsync(), JustCreated = newId };
        }
        else if (req.Join != null)
        {
            rsp.Ok = await _server.JoinLobbyAsync(req.Join.LobbyId, req.Join.PlayerName);
        }
        else if (req.GetInfo != null)
        {
            if (req.GetInfo == GetInfoType.Lobbies)
            {
                rsp.LobbyList = new LobbyListResponse { Lobbies = await _server.GetLobbyListAsync() };
            }
            else
            {
                rsp.Error = "unknown info type";
            }
        }
        else if (req.Bid != null)
        {
            rsp.Ok = await _server.AcceptBidAsync(req.Bid.Cards);
        }
        else if (req.InvokeCtl.HasValue)
        {
            rsp.Ok = await _server.InvokeCtlAsync(req.InvokeCtl.Value);
        }
        else if (req.TestRequest != null)
        {
            rsp.Ok = new OkResponse { Message = req.TestRequest.Message };
        }
        else
        {
            rsp.Error = "unknown request";
        }

        return rsp;
    }

    public async Task Send(RpcResponse rsp)
    {
        var data = JsonSerializer.SerializeToUtf8Bytes(rsp, RpcJsonContext.Default.RpcResponse);
        await _socket.SendAsync(data, WebSocketMessageType.Text, true, _token);
    }

    private async Task HandleRecv(string data)
    {
        var id = -1;

        Debug.WriteLine(data);

        try
        {
            var req = JsonSerializer.Deserialize<RpcRequest>(data, RpcJsonContext.Default.RpcRequest)!;
            id = req.Id;
            var rsp = await Invoke(req);
            await Send(rsp);
        }
        catch (Exception e)
        {
            await Send(new RpcResponse { Id = id, Error = e.Message });
        }
    }

    private async Task RunAsyncInner()
    {
        var buf = WebSocket.CreateServerBuffer(4096);
        var recvResult = await _socket.ReceiveAsync(buf, _token);
        while (!recvResult.CloseStatus.HasValue)
        {
            await HandleRecv(Encoding.UTF8.GetString(buf.Array!, buf.Offset, recvResult.Count));
            recvResult = await _socket.ReceiveAsync(buf, _token);
        }

        await _socket.CloseAsync(recvResult.CloseStatus.Value, recvResult.CloseStatusDescription, _token);
    }

    public async Task RunAsync()
    {
        try
        {
            await RunAsyncInner();
        }
        catch (Exception e)
        {
            _server.OnError(e);
        }
    }
}