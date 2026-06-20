using System.Text.Json.Serialization;

namespace JamServer.Game;

[JsonSerializable(typeof(Card))]
public partial class GameJsonContext : JsonSerializerContext
{
}