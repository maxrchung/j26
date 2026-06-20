using JamServer.Lobby;
using JamServer.Models;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;

namespace JamServer.Controllers;

public class LobbyController(LobbyCoordinator coordinator, ILogger<LobbyController> logger) : IController
{
    private Ok<LobbyListResponse> GetLobbies()
    {
        logger.LogInformation("Getting lobbies");
        return TypedResults.Ok(new LobbyListResponse
        {
            Lobbies = coordinator.GetLobbies().ToList()
        });
    }

    private Results<Ok<LobbyJoinResponse>, NotFound> JoinLobby([FromBody] LobbyJoinRequest req)
    {
        if (!coordinator.TryFindLobby(req.Id, out var lobby))
        {
            return TypedResults.NotFound();
        }

        var key = lobby.InvitePlayer(req.PlayerName);
        return TypedResults.Ok(new LobbyJoinResponse
        {
            PlayerKey = key,
            Lobby = lobby.GetFullLobbyInfo(),
        });
    }

    private Results<Ok<LobbyInfo>, BadRequest> CreateLobby([FromBody] LobbyCreateRequest req)
    {
        var lobby = coordinator.CreateLobby(req.Name);
        return TypedResults.Ok(lobby.Info);
    }

    public void Map(IEndpointRouteBuilder builder)
    {
        var group = builder.MapGroup("/lobbies");
        group.MapGet("/", GetLobbies);
        group.MapPost("/create", CreateLobby);
        group.MapPost("/join", JoinLobby);
    }
}