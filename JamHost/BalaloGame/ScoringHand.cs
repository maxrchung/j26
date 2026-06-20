namespace BalaloGame;

public enum ScoringType
{
    HighCard,
    Pair,
    TwoPair,
    ThreeOfAKind,
    Straight,
    Flush,
    FullHouse,
    FourOfAKind,
    StraightFlush,
    RoyalFlush,
    FiveOfAKind,
}

public record CardMatch
{
    public required ScoringType Type { get; init; }
    public List<Card> Cards { get; init; } = [];

    public override string ToString()
    {
        return $"{Type} with ({string.Join(", ", Cards)})";
    }
}

public record OfAKind(int N, CardValue Value, List<Card> Cards);

public class ScoringHand
{
    public const int HandSize = 5;

    // stored in descending order (ace->2)
    private readonly List<Card> _cards;

    public ScoringHand(IEnumerable<Card> cards)
    {
        _cards = cards.OrderByDescending(x => x.Value).ToList();
    }

    private List<OfAKind> CalculateOfAKind()
    {
        var counts = new Dictionary<CardValue, (int count, List<Card> cards)>();
        foreach (var card in _cards)
        {
            counts.TryAdd(card.Value, (0, []));
            var (count, list) = counts[card.Value];
            counts[card.Value] = (count + 1, list.Append(card).ToList());
        }

        return counts.Where(x => x.Value.count >= 2)
            .Select(x => new OfAKind(x.Value.count, x.Key, x.Value.cards)).ToList();
    }

    private bool IsFullHand => _cards.Count == HandSize;


    private bool CheckForStraight()
    {
        // need to be able to make a straight lol
        if (!IsFullHand || _cards.First().Value < CardValue.Seven) return false;
        for (var i = 1; i < HandSize; i++)
        {
            if (_cards[i].Value != _cards[i - 1].Value - 1) return false;
        }

        return true;
    }

    private bool CheckForFlush()
    {
        if (!IsFullHand) return false;
        // check if every card is same suit as every other card
        return _cards.All(card => _cards.All(x => x.IsSameSuit(card)));
    }

    private CardMatch FullMatchOf(ScoringType type) => new() { Type = type, Cards = _cards, };

    public CardMatch GetScoringType()
    {
        var ofAKind = CalculateOfAKind();
        var highestOfAKindV = ofAKind.OrderByDescending(x => x.N).FirstOrDefault();
        var highestOfAKind = highestOfAKindV?.N ?? 0;

        if (highestOfAKind == 5) return FullMatchOf(ScoringType.FiveOfAKind);

        var hasFlush = CheckForFlush();
        var hasStraight = CheckForStraight();
        var highestCard = _cards.First().Value;

        if (highestCard == CardValue.Ace && hasFlush && hasStraight) return FullMatchOf(ScoringType.RoyalFlush);
        if (hasFlush && hasStraight) return FullMatchOf(ScoringType.StraightFlush);

        if (highestOfAKind == 4)
            return new CardMatch
            {
                Type = ScoringType.FourOfAKind,
                Cards = highestOfAKindV!.Cards
            };

        if (highestOfAKind == 3 && ofAKind.Any(x => x.N == 2)) return FullMatchOf(ScoringType.FullHouse);

        if (hasFlush) return FullMatchOf(ScoringType.Flush);
        if (hasStraight) return FullMatchOf(ScoringType.Straight);
        if (highestOfAKind == 3) return FullMatchOf(ScoringType.ThreeOfAKind);

        var pairs = ofAKind.Where(x => x.N == 2).ToList();
        if (pairs.Count == 2)
        {
            return new CardMatch
            {
                Type = ScoringType.TwoPair,
                Cards = pairs.SelectMany(x => x.Cards).ToList()
            };
        }

        ;

        if (pairs.Count == 1)
        {
            return new CardMatch
            {
                Type = ScoringType.Pair,
                Cards = pairs.First().Cards
            };
        }

        return new CardMatch { Type = ScoringType.HighCard, Cards = [_cards.First()] };
    }
}