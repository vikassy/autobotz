require 'sinatra'
require 'redis'
require "erb"
require 'cinch'
require 'sanitize'


set :environment, :production #For ip:4567 , comment this to get localhost:4567
#redis = Redis.new(:host => '127.0.0.1', :port => 6379)
redis = Redis.new(:host => '127.4.45.1', :port => 15008) #This is for development
# redis = Redis::new(:path=>"#{ENV['OPENSHIFT_GEAR_DIR']}tmp/redis.sock") #This is for production

#================================================This is the code of the bot ===================================

$channels_to_be_tracked = ["#nitk-autobotz"]
time = Time.now.localtime("+05:30")

class Logger

  attr_accessor :redis

  def initialize(ip,port) 
    #@redis = Redis.new(:host => ip, :port => port) #This is for development
    @redis = Redis.new(:host => '127.4.45.1', :port => 15008)
    # @redis = Redis::new(:path=>"#{ENV['OPENSHIFT_GEAR_DIR']}tmp/redis.sock") #This is for production
    len = redis.LLEN "channels"
    registered_channel = redis.lrange('channels',0,len)
    puts "-----------------------------------------------"
    puts "The registered channels are : "
    puts "-----------------------------------------------"
    puts registered_channel
    $channels_to_be_tracked.each do |f|
      puts f
      if not registered_channel.include?(f)
        @redis.LPUSH "channels" , f
      end
    end
    puts "-----------------------------------------------"
    puts "End of initialize"
    puts "-----------------------------------------------"
  end

  def get_time
    Time.now.localtime("+05:30")
  end

  def get_log_time
    t = get_time
    "#{t.hour}:#{t.min}:#{t.sec}"
  end

  def log(channel,user,msg)
    puts "-----------------------------------------------"
    puts "Inside log....."
    puts "#{channel}:#{get_time.strftime("%d-%m-%Y")}"
    puts "-----------------------------------------------"
    len =  @redis.LLEN "#{channel}:#{get_time.strftime("%d-%m-%Y")}"
    if len.to_i == 0
      puts "-----------------------------------------------"
      puts "Length of the list is zero"
      puts "-----------------------------------------------"
      @redis.LPUSH "#{channel}" , "#{get_time.strftime("%d-%m-%Y")}"
    end
    puts "-----------------------------------------------"
    puts "#{channel}:#{get_time.strftime("%d-%m-%Y")}"
    puts "-----------------------------------------------"
    nick = Sanitize.clean(user.nick)
    @redis.LPUSH "#{channel}:#{get_time.strftime("%d-%m-%Y")}", "<div style='color: green;display: inline'><#{get_log_time}></div>"+"<div style='color: red;display: inline'>#{nick}</div>"+": "+Sanitize.clean(msg)
  end

  def bot_log(channel,msg)    
    @redis.LPUSH "#{channel}:#{get_time.strftime("%d-%m-%Y")}", "<div style='color: green;display: inline'><#{get_log_time}></div>"+"<div style='color: red;display: inline'>autobotz</div>"+": "+msg
  end

end


bot = Cinch::Bot.new do
  logger = Logger.new('127.0.0.1',6379)
  configure do |c|
    c.server = "irc.freenode.org"
    c.channels = $channels_to_be_tracked
    c.nick = 'autobotz'
  end


  on :message,"!users" do |m|
    names = "Users: "
    m.channel.users.each do |f|
      names += f[0].to_s+" "
    end
    m.reply("#{names}")
    logger.bot_log(m.channel,names)
  end

  on :message,"!user_count" do |m|
    names = "#{m.user.nick}: Total_Users: #{m.channel.users.count}"
    m.reply("#{names}")
    logger.bot_log(m.channel,names)
  end

  on :message,"!hello" do |m|
    msg = "Hello #{m.user.nick}"
    m.reply(msg)
    logger.bot_log(m.channel,msg)
  end

  on :message,"!log" do |m|
    msg = "#{m.user.nick}: The log can be found in http://ircbot-run123.rhcloud.com/message?channel=#{(m.channel.to_s)[1,m.channel.to_s.size-1]}&date=#{logger.get_time.strftime("%d-%m-%Y")}"
    m.reply(msg)
    logger.bot_log(m.channel,msg)
  end

  on :message do |m|
    logger.log(m.channel,m.user,(m.params[1]).to_s)
  end

end

job1 = fork do
	bot.start
end

#================================================This is the code of the bot ===================================



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
  puts "-----------------------------------------------"
	puts "In the /:channel get"
  puts "-----------------------------------------------"
	@data=" "
	c = redis.lrange("\##{channel}",0,len).each do |f|
    puts f.to_s
		@data+="<a href=\" /message?channel=#{channel}&date=#{f}\">#{f}</a><br /><br />"
	end
  puts "-----------------------------------------------"
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