using BalaloGame;

var deck = Deck.GenerateDefault();
for (var i = 0; i < 5; i++)
{
    deck.Shuffle();
    PrintHand(deck.DrawMany(5).ToList());
}

void PrintHand(List<Card> hand )
{
    var scoring = new ScoringHand(hand);
    var scoreType = scoring.GetScoringType();
    Console.WriteLine("=== HAND ===");
    Console.WriteLine($"{string.Join(", ", hand)}");
    Console.WriteLine($"IS A {scoreType}");
    Console.WriteLine("=============\n");
}