namespace BalaloGame;

public enum CardSuit
{
    Spade,
    Heart,
    Diamond,
    Club
}

public enum CardValue
{
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
    Ace,
}

public class Card
{
    private CardValue _value;
    private CardSuit _suit;

    public CardValue Value => _value;
    public int ValueInt => _value switch
    {
        CardValue.Two => 2,
        CardValue.Three => 3,
        CardValue.Four => 4,
        CardValue.Five => 5,
        CardValue.Six => 6,
        CardValue.Seven => 7,
        CardValue.Eight => 8,
        CardValue.Nine => 9,
        CardValue.Ten => 10,
        CardValue.Jack or CardValue.Queen or CardValue.King => 11,
        CardValue.Ace => 12,
        _ => throw new ArgumentOutOfRangeException(nameof(_value), _value, null)
    };

    public Card(CardValue value, CardSuit suit)
    {
        _value = value;
        _suit = suit;
    }

    public bool Is(CardValue value) => _value == value;
    
    public bool IsSameSuit(Card other) => _suit == other._suit;
    public bool IsSameValue(Card other) => _value == other._value;
    
    public override string ToString()
    {
        return $"{_value} of {_suit}s";
    }
}