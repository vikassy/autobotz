require 'cinch'
require 'redis'
require 'sanitize'

$channels_to_be_tracked = ["#nitk-autobotz"]
time = Time.now.localtime("+05:30")

class Logger

  attr_accessor :redis

  def initialize(ip,port) 
    # @redis = Redis.new(:host => ip, :port => port) #This is for development
    @redis = Redis.new(:host => '127.4.45.1', :port => 15008)
    # @redis = Redis::new(:path=>"#{ENV['OPENSHIFT_GEAR_DIR']}tmp/redis.sock") #This is for production
    len = redis.LLEN "channels"
    registered_channel = redis.lrange('channels',0,len)
    puts "llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll"
    puts registered_channel
    $channels_to_be_tracked.each do |f|
      puts f
      if not registered_channel.include?(f)
        @redis.LPUSH "channels" , f
      end
    end
    puts "llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll"
  end

  def get_time
    Time.now.localtime("+05:30")
  end

  def get_log_time
    t = get_time
    "#{t.hour}:#{t.min}:#{t.sec}"
  end

  def log(channel,user,msg)
    puts "iiiiiiiinnnnnnnnnnnnnnnnnnnnnnnnnnnnnssssssssssssssssiiiiiiiiiiiiiddddddddddddddddeeeeeeeeeeeee"
    puts "#{channel}:#{get_time.day}"
    len =  @redis.LLEN "#{channel}:#{get_time.day}"
    if len.to_i == 0
      puts "iiiiiiiinnnnnnnnnnnnnnnnnnnnnnnnnnnnnssssssssssssssssiiiiiiiiiiiiiddddddddddddddddeeeeeeeeeeeee"
      @redis.LPUSH "#{channel}" , "#{get_time.day}"
    end
    puts "llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll"
    puts "#{channel}:#{get_time.day}"
    nick = Sanitize.clean(user.nick)
    @redis.LPUSH "#{channel}:#{get_time.day}", "<div style='color: green;display: inline'><#{get_log_time}></div>"+"<div style='color: red;display: inline'>#{nick}</div>"+": "+Sanitize.clean(msg)
  end

  def bot_log(channel,msg)    
    @redis.LPUSH "#{channel}:#{get_time.day}", "<div style='color: green;display: inline'><#{get_log_time}></div>"+"<div style='color: red;display: inline'>autobotz</div>"+": "+msg
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
    msg = "#{m.user.nick}: The log can be found in http://ircbot-run123.rhcloud.com/message?channel=#{m.channel}&date=#{logger.get_time.day}"
    m.reply(msg)
    logger.bot_log(m.channel,msg)
  end

  on :message do |m|
    logger.log(m.channel,m.user,(m.params[1]).to_s)
  end

end

bot.start