namespace BalaloGame;

public class GamePlayer
{
    private readonly GameBoard _board;
    private List<int> _hand = [];
    public Guid Id;
    public int HandSize = 3;
    public int Score = 0;

    public GamePlayer(GameBoard board, Guid id)
    {
        _board = board;
        Id = id;
    }

    public List<Card> HandCards => _hand.Select(i => _board[i]).ToList();

    public void SetHand(List<int> cards)
    {
        _hand = cards;
    }

    public int GetScore() {
        return Score;
    }

    public void IncreaseHandSize() {
        HandSize += 1;
    }

    public void IncreasePoints(int points) {
        Score += points;
    }

    public void DecreasePoints(int points) {
        Score -= points;
    }
}