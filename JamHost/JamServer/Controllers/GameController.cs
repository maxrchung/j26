using JamServer.Lobby;
using JamServer.Models;
using JamServer.RPC;
using Microsoft.AspNetCore.Http.HttpResults;

namespace JamServer.Controllers;

public partial class GameController(LobbyCoordinator coordinator, ILogger<GameController> logger) : IController
{
    private async ValueTask<Results<ServerSentEventsResult<GameUpdate>, BadRequest<GenericResponse>>> Connect(
        HttpContext ctx)
    {
        var key = ctx.Request.Headers["X-Player-Key"].FirstOrDefault();
        if (!Guid.TryParse(key, out var playerKey))
        {
            return GenericResponse.BadRequest("malformed player key");
        }

        if (!coordinator.TryUseKey(playerKey, out var player))
        {
            return GenericResponse.BadRequest("invalid player key");
        }

        LogPlayerPlayerConnected(player.Name);
        var playerChan = new PlayerChannel();
        await playerChan.PushJoin();

        return TypedResults.ServerSentEvents(playerChan.Updates.ReadAllAsync());
    }

    private async ValueTask<IResult> GetSocket(HttpContext ctx)
    {
        if (!ctx.WebSockets.IsWebSocketRequest) return GenericResponse.BadRequest("not a websocket");
        using var stream = await ctx.WebSockets.AcceptWebSocketAsync();
        var chan = new RpcPipe(stream, new DummyServer());
        await chan.RunAsync();
        return Results.Ok();
    }

    public void Map(IEndpointRouteBuilder endpoints)
    {
        var group = endpoints.MapGroup("/game");
        group.MapGet("/stream", Connect);
        group.MapGet("/socket", GetSocket);
    }

    [LoggerMessage(LogLevel.Information, "Player {Player} connected")]
    partial void LogPlayerPlayerConnected(string player);
}