using System.Net.WebSockets;
using System.Text;
using System.Threading.Channels;
using JamServer.Models;

namespace JamServer.Lobby;

public class PlayerChannel
{
    public ChannelReader<GameUpdate> Updates => _updates.Reader;

    private readonly Channel<GameUpdate> _updates = Channel.CreateUnbounded<GameUpdate>();

    public async Task RunAsync(WebSocket socket)
    {
        await socket.SendAsync("CONNECTED"u8.ToArray(), WebSocketMessageType.Text, true, CancellationToken.None);
        var buf = new byte[1024];
        var recvResult = await socket.ReceiveAsync(new ArraySegment<byte>(buf), CancellationToken.None);
        while (!recvResult.CloseStatus.HasValue)
        {
            await socket.SendAsync("hi"u8.ToArray(), WebSocketMessageType.Text, true,
                CancellationToken.None);
            recvResult = await socket.ReceiveAsync(new ArraySegment<byte>(buf), CancellationToken.None);
        }

        await socket.CloseAsync(recvResult.CloseStatus.Value, recvResult.CloseStatusDescription,
            CancellationToken.None);
    }

    public async Task PushJoin()
    {
        await _updates.Writer.WriteAsync(new GameUpdate
        {
            Type = GameUpdateType.PlayerJoin
        });
    }
}