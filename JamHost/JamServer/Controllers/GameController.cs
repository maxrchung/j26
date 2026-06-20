using JamServer.Lobby;
using JamServer.Models;
using JamServer.RPC;

namespace JamServer.Controllers;

public partial class GameController(
    IServiceProvider services,
    ILogger<GameController> logger) : IController
{
    private async Task GetSocket(HttpContext ctx)
    {
        if (!ctx.WebSockets.IsWebSocketRequest)
        {
            ctx.Response.StatusCode = 400;
            return;
        }

        using var stream = await ctx.WebSockets.AcceptWebSocketAsync();
        var player = new PlayerChannel(services, stream);
        await player.RunAsync();
    }

    public void Map(IEndpointRouteBuilder endpoints)
    {
        var group = endpoints.MapGroup("/game");
        group.MapGet("/socket", GetSocket);
    }

    [LoggerMessage(LogLevel.Information, "Player {Player} connected")]
    partial void LogPlayerPlayerConnected(string player);
}