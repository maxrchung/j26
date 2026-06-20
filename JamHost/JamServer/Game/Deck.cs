using JamServer.Models;

namespace JamServer.Game;

public class Deck
{
    private readonly List<Card> _cards;

    private Deck(List<Card>? cards = null)
    {
        _cards = cards ?? [];
    }

    private static readonly CardSuit[] StartingSuits =
    [
        CardSuit.Clubs,
        CardSuit.Diamonds,
        CardSuit.Hearts,
        CardSuit.Spades,
    ];

    private static readonly CardValue[] StartingValues =
    [
        CardValue.Ace,
        CardValue.Two,
        CardValue.Three,
        CardValue.Four,
        CardValue.Five,
        CardValue.Six,
        CardValue.Seven,
        CardValue.Eight,
        CardValue.Nine,
        CardValue.Ten,
        CardValue.Jack,
        CardValue.Queen,
        CardValue.King,
    ];

    public static Deck CreateDefault()
    {
        var cards = new List<Card>();
        foreach (var suit in StartingSuits)
        {
            foreach (var value in StartingValues)
            {
                cards.Add(new Card(suit, value));
            }
        }

        return new Deck(cards);
    }

    public IEnumerable<CardInfo> GetCardInfos() => _cards.Select(x => x.Info);
}