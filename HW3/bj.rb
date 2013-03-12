MAX_INT = (2 ** (0.size * 8 - 1)) # this is used when 'randomly' shuffling the deck

module Blackjack

  class Game
    attr_accessor :deck, :table

    def initialize(players = 1, decks = 1)
      self.deck   = Deck.new(decks)
      self.table  = Table.new(players)
    end

    def deal
      players = table.players
      dealer  = table.dealer

      2.times do
        players.each do |player|
          player.dealt self.deck.deal_card
        end

        dealer.dealt self.deck.deal_card
      end
    end
    def hit(player)
      return unless player
      player.dealt self.deck.deal_card
    end

  end

  class Table
    attr_accessor :players, :dealer

    def initialize(player_count = 1)
      self.dealer   = Dealer.new
      self.players  = []

      # go ahead and initialize Player objects for later use
      player_count.times do
        self.players << Player.new
      end
    end
  end

  class Player
    attr_accessor :hand, :name

    def initialize
      self.hand = Hand.new
    end

    def dealt(card = {})
      self.hand.add card
    end
  end

  class Dealer < Player; end

  class Hand
    attr_accessor :cards, :total

    def initialize
      self.cards = []
    end

    def add(card = {})
      self.cards << card
      card
    end

    def evaluate
      total = {low: 0, high: 0}
      self.cards.each do |card|
        value = card.values[0]

        case value
        when 1
          total[:low] += 1
          total[:high] += 11
        else
          total[:low] += value
          total[:high] += value
        end
      end
      total
    end

    def to_s
      cards_string = ""

      self.cards.each do |card|
        cards_string << "#{card.keys[0]} "
      end

      cards_string
    end

  end

  class Deck
    attr_accessor :cards, :deck_count

    def initialize(decks = 1)
      self.deck_count = decks if decks >= 1

      if self.deck_count
        self.cards = shuffle(build_deck(decks), build_shuffler(decks))
      end
    end

    def deal_card
      self.cards.pop
    end

  private

    # correlate items in the unrandom 'decks' array with those in the random 'shuffler' array & sort on random to randomize unrandom.
    def shuffle(decks, shuffler)
      return nil if decks.count * 52 != shuffler.count

      hsh = {}
      index = 0
      shuffled_deck = []

      # correlate random and unrandom array items via sorted hash
      decks.each do |deck|
        deck.each do |k, v|
          hsh.merge!((shuffler[index]) => {k => v})
          index += 1
        end
      end

      # we are only interested in the previously unrandom data (not the random number correlated earlier)
      hsh.sort.each do |ary|
        shuffled_deck << ary[1]
      end

      shuffled_deck
    end

    # this method returns an array consisting of deck-ordered cards from 'deck_count' number of decks
    def build_deck(deck_count = 1)
      arr = []
      for i in 1..deck_count
        deck_hash = {}
        ['Clubs', 'Hearts', 'Spades', 'Diamonds'].each do |suit|
          val = 0
          ['A ','2 ','3 ','4 ','5 ','6 ','7 ','8 ','9 ','10 ','J ','Q ','K '].each do |face|
            val += 1 unless val == 10
            deck_hash.merge!({"#{face}#{suit}".to_sym => val})
          end
        end
        arr << deck_hash
      end
      arr
    end

    # this method builds an array of 'random' numbers of length 'deck_count * 52' -- one for every card
    def build_shuffler(deck_count = 1)
      arr = []

      for i in 1..deck_count
        for j in 1..52
          arr << rand(MAX_INT)
        end
      end
      arr
    end
  end
end