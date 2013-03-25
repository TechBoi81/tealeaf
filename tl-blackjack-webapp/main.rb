require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do
  def calc_total(cards)
  	arr = cards.map{|element| element[1]}
  	#each player's hand initially set to 0.
  	total = 0

  	arr.each do |face|
  		if face == 'A'
				total += 11
			else
				total += face.to_i == 0 ? 10 : face.to_i
			end
		end

		#multiple Aces logic
		arr.select{|element| element == 'A'}.count.times do
			break if total <= 21
			total -= 10
		end

		total
  end

  def card_img (card)
  	suit = card[0]
  	value = card[1]

  	if ['J', 'Q', 'K', 'A'].include?(value)
  		value = case card[1]
	  		when 'J' then 'jack'
	  		when 'Q' then 'queen'
	  		when 'K' then 'king'
	  		when 'A' then 'ace'
  		end
  	end
  	"<img src='/images/cards/#{suit}_#{value}.jpg' class='card_img'>"

  end

  def blackjack!(msg)
  	@show_buttons = false
  	@game_over = true
  	@success = "Blackjack!! Woot! #{msg}"
  end

  def winner!(msg)
  	@show_buttons = false
  	@game_over = true
  	@success = "Winner Winner Chicken Dinner! #{msg}"
  end

  def looser!(msg)
  	@show_buttons = false
  	@game_over = true
  	@error = "You lost! Womp Womp! #{msg}"
  end

  def push!(msg)
  	@show_buttons = false
  	@game_over = true
  	@inform = "What we have here is a failure to determine a winner.  #{msg}"
  end

end

before do
	@show_buttons = true
	@game_over = false

end


get '/' do
	if session[:player_name]
	#progress to the game
	redirect '/game'
	else
		redirect '/new_player'
	end
end

get '/new_player' do
  erb :new_player
end

get '/game_over' do
	erb :game_over
end

post '/new_player' do
	if params[:player_name].empty? || params[:player_name] == " "
		@error = "The name field cannot be empty."
		halt erb(:new_player)
	end

  session[:player_name] = params[:player_name].capitalize

  #progress to the game
  redirect '/game'
end

get '/game' do
	#keeps track of who's turn it is to detertmine when
	#dealer's face-down card gets shown.
session[:turn] = "player"

	suits = ['spades', 'clubs', 'hearts', 'diamonds']
	cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
	session[:deck] = suits.product(cards).shuffle!
	session[:dealer_hand] = []
	session[:player_hand] = []
	session[:dealer_hand] << session[:deck].pop
	session[:player_hand] << session[:deck].pop
	session[:dealer_hand] << session[:deck].pop
	session[:player_hand] << session[:deck].pop

	player_total = calc_total(session[:player_hand])
	if player_total == 21
		@show_buttons = false
		@inform = "You have BLACKJACK! It's the dealer's turn."
		redirect '/game/dealer'
	end

  erb :game
end

post '/game/player/hit' do
	session[:player_hand] << session[:deck].pop

	player_total = calc_total(session[:player_hand])
	if player_total > 21
		looser!("#{session[:player_name]} busted with #{player_total}.")
	elsif player_total == 21
		blackjack!("#{session[:player_name]} has 21.")
		@show_buttons = false
		redirect '/game/dealer'
	end
	erb :game
end

post '/game/player/stay' do
	@inform = "#{session[:player_name]} chose to stay."
	@show_buttons = false
	redirect '/game/dealer'
end

get '/game/dealer' do
	card1 = card2 = nil
	@show_buttons = false
	session[:turn] = "dealer"
	dealer_total = calc_total(session[:dealer_hand])
	session[:dealer_hand].each_with_index do |card, i|
		card1 = card if i == 0
		card2 = card if i == 1
	end

	if dealer_total == 21
		#if the dealer hits 21, we need to check for push conditions (player also has 21).
		#win logic resides in /game/winner and will take care of this case.
		redirect '/game/winner'
	elsif dealer_total > 21
		winner!("The dealer has busted.  You got lucky.")
	elsif dealer_total >= 17 #17 - 20
		if card1 = 'A'|| card2 == 'A'
			dealer_total -= 10
		end
		redirect '/game/winner'
	else
		#dealer hits
		@dealer_hit_btn = true
	end
	erb :game 
end

post '/game/dealer/hit' do
	session[:dealer_hand] << session[:deck].pop
	redirect '/game/dealer'

end

get '/game/winner' do
	@show_buttons = false
	player_total = calc_total(session[:player_hand])
	dealer_total = calc_total(session[:dealer_hand])

	@inform = "The dealer stays with #{dealer_total}"
	if player_total < dealer_total
		looser!("#{session[:player_name]} has #{player_total}.  The Dealer has #{dealer_total}")
	elsif player_total > dealer_total
		winner!("#{session[:player_name]} has #{player_total}.  The Dealer has #{dealer_total}")
	elsif
		push!("#{session[:player_name]} and the dealer both have #{player_total}.")
	end
		
	erb :game
end
