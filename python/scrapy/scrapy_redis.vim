pip install scrapy-redis

Scheduler               #调度
Duplication Filter      #去重
Item Pipeline           #管道文件 存储到reids中
Base Spider             #爬虫类 SPider CrawlSpider


redis中
  存储请求 队列 Scheduler
  存储请求 指纹 Scheduler
  存储数据     Itrem Pipeline

安装reids

settings.py

#使用scrapy-redis里的去重组件 不使用scrapy默认的去重
DUPEFILTER_CLASS = "scrapy_redis.dupefilter.RFPDupeFilter"
#使用了scrapy-redis里的调度器组件 不使用scrapy默认的调度器
SCHEDULER = "scrapy_redis.scheduler.Scheduler"
#请求任务可以中途暂停 redis请求记录不丢失
SCHEDULER_PERSIST = True

#默认的scrapy-redis请求队列形式(按优先级顺序)
SCHEDULER_QUEUE_CLASS = "scrapy_redis.queue.SpiderPriorityQueue"
#队列形式 先进先出
#SCHEDULER_QUEUE_CLASS = "scrapy_redis.queue.SpiderQueue"
#栈形式 请求先进后出
#SCHEDULER_QUEUE_CLASS = "scrapy_redis.queue.SpiderStack"


ITEM_PIPELINES = {
    ......
    #支持将数据存储到redis数据库里 必须启动
    'scrapy_redis.pipelines.RedisPipeline': 400,
}

#若不填写 则默认使用 127.0.0.1:6379的redis数据库
#指定数据的IP 和 端口
REDIS_HOST = '192.168.10.100'
REDIS_PORT = 6379


#向redis中存入项目的 起始爬取 链接地址
lpush mysqpider:start_url http://www.dmoz.org

myspider_redis.py
from scrapy_redis.spiders import RedisSpider

class MySpider(RedisSpider):
  name = "myspider_redis"
  #启动所有的slaver端爬虫的指令 下面格式可以参考 见识采用这种格式
  redis_key  = "myspider:start_url"
  #指定爬取的 域 范围
  allow_domain = ["dmoz.org"]

  #动态获取 爬取的域范围
  def __init__(self, *args, **kwagrs):
    domain = kwargs.pop("domain", "")
    self.allowed_domains = filter(None, domain.split(','))
    super(MySpider, self).__init__(*args, **kwargs)

  def parse(self, response):
    return {
      "name": response.css("title::text").extract_forst(),
      "url": response.url,
    }

#启动 scrapy_redis
scrapy runspider myspider_redis.py


#RedisCrawlSpider

from scrapy.spider import Rule
from scrapy.linkextractors import LinkExtractor
from scrapy_redis.spiders import RedisCrawlSpider


class MyCrawler(RedisCrawlSpider):
  name = "mycrawler_redis"
  redis_key = "mycrawler:start_urls"

  #爬取规则
  rules = (
    Rule(LinkExtractor(), callback="parse_page", follow=True),
  )

  #动态定义允许的 域名列表
  def __init__(self, *args, **kwargs):
    domain = kwargs.pop("domain", "")
    self.allowed_domains = filter(None, domain.split(","))
    super(MyCrawler, self).__init__(*args, **kwargs)

  def parse_page(self, response):
    return {
      "name": response.css("title::text").extract_first(),
      "url": response.url
    }








