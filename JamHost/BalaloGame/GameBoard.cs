namespace BalaloGame;

public class GameBoard
{
    private readonly Deck _deck = Deck.GenerateDefault();
    private readonly List<GamePlayer> _players = [];

    public Card this[int index] => _deck.Cards[index];
    
    public IEnumerable<Card> Cards => _deck.Cards;

    public List<Card> _bid = new List<Card>();
    public int _bidValue = 0;
    public GamePlayer _bidPlayer;

    public int RoundNumber { get; private set; } = 0;

    public void NextRound()
    {
        RoundNumber++;
        var cards = Enumerable.Range(0, _deck.Size).Shuffle().ToList();
        var offset = 0;
        foreach (var player in _players)
        {
            player.SetHand(cards.Skip(offset).Take(player.HandSize).ToList());
            offset += player.HandSize;
        }
    }

    public GamePlayer AddPlayer(Guid id)
    {
        var player = new GamePlayer(this, id);
        _players.Add(player);
        return player;
    }

    public void RemovePlayer(GamePlayer player)
    {
        _players.Remove(player);
    }

    public int GetBidValue() {
        return _bidValue;
    }

    public void SetBid(List<Card> bid) {
        _bid = bid;
        _bidValue = CalculateValue(bid);
    }

    public void SetBidPlayer(GamePlayer player) {
        _bidPlayer = player;
    }

    public GamePlayer GetBidPlayer() {
        return _bidPlayer;
    }

    public bool ValidateBid(List<Card> bid) {
        var bidValue = CalculateValue(bid);
        if (bidValue <= _bidValue) {
            return false;
        }
        return true;
    }

    public int CalculateValue(List<Card> bid) {
        Random rand = new Random();
        return rand.Next();
    }

    public bool CheckBs() {
        var cards_in_play = new List<Card>();
        foreach (var player in _players) {
            cards_in_play.AddRange(player.HandCards);
        }

        var bid_copy = new List<Card>(_bid);
        foreach (var bid_card in _bid) {
            if (cards_in_play.Contains(bid_card)) {
                bid_copy.Remove(bid_card);
                cards_in_play.Remove(bid_card);
            }
        }

        if (bid_copy.Count == 0) {
            return false;
        }

        return true;
    }
}