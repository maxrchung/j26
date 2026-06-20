using JamServer.Game;

namespace JamServer.Models;

public record CardInfo
{
    public required CardSuit Suit { get; init; }
    public required CardValue Value { get; init; }
}