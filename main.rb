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
  !!session[:user_name]
end

def create_deck
  ["Spades", "Clubs", "Hearts", "Diamonds"].product((2..10).to_a << "Jack" << "Queen" << "King" << "Ace").shuffle
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

def calculate_total(hand)
  total = 0
  
  card_values = hand.map { |card| card[1] }
  
  card_values.each do |value|
    if value == "Ace"
      total += 11
    elsif value.to_i == 0
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

def evaluate_totals(player_hand, dealer_hand)
  session[:player_total] = calculate_total(player_hand)
  session[:dealer_total] = calculate_total(dealer_hand)
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
  erb :bet
end

post '/place_bet' do
  session[:bet] = params[:bet].to_i
  redirect '/game'
end

get '/game' do
  require_user_name
  if session[:player_hand].empty?
    session[:deck] = create_deck
    session[:player_hand] = []
    session[:dealer_hand] = []
    deal_opening_hands
  end
  place_bet if session[:bet]
  evaluate_totals(session[:player_hand], session[:dealer_hand])
  erb :game
end

post '/hit' do
  session[:player_hand] << session[:deck].pop
  redirect '/game'
end

post '/stay' do
  
end






