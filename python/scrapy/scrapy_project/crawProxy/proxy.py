#encoding:utf-8
from lxml import etree
from concurrent import futures
from crawlProxy.settings import USER_AGENT_LIST, MAX_WORKERS, URL_LIST, REDIS_HOST, REDIS_PORT, REDIS_DB, REDIS_KEY
from crawlProxy.DB.RedisClient import RedisClient
import random
import time
import requests


rdb = RedisClient(
  name = REDIS_KEY,
  host=REDIS_HOST,
  port=REDIS_PORT,
  db=REDIS_DB
)

#Metaclass 为Crawl类动态添加方法和属性
class CrawlMetaclass(type):
  #cls 当前准备创建的类对象
  #name 类的名字
  #bases 类继承的父类集合
  #attrs 类的方法集合
  #__CrawlFunc__ __CrawlCount__ 就是类Crawl的变量或方法 可直接使用
  def __new__(cls, name, bases, attrs):
    count = 0
    #抓取方法列表
    attrs['__CrawlFunc__'] = []

    for k, v in attrs.items():
      if 'crawl_' in k:
        attrs['__CrawlFunc__'].append(k)
        count += 1
    #抓取方法数量
    attrs['__CrawlCount__'] = count
    print(attrs)

    return type.__new__(cls, name, bases, attrs)


#抓取类
class Crawl(object, metaclass=CrawlMetaclass):
  def __init__(self):
    self.db = RedisClient(
      name = REDIS_KEY,
      host=REDIS_HOST,
      port=REDIS_PORT,
      db=REDIS_DB
    )

  #执行所有以'crawl_'开头的类方法 返回值保存到 proxies中
  #动态的调用所有以crawl_开头的方法
  def get_proxies(self, callback):
    proxies = []
    print("Class Methods Name: ", callback)

    #执行爬取类方法 eval(self.crawl_xxx)
    for proxy_list in eval("self.{}()".format(callback)):
      print("Get IP:", proxy_list)
      proxies.append(proxy_list)
    return proxies

  #代理网站 抓取分析 以crawl开头
  def crawl_kuaidaili(self, page_count=10):
    PAGE_NUM = 100
    #高匿
    INHA_URL = "https://www.kuaidaili.com/free/inha/%d/"
    #透明
    INTR_URL = "https://www.kuaidaili.com/free/intr/%d/"

    #返回一个迭代器 不可直接使用 循环取得迭代器的响应内容
    response = self.get_response(INHA_URL, page_count)

    for resp in response:
      selector = etree.HTML(resp)
      tr_list = selector.xpath("//div[@id='list']//tbody//tr")
      for tr in tr_list:
        IP = tr.xpath(".//td[@data-title='IP']//text()")[0]
        PORT = tr.xpath(".//td[@data-title='PORT']//text()")[0]
        # CRYPT = tr.xpath(".//td[@data-title='匿名度']//text()")[0]
        # TYPE = tr.xpath(".//td[@data-title='类型']//text()")[0]
        # LOCATE = tr.xpath(".//td[@data-title='位置']//text()")[0]
        # RESPEED = tr.xpath(".//td[@data-title='响应速度']//text()")[0]
        # VERTIME = tr.xpath(".//td[@data-title='最后验证时间']//text()")[0]
        # info = {
        #   'ip': IP, 'port': PORT,
        #   'crypt': CRYPT, 'type': TYPE,
        #   'locate': LOCATE, 'respeed': RESPEED,
        #   'vertime': VERTIME
        # }
        proxy_info = "%s:%s" % (IP, PORT)

        yield proxy_info

  #
  def crawl_xiladaili(self, page_count=10):
    # 高匿
    INHA_URL = "http://www.xiladaili.com/gaoni/%s/"

    # 返回一个迭代器 不可直接使用 循环取得迭代器的响应内容
    response = self.get_response(INHA_URL, page_count)
    for resp in response:
      selector = etree.HTML(resp)
      tr_list = selector.xpath("//table[@class='fl-table']//tbody//tr")
      for tr in tr_list:
        IP_PORT = tr.xpath(".//td[1]//text()")[0]
        # TYPE = tr.xpath(".//td[2]//text()")[0]
        # CRYPY = tr.xpath(".//td[3]//text()")[0]
        # LOCATE = tr.xpath(".//td[4]//text()")[0]
        # RESPEED = tr.xpath(".//td[5]//text()")[0]
        # VERTIME = tr.xpath(".//td[6]//text()")[0]
        # SCORE = tr.xpath(".//td[7]//text()")[0]

        yield IP_PORT



  #获取响应数据
  def get_response(self, start_url, page_count):
    #循环页数
    for i in range(1, page_count):
      #随机暂停抓取的秒数
      rand_time = random.randint(3, 7) * 10 / 100
      time.sleep(rand_time)

      #抓取的URL
      url = start_url % i
      print("Crawl URL Link %s" %url)
      #头信息
      HEADERS = {
        "user-agent": random.choice(USER_AGENT_LIST),
      }
      #错误标识
      flag_err = True

      while flag_err:
        req = requests.get(url, headers=HEADERS)
        print(req.status_code)
        if int(req.status_code) == 200:
          yield req.text
          flag_err = False
        else:
          time.sleep(0.5)

  #单个IP可用性检测
  def check_and_store(self, ip):
    print("Check Execute IP: %s" %ip)
    try:
      res = requests.get(
        random.choice(URL_LIST),
        proxies={"http": "http://%s" %ip},
        headers = {"user-agent": random.choice(USER_AGENT_LIST)},
        timeout = 1,
      )
    except Exception as e:
      pass
    else:
      if res.status_code == 200:
        print(ip, res.url, res.request.headers)
        #以set形式存储到redis中
        self.db.sadd(ip)
        return ip
      else:
        print("check_ip %s Error" %ip)

  #future 代理IP可用性检测
  def check_ip(self, res_list):
    worker = min(MAX_WORKERS, len(res_list))
    with futures.ThreadPoolExecutor(worker) as executor:
      res = executor.map(self.check_and_store, res_list)
    print(list(res))


if __name__ == '__main__':
  crawl = Crawl()
  for callback_num in range(crawl.__CrawlCount__):
    #获取到Crawl类中的以crawl_开头的方法名
    callback = crawl.__CrawlFunc__[callback_num]
    #调用对应此方法
    proxies = crawl.get_proxies(callback)
    #future 代理IP可用性检测 并存储到redis中
    crawl.check_ip(proxies)
