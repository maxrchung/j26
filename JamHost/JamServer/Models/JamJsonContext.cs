using System.Net.ServerSentEvents;
using System.Text.Json.Serialization;

namespace JamServer.Models;

// general
[JsonSerializable(typeof(GenericResponse))]
// lobby
[JsonSerializable(typeof(LobbyListResponse))]
[JsonSerializable(typeof(LobbyCreateRequest))]
[JsonSerializable(typeof(LobbyJoinRequest))]
[JsonSerializable(typeof(LobbyJoinResponse))]
// game
[JsonSerializable(typeof(SseItem<GameUpdate>))]
internal partial class JamJsonContext : JsonSerializerContext
{
}