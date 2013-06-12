require 'redis'
redis = Redis::new(:path=>"#{ENV['OPENSHIFT_GEAR_DIR']}tmp/redis.sock")
redis.LPUSH 'msg', "msg!! here"
len = redis.LLEN 'msg'
data = redis.lrange('msg',0,len)
puts data
