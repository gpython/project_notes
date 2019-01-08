#encoding:utf-8
import redis

class RedisClient(object):
  def __init__(self, name, host, port, db):
    self.key_name = name
    self.__conn = redis.Redis(host=host, port=port, db=db)

  def sadd(self, value):
    return self.__conn.sadd(self.key_name, value)

  def random(self, count=1):
    return self.__conn.SRANDMEMBER(self.key_name, count)


