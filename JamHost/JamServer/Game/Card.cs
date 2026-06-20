using System.Text.Json.Serialization;
using JamServer.Models;

namespace JamServer.Game;

public enum CardSuit
{
    [JsonStringEnumMemberName("clubs")] Clubs,
    [JsonStringEnumMemberName("diamonds")] Diamonds,
    [JsonStringEnumMemberName("hearts")] Hearts,
    [JsonStringEnumMemberName("spades")] Spades,
}

public enum CardValue
{
    Ace,
    Two,
    Three,
    Four,
    Five,
    Six,
    Seven,
    Eight,
    Nine,
    Ten,
    Jack,
    Queen,
    King,
}

public class Card(CardSuit suit, CardValue value)
{
    public readonly CardSuit Suit = suit;
    public readonly CardValue Value = value;

    public CardInfo Info => new()
    {
        Suit = Suit,
        Value = Value,
    };
}