require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'

def require_user_name
  redirect('/') unless has_user_name?
end

def has_user_name?
  session[:user_name]
end

def create_deck
 ((2..10).to_a << "Jack" << "Queen" << "King" << "Ace").product(["Spades", "Clubs", "Hearts", "Diamonds"]).shuffle
end

def deal_opening_hands
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
end

def place_bet
  if session[:bet] > session[:bank]
    @error = "Your bet was bigger than your bank, you went all in!"
    session[:bet] = session[:bank]
  end
  session[:bank] -= session[:bet]
end

def evaluate_totals(player_hand, dealer_hand)
  session[:player_total] = calculate_total(player_hand)
  session[:dealer_total] = calculate_total(dealer_hand)
end

def players_finished?
  session[:dealer_total] > 17 && session[:dealer_turn]
end

def start_new_game
    session[:dealer_turn] = false
    session[:deck] = create_deck
    session[:player_hand] = []
    session[:dealer_hand] = []
    session[:bet] = 0
end

def game_over
  session.clear
  redirect '/'
end

def bust?(total)
  total > 21
end

def either_players_bust?
  player_bust? || dealer_bust?
end

def player_bust?
  bust?(session[:player_total])
end

def dealer_bust?
  bust?(session[:dealer_total])
end
  
def blackjack?
 session[:player_hand].size == 2 && session[:player_total] == 21
end

def dealer_blackjack?
  session[:dealer_hand].size == 2 && session[:dealer_total] == 21
end

helpers do
  def image_source(card)
    "<img src='/images/cards/" + card[1].downcase + "_" + card[0].to_s.downcase + ".jpg' class='card_image' />"
  end

  def calculate_total(hand)
    total = 0
    
    card_values = hand.map { |card| card[0] }
    
    card_values.each do |value|
      if value == "Ace"
        total += 11
      elsif value == "Jack" || value == "Queen" || value == "King"
        total += 10
      else
        total += value.to_i
      end
    end
    
    card_values.select{ |val| val == "Ace"}.count.times do
      total -= 10 if total > 21
    end
    total
  end
end

def find_winner
  if player_bust? || dealer_blackjack?
    "Dealer"
  elsif blackjack? || dealer_bust? || (session[:dealer_total] < session[:player_total])
    session[:user_name]
  elsif session[:dealer_total] >= session[:player_total]
    "Dealer"
  end
end

get '/' do
  redirect('/bet') if has_user_name?
  erb :set_name
end

post '/set_name' do
  session[:user_name] = params[:user_name]
  session[:bank] = 500
  redirect '/bet'
end

get '/bet' do
  require_user_name
  start_new_game
  erb :bet
end

post '/place_bet' do
  require_user_name
  unless params[:bet].to_i.to_s == params[:bet]
    @error = "Please enter a valid number"
    halt erb :bet
  end
  session[:bet] = params[:bet].to_i
  place_bet
  redirect '/game'
end

get '/game' do
  require_user_name
  deal_opening_hands if session[:player_hand].empty?
  evaluate_totals(session[:player_hand], session[:dealer_hand])
  redirect '/find_winner' if blackjack?
  erb :game
end

post '/game/player/hit' do
  session[:player_hand] << session[:deck].pop
  evaluate_totals(session[:player_hand], session[:dealer_hand])
  redirect'/find_winner' if player_bust?
  erb :game, layout: false
end

post '/game/player/stay' do
  session[:dealer_turn] = true
  redirect '/game/dealer_turn'
end

get '/start_over' do
  session.clear
  redirect '/'
end

get '/game/dealer_turn' do
  require_user_name
  if dealer_blackjack?
    @error = "The dealer hit blackjack!"
    sleep 4
    redirect '/game_over'
  elsif session[:dealer_total] > 17
    @error = "The dealer stays at #{session[:dealer_total]}."
    redirect '/game_over'
  elsif session[:dealer_hand].size ==2
    @error = "The dealer reveals his card"
  end
  erb :game, layout: false
end

post '/game/dealer/hit' do
  if session[:dealer_total] < 17
    session[:new_dealer_card] = session[:deck].pop
    session[:dealer_hand] << session[:new_dealer_card]
    evaluate_totals(session[:player_hand], session[:dealer_hand])
    erb :game, layout: false
  else
    session[:dealer_turn] = false
    redirect '/find_winner'
  end
end

get '/find_winner' do
  require_user_name
  evaluate_totals(session[:player_hand], session[:dealer_hand])
  session[:winner] = find_winner
  (session[:bank] += (session[:bet] * 2)) if session[:winner] == session[:user_name]
  redirect '/game_over'
end

get '/game_over' do
  require_user_name
  session[:dealer_turn] = false
  @game_over = true
  if session[:winner] == session[:user_name]
    msg = "#{session[:user_name]} wins with #{session[:player_total]}.\r"
    (msg = msg + "#{session[:user_name]} hit Blackjack!\r") if blackjack?
    (msg = "The dealer busted!\r" + msg) if dealer_bust?
    @success = msg + "$#{session[:bet] * 2} added to the bank"
  elsif player_bust? 
    @error = "#{session[:user_name]} busted.\r $#{session[:bet]} lost!"
  elsif dealer_blackjack?
    @error = "The dealer hit Blackjack.\r $#{session[:bet]} lost!"
  else
    @error = "The dealer wins with #{session[:dealer_total]}.\r$#{session[:bet]} lost!"
  end
    
  erb :game
end



post '/again' do
  if params[:yes_or_no] == "no"
    game_over
  else
    redirect '/bet'
  end
end




