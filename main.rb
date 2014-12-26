require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'set_name' 
def require_user_name
  redirect('/') unless has_user_name?
end

def has_user_name?
  !!session[:user_name]
end
@player =''


get '/' do
  if !@player
    erb :set_name
  else
    redirect '/game'
  end
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
  if session[:bet] > session[:bank]
    @error = "Your bet was bigger than your bank, you went all in!"
    session[:bet] = session[:bank]
  end
  session[:bank] -= session[:bet]
  redirect '/game'
end

get '/game' do
  require_user_name
  erb :game
end





