require 'sinatra'
require 'sinatra/reloader'
require './wrapper'

get '/' do 
	erb :input
end

post '/submit' do
	@text = params['text']
	wrapper = Wrapper.new
	File.open('input.txt', 'w') {|f| f.write(@text)}
	@entities = wrapper.call('input.txt')
	erb :output
end