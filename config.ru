require 'rubygems'
require 'bundler'
Bundler.require

require './irc_log.rb'
run Sinatra::Application
`ruby ./irc_bot.rb`