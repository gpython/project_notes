#encoding:utf-8
import redis

class RedisClient(object):
  def __init__(self, name, host, port, db):
    self.key_name = name
    self.__conn = redis.Redis(host=host, port=port, db=db)

  #向集合添加一个或多个成员
  def sadd(self, value):
    return self.__conn.sadd(self.key_name, value)

  #返回集合中一个或多个随机数
  def srandmember(self, count=1):
    return self.__conn.srandmember(self.key_name, count)

  #返回集合中的所有成员
  def smemebers(self):
    return self.__conn.smembers(self.key_name)

