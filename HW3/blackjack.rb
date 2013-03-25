require 'pp'
require 'sinatra'
require_relative 'bj'

def clear_screen
  puts "\e[H\e[2J"
end

player_count = deck_count= 0
clear_screen

while player_count == 0
  p "How many players for this game?"
  player_count = gets.chomp
  player_count  = player_count.to_i

  p "Please enter a valid number of players" if player_count == 0
end

clear_screen

while deck_count == 0 
  p "How many decks for this game? It's recommended to use at least 2 decks"
  deck_count = gets.chomp
  deck_count = deck_count.to_i
  p "Please enter a valid number of decks to be played with" if deck_count == 0

  p "Initializing game with 1 deck.  All hands will be hidden throughout the game." if deck_count == 1
end

  game = Blackjack::Game.new(player_count, deck_count) 

clear_screen if deck_count > 1
  for i in 0...player_count
    if i == 0 
      p "You are in 1st position.  What is your name?"
      game.table.players[i].name = gets.chomp
      clear_screen
    else #getting name for all other positions.
      p "What is player #{i+1}'s name?"
      game.table.players[i].name = gets.chomp
      clear_screen
    end
  end

game.deal

dealer  = game.table.dealer
players = game.table.players

clear_screen

players.each do |player|
  
  p "#{player.name} shows #{player.hand.to_s}"
end

if deck_count > 1
  dealer_up_card = dealer.hand.cards[1].keys[0]
  p "Dealer shows #{dealer_up_card}."
else
  p "Dealer's hand is hidden."
end

#getting initial hand totals here.
players.each_with_index do |player, position|

  player_total_lh = player.hand.evaluate
  player_total_l = player_total_lh.values[0]
  player_total_h = player_total_lh.values[1]

  true_total = player_total_l  < player_total_h ? player_total_h : player_total_l

  if true_total == 21 && position == 0
    p "BLACKJACK!! Please wait until the other positions have finished."
    players.first.hand.total = true_total
  end

  if position == 0 #Human player options after deal
    card_hit = 2 # index to start with

    while true_total < 21
      p "Your total is #{true_total}.  Would you like to hit or stay?  Enter '1' for hit or '2' for stay"
      choice = gets.chomp.to_i

      clear_screen

      if choice == 1
        p "You chose to hit."

        game.hit(player)
        p "Your new card is #{player.hand.cards[card_hit].keys[0]}"

        true_total += player.hand.cards[card_hit].values[0]

        p "Your new total is #{true_total}"

        card_hit += 1

        if true_total > 21
          p "You busted! Womp womp!"
          player.hand.total = nil
        elsif true_total == 21
          p "You got 21, you lucky dog you!"
          player.hand.total = true_total
        end

      elsif choice == 2
        p "You chose to stay.  Your total is #{true_total}"
        player.hand.total = true_total
        break # we're done

      else #if choice is anything other than 1 or 2.
        p "Please enter a valid choice."
      end
    end

  else #For all the other players.  Their logic is the same as the dealer's: hit until 17, then stay.

    computer_card_hit = 2
    hit_count = 0

    if true_total < 17
      if deck_count > 1 # only show if more than one deck in play
        p "#{player.name}'s turn, showing #{player.hand.to_s}"
      else
        p "#{player.name}'s turn."
      end

      # hit until at least 17
      while true_total < 17
        p "#{player.name} chooses to hit."

        card = game.hit(player)

        p "#{player.name}'s new card: #{card.keys[0]}" if deck_count > 1
        true_total += card.values[0]

        if true_total > 21
            p "#{player.name} busted!" if deck_count > 1
          player.hand.total = nil
        end
        computer_card_hit += 1
        hit_count += 1
      end

      if true_total < 21
        player.hand.total = true_total

        if deck_count > 1
          puts "#{player.name} chooses to stay with: #{player.hand.to_s}"
        else
          p "#{player.name} chooses to stay."
        end
      end

    elsif true_total < 21

      if deck_count > 1
        p "#{player.name}'s turn.  They chose to stay with #{player.hand.to_s}."
      else
        p "#{player.name}'s turn.  They choose to stay."
      end

      player.hand.total = true_total
    end
  end
end

# evaluate dealer's hand
d_total_lh  = dealer.hand.evaluate
d_total_l   = d_total_lh.values[0]
d_total_h   = d_total_lh.values[1]

dealer_total = d_total_l < d_total_h ? d_total_h : d_total_l

p "Dealer shows #{dealer.hand.to_s}." if deck_count > 1

if dealer_total == 21
  p "Dealer has Blackjack!" if deck_count > 1
  dealer.hand.total = dealer_total
else
  #Dealer hits until value shown is above 17, then shows last card to get final total.
  x = 2
  while dealer_total < 17
    p "Dealer's turn.  She chooses to hit."
    game.hit(dealer)
    p "Dealer's new card is #{dealer.hand.cards[x].keys[0]}" if deck_count > 1
    dealer_total += dealer.hand.cards[x].values[0]
    x += 1
  end
  if dealer_total > 21
    dealer.hand.total = nil 
  else
    p "Dealer stays"
    dealer.hand.total = dealer_total
  end
end

if dealer.hand.total == nil # dealer has busted
  p "------------------"
  p "The dealer busted!"

  #if the human wins
  p "YOU WIN! Winner, Winner chicken dinner!" if players.first.hand.total

  players.each do |player|
    outcome = player.hand.total.nil? ? "busted" : "wins"
    p "#{player.name} #{outcome}!"
  end      

else
  p "------------------"
  p "The dealer's total is #{dealer_total}"

  #human player

  players.each do |player|
    total = player.hand.total
    if total
      p "#{player.name}'s total is #{total}. Win!"  if total > dealer_total
      p "#{player.name}'s total is #{total}. Lost!" if total < dealer_total
      p "#{player.name}'s total is #{total}. Push!" if total == dealer_total
    else
      p "#{player.name} busted."
    end
  end
end
