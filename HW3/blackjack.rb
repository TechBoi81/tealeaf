require 'pp'

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


player_count = deck_count= 0
puts "\e[H\e[2J"

while player_count == 0
  p "How many players for this game?"
  player_count = gets.chomp
  player_count  = player_count.to_i

  p "Please enter a valid number of players" if player_count == 0
end


  puts "\e[H\e[2J"
while deck_count == 0 
  p "How many decks for this game? It's recommended to use at least 2 decks"
  deck_count = gets.chomp
  deck_count = deck_count.to_i
  p "Please enter a valid number of decks to be played with" if deck_count == 0

  p "Initializing game with 1 deck.  All hands will be hidden throughout the game." if deck_count == 1
end

  game = Blackjack::Game.new(player_count, deck_count) 
puts "\e[H\e[2J" if deck_count > 1
if player_count > 1
  for i in 0...player_count
    if i == 0 
      p "You are in 1st position.  What is your name?"
      name = gets.chomp
      game.table.players[i].name = name
      puts "\e[H\e[2J"
    else #getting name for all other positions.
      p "What is player #{i+1}'s name?"
      name = gets.chomp
      game.table.players[i].name = name
      puts "\e[H\e[2J"
    end
  end
else
  p "What is your name?"
  name = gets.chomp
  game.table.players[0].name = name
end

game.deal

dealer = game.table.dealer.hand
puts "\e[H\e[2J"

if deck_count > 1 
#------------------------------------------------------------------------------------------------------------------------------------
  x = 0
  while x < player_count
    card1 = game.table.players[x].hand.cards[0].keys[0]
    card2 = game.table.players[x].hand.cards[1].keys[0]
    p "#{game.table.players[x].name} shows a #{card1} and a #{card2}."
    x += 1
  end
  p "Dealer shows #{game.table.dealer.hand.cards[1].keys[0]}."

  #getting initial hand totals here.
  for position in 0...player_count
    player_total_lh = game.table.players[position].hand.evaluate
    player_total_l = player_total_lh.values[0]
    player_total_h = player_total_lh.values[1]
    if player_total_l  < player_total_h
      player_total = player_total_h
      if player_total == 21 && position == 0
        p "BLACKJACK!! Please wait until the other positions have finished."
        game.table.players[0].hand.total = player_total
      end
    else
      player_total = player_total_l
      if player_total == 21 && position == 0
        p "BLACKJACK!! Please wait until the other positions have finished."
        game.table.players[0].hand.total = player_total
      end
    end

    if position == 0 #Human player options after deal
      y = 2
      while player_total < 21
        p "Your total is #{player_total}.  Would you like to hit or stay?  Enter '1' for hit or '2' for stay"
        choice = gets.chomp
        choice = choice.to_i
        puts "\e[H\e[2J"

        if choice == 1
          p "You chose to hit."
          game.hit(game.table.players[0])
          p "Your new card is #{game.table.players[0].hand.cards[y].keys[0]}"
          player_total += game.table.players[0].hand.cards[y].values[0]
          p "Your new total is #{player_total}"
          y += 1

          if player_total > 21
            p "You busted! Womp womp!"
            game.table.players[0].hand.total = nil
          elsif player_total == 21
            p "BLACKJACK!!"
            game.table.players[0].hand.total = player_total
          end

        elsif choice == 2
          p "You chose to stay.  Your total is #{player_total}"
          game.table.players[0].hand.total = player_total
          break
        else #if choice is anything other than 1 or 2.
          p "Please enter a valid choice."
        end
      end

    else #For all the other players.  Their logic is the same as the dealer's: hit until 17, then stay.
      iter = 2
      hit_count = 0
      if player_total < 17
        p "#{game.table.players[position].name}'s turn, showing a #{card1} and a #{card2}."
        while player_total < 17
          p "#{game.table.players[position].name} chooses to hit."
          game.hit(game.table.players[position])
          p "#{game.table.players[position].name}'s new card is #{game.table.players[position].hand.cards[iter].keys[0]}"
          player_total += game.table.players[position].hand.cards[iter].values[0]

          if player_total > 21
            p "#{game.table.players[position].name} busted!"
            game.table.players[position].hand.total = nil
          end
          iter += 1
          hit_count += 1
        end
        if player_total < 21
          game.table.players[position].hand.total = player_total
          print "#{game.table.players[position].name} chooses to stay with:"
            for counter in 0...hit_count+2
              print " #{game.table.players[position].hand.cards[counter].keys[0]}"
            end
            print "\n"
        end
      elsif player_total < 21 && player_total >= 17
        p "#{game.table.players[position].name}'s turn.  They chose to stay with #{card1} & #{card2}."
        game.table.players[position].hand.total = player_total
      end
    end
  end
  d_total_lh = game.table.dealer.hand.evaluate
  d_total_l = d_total_lh.values[0]
  d_total_h = d_total_lh.values[1]
  if d_total_l < d_total_h
    dealer_total = d_total_h
  else
    dealer_total = d_total_l
  end

  p "Dealer shows #{dealer.cards[0].keys[0]}, & #{dealer.cards[1].keys[0]}."
  if dealer_total == 21
    p "Dealer has Blackjack!"
    game.table.dealer.hand.total = dealer_total
  else
    #Dealer hits until value shown is above 17, then shows last card to get final total.
    x = 2
    while dealer_total < 17
      p "Dealer's turn.  She chooses to hit."
      game.hit(game.table.dealer)
      p "Dealer's new card is #{dealer.cards[x].keys[0]}"
      dealer_total += dealer.cards[x].values[0]
      x += 1
    end
    if dealer_total > 21
      game.table.dealer.hand.total = nil
    else
      p "Dealer stays"
      game.table.dealer.hand.total = dealer_total
    end
  end

  if game.table.dealer.hand.total == nil #if the dealer has busted
    p "The dealer busted!"
    #if the human wins
    p "YOU WIN! Winner, Winner chicken dinner!" if game.table.players[0].hand.total
    for loop_var1 in 1...player_count
      #if the computer player has not busted
      p "#{game.table.players[loop_var1].name} wins!" if game.table.players[loop_var1].hand.total  
    end

  else
    #p "The dealer's total is #{dealer_total}"
    #human player
    if game.table.players[0].hand.total && game.table.players[0].hand.total > dealer_total
      p "Your total is #{game.table.players[0].hand.total}. The dealer has #{dealer_total}. You win! WOOT!"
    elsif game.table.players[0].hand.total && game.table.players[0].hand.total == dealer_total
      p "#{game.table.players[0].name}'s total is #{game.table.players[0].hand.total}.  The dealer has #{dealer_total}.  You push."
    elsif game.table.players[0].hand.total == nil 
      p "You busted! The dealer takes all your money."
    else #Dealer's total is greater than human player's total.
      p "Your total is #{game.table.players[0].hand.total}. The dealer has #{dealer_total}. You loose.  Womp womp!"
    end

    for positions in 1...player_count
      player_name = game.table.players[positions].name
      total = game.table.players[positions].hand.total
      #if the computerp player(s) haven't busted
      if total && total > dealer_total
        p "#{player_name}'s total is #{total}.  The dealer has #{dealer_total}. #{player_name} wins!"
      elsif total && total < dealer_total
        p "#{player_name}'s total is #{total}.  The dealer has #{dealer_total}. The dealer wins."
      end
    end
  end

else #if only playing with one deck

  #getting initial hand totals here.
  for position in 0...player_count
    player_total_lh = game.table.players[position].hand.evaluate
    player_total_l = player_total_lh.values[0]
    player_total_h = player_total_lh.values[1]
    if player_total_l  < player_total_h
      player_total = player_total_h
      if player_total == 21 && position == 0
        p "BLACKJACK!! Please wait until the other positions have finished."
        game.table.players[0].hand.total = player_total
      end
    else
      player_total = player_total_l
      if player_total == 21 && position == 0
        p "BLACKJACK!! Please wait until the other positions have finished."
        game.table.players[0].hand.total = player_total
      end
    end

    if position == 0 #Human player options after deal
      y = 2
      while player_total < 21
        p "Your total is #{player_total}.  Would you like to hit or stay?  Enter '1' for hit or '2' for stay"
        choice = gets.chomp
        choice = choice.to_i
        puts "\e[H\e[2J"

        if choice == 1
          p "You chose to hit."
          game.hit(game.table.players[0])
          p "Your new card is #{game.table.players[0].hand.cards[y].keys[0]}"
          player_total += game.table.players[0].hand.cards[y].values[0]
          p "Your new total is #{player_total}"
          y += 1

          if player_total > 21
            p "You busted! Womp womp!"
            game.table.players[0].hand.total = nil
          elsif player_total == 21
            p "BLACKJACK!!"
            game.table.players[0].hand.total = player_total
          end

        elsif choice == 2
          p "You chose to stay.  Your total is #{player_total}"
          game.table.players[0].hand.total = player_total
          break
        else #if choice is anything other than 1 or 2.
          p "Please enter a valid choice."
        end
      end

    else #For all the other players.  Their logic is the same as the dealer's: hit until 17, then stay.
      iter = 2
      hit_count = 0
      if player_total < 17
        while player_total < 17
          p "#{game.table.players[position].name} chooses to hit."
          game.hit(game.table.players[position])
          player_total += game.table.players[position].hand.cards[iter].values[0]

          if player_total > 21
            game.table.players[position].hand.total = nil
          end
          iter += 1
          hit_count += 1
        end
        if player_total < 21
          game.table.players[position].hand.total = player_total
          p "#{game.table.players[position].name} chooses to stay."
            for counter in 0...hit_count+2
            end
        end
      elsif player_total < 21 && player_total >= 17
        p "#{game.table.players[position].name}'s turn.  They chose to stay."
        game.table.players[position].hand.total = player_total
      end
    end
  end
  d_total_lh = game.table.dealer.hand.evaluate
  d_total_l = d_total_lh.values[0]
  d_total_h = d_total_lh.values[1]
  if d_total_l < d_total_h
    dealer_total = d_total_h
  else
    dealer_total = d_total_l
  end

  if dealer_total == 21
    game.table.dealer.hand.total = dealer_total
  else
    #Dealer hits until value shown is above 17, then shows last card to get final total.
    x = 2
    while dealer_total < 17
      p "Dealer's turn.  She chooses to hit."
      game.hit(game.table.dealer)
      dealer_total += dealer.cards[x].values[0]
      x += 1
    end
    if dealer_total > 21
      game.table.dealer.hand.total = nil
    else
      p "Dealer stays"
      game.table.dealer.hand.total = dealer_total
    end
  end

  if game.table.dealer.hand.total == nil #if the dealer has busted
    p "The dealer busted!"
    #if the human wins
    p "YOU WIN! Winner, Winner chicken dinner!" if game.table.players[0].hand.total
    for loop_var1 in 1...player_count
      #if the computer player has not busted
      p "#{game.table.players[loop_var1].name} wins!" if game.table.players[loop_var1].hand.total  
    end

  else #The dealer did not bust.
    p "The dealer's total is #{dealer_total}"
    #human player
    if game.table.players[0].hand.total && game.table.players[0].hand.total > dealer_total
      p "Your total is #{game.table.players[0].hand.total}. The dealer has #{dealer_total}. You win! WOOT!"
    elsif game.table.players[0].hand.total && game.table.players[0].hand.total == dealer_total
      p "#{game.table.players[0].name}'s total is #{game.table.players[0].hand.total}.  The dealer has #{dealer_total}.  You push."
    elsif game.table.players[0].hand.total == nil 
      p "You busted! The dealer takes all your money."
    else #Dealer's total is greater than human player's total.
      p "Your total is #{game.table.players[0].hand.total}. The dealer has #{dealer_total}. You loose.  Womp womp!"
    end

    for positions in 1...player_count
      player_name = game.table.players[positions].name
      total = game.table.players[positions].hand.total
      #if the computerp player(s) haven't busted
      if total && total > dealer_total
        p "#{player_name}'s total is #{total}.  The dealer has #{dealer_total}. #{player_name} wins!"
      elsif total && total < dealer_total
        p "#{player_name}'s total is #{total}.  The dealer has #{dealer_total}. The dealer wins."
      else #The computer players have busted
        p "#{player_name} has busted!.  The dealer wins!"
      end
    end
  end
end

