require 'sinatra'
require 'redis'
require "erb"

set :environment, :production #For ip:4567 , comment this to get localhost:4567
redis = Redis.new(:host => '127.4.45.1', :port => 15008) #This is for development
# redis = Redis::new(:path=>"#{ENV['OPENSHIFT_GEAR_DIR']}tmp/redis.sock") #This is for production

get '/message' do
	channel = "#"+params[:channel].to_s
	date = params[:date].to_s
	puts channel
	puts date
	len=redis.LLEN "#{channel}:#{date}"
	data = ''
	if len == 0
		"<html><h3>Log not found</h3></html>"
	else
		data = redis.lrange("#{channel}:#{date}",0,len)
		data = data.reverse.join("<br />")
	end
	data
end

get '/:channel' do
	channel = params[:channel].to_s
	len = redis.LLEN "\##{channel}"
	puts "Here =============================================== #{len}"
	@data=" "
	c = redis.lrange("\##{channel}",0,len).each do |f|
		puts "inside"
		@data+="<a href=\" /message?channel=#{channel}&date=#{f}\">#{f}</a><br /><br />"
	end
	erb :index
end

get '/' do
	len = redis.LLEN "channels"
	puts len
	data=" "
	redis.lrange("channels",0,len).each do |f|
		data+="<a href=\" /#{f[1,f.length]}\">#{f}</a><br /><br />"
	end
	"<h3>Channels:</h3><br/><br/>"+data
end