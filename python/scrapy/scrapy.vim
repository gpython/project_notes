wget https://download.lfd.uci.edu/pythonlibs/r5uhg2lo/Twisted-18.9.0-cp36-cp36m-win32.whl
pip install Twisted-18.9.0-cp36-cp36m-win32.whl
pip install pywin32 scrapy

创建scrapy项目
scrapy startproject mySpider

生成一个爬虫
cd mySpider
                 爬虫名字  爬取的连接范围
scrapy genspider itcast "itcast.cn"
生成一个爬虫名字的py项目文件 itcast.py
返回值必须为Request BaseItem dict 或None


提取数据
完善spider 使用xpath等方法
class ItcastSpider(scrapy.Spider):
  #爬虫名字 启动爬虫scrapy srawl itcast
  name = 'itcast'

  #允许爬取的范围
  allowed_domains = ['itcast.cn']

  #开始爬取的地址
  start_urls = ['http://www.itcast.cn/channel/teacher.shtml']

  #解响应数据
  def parse(self, response):


保存数据 中间件
pipeline中保存数据

  可以有多个pipeline 不同的spider处理不同的item数据内容
  一个spider的内容可能要做不同的操作 比如存入不同的数据库中
  pipeline权重越小优先级越高


在项目文件夹中启动爬虫
scrapy crawl itcast

在settings文件中设置日志等级
LOG_LEVEL = "WARNING"



Xpath
xpath("//div[@class='c1 text14_2']//text()")
xpath("//div[@class='c1 text14_2']//img//@src")
xpath("//a[text()='>']//@href")
xpath(".//td[2]//a[@class='news14']//@title")

class包含i的div
xpath("//div[contains(@class, 'i')]")


分组
li_list = response.xpath("//div[@class='tea_con']//li")

for li in li_list:
  name = li.xpath(".//h3/text()").extract_first()
  title = li.xpath(".//h4/text()").extract_first()
  content = li.xpath(".//p/text()").extract_first()

xpath返回一个列表
extract() 返回包含字符串数据的列表值
extract_first() 返回列表中第一个值 没有为None

response.xpath()返回一个包含selector对象的列表

#### Logging
setting.py文件中日志等级 和 记录文件 设置 (记录文件后日志不会在输出到屏幕)
LOG_LEVEL = "WARNING"
LOG_FILE = "/data/logs/scrapy.log"

记录日志
import logging
logger= logging.getLogger(__name__)
logger.warning('some log access')


import logging

#设置日志输出格式
logging.basicConfig(
    level=logging.INFO,
    format='%(levelname)s [%(filename)s:%(lineno)d]'
            ': %(message)s'
            '- %(asctime)s', datefmt='[%d/%b/%Y %H:%M:%S]',
)

logger = logging.getLogger(__name__)

其他py文件可以直接导入此logger使用
logger.info()


### 翻页请求
当前页 数据
//table[@class='tablelist']//tr[2]//td[1]

下一页页码连接
//a[@id='next']//@href


scrapy startproject tencent
scrapy genspider hr tencent.com

next_url = response.xpath("//a[@id='next']/@href").extract_first()
if next_url != "javascript:;":
  next_url = "%s%s" %("https://domain/", next_url)
  #scrapy.Request能够构建一个request对象
  #同时指定提取数据的callback函数
  yield scrapy.Request(
    next_url,
    callbacl = self.parse
  )

scrapy.Request 参数说明
POST  请求体 自定义headers 自定义 cookies
[]为可选参数
scrapy.Request(url [,callback, method="GET", headers, body, cookies, meta, dont_filter=False])

scrapy.Request
  callback 指定传入的url交给那个解析函数去处理
  meta 实现在不同的解析函数中传递数据 meta默认会携带部分信息 比如下载延迟 请求深度等
  dont_filter 让scrapy的去重不会过滤当前url， scrapy默认有curl去重的功能 对需要重复请求的url有重要用途



### items.py

定义要保存的字段
#scrapy.Item是一个字典
class MyspiderItem(scrapy.Item):
  #scrapy.Field()是一个字典
  name = scrapy.Field()

获取数据的时候 使用不同的Item来存放不同的数据
在把数据交给pipeline的时候 可以通过isinstance(item, MyspiderItem)来
判断数据属于哪个item 进行不同的数据处理







scrapy shell http://url
>> response.xpath()
>> spider.name
>> response.url 当前响应的url
>> response.request.url 当前响应对应的请求的url
>> response.headers 响应头
>> response.body    响应体 也就是html代码 默认byte类型
>> response.request.headers 当前响应请求头


###settings

使用setting文件中内容
spider.settings.get("BO_NAME", None)


###RE 正则
正则替换 正则查找值 替换为的值 字符串
re.sub(r"\xa0|\s","", i)





###CrawlSpider

生成crawlspider 的爬虫
scrapy startproject crawl_pro
scrapy genspider -t crawl cf "circ.gov.cn"


class CfSpider(CrawlSpider):
  name = 'cf'
  allowed_domains = ['circ.gov.cn']

  #第一次请求的url 如果对此url有特殊需求
  #可以自定义parse_start_url函数专门处理这个url所对应的响应
  start_urls = ['http://bxjg.circ.gov.cn/web/site0/tab5240/']

  #定义提取url的地址规则
  rules = (
    #LinkExtractor选择提取器 提取url地址
    #callback 提取出来的url地址 的response会交给callback处理
    #callback 指定满足规则的url的解析函数的字符串

    #follow 当前url地址的响应是否重新通过Rule来提取url地址
    #follow response中提取的连接是否需要跟进

    #不指定callback函数的请求下 如果follow为True 满足该rule的url还会继续被请求
    #如果多个Rule都满足某一个url 会从rules中选择第一个满足的进行操作


    #详情页地址需要写callback 非详情页面 下一页之类连接地址不需要callback 而是follow为True

    #详情页 内容 抓取
    #找到所有详情页 地址 并请求 然后调用parse_item进行处理response

    Rule(LinkExtractor(allow=r'Items/'), callback='parse_item', follow=True),

    #非详情页  下一页页码请求 请求后转给详情页面 处理详情页内容信息
    #找到所有翻页地址 并请求

    Rule(LinkExtractor(allow=r'/web/site0/tab5240/module14430/page\d+\.htm'), follow=True),

  )

  #parse函数有特殊的功能 不能定义
  def parse_item(self, response):
    item = {}
    #i['domain_id'] = response.xpath('//input[@id="sid"]/@value').extract()
    #i['name'] = response.xpath('//div[@id="name"]').extract()
    #i['description'] = response.xpath('//div[@id="description"]').extract()
    yield scrapy.Request(
      url,
      callback=self.next_url_parse_detail,
      meta = {"item": item},
    )

  def next_url_parse_detail(self, response):
    item = response.meta["item"]
    item["oter_content"] = respone.xpath("//div[@class='xxx']")
    yield item




###登录
直接 携带cookie登录
找到发送post请求的url地址 带上信息 发送请求

scrapy crawl peoject_name 开启爬虫项目时 调用start_urls
start_urls 被scrapy.Spider类中的start_requests函数调用
重写此函数即可

settings中
COOKIES_ENABLED 默认为开启 下次请求其他网站时 会自动携带cookie发送请求
可以在settings中设置COOKIES_DEBUG=True 能够在不同的解析函数中传递 前提
COOKIE_ENABLED=True


下载中间件 Download Middlewares 添加随机的UA
下载中间件 在引擎 和 下载器 中间
引擎传过去的request对象会通过下载中间件
下载器请求完成后的相应 也会通过下载中间件


settings中关闭注释 DOWNLOADER_MIDDLEWARES

process_request(self, request, spider)
  每个request请求通过下载中间件 该方法被调用

process_response(self, request, response, spider)
  当下载完成http请求 传递响应给引擎的时候调用

class RandomUserAgent(object):
  #请求发送之前给request的headers头赋值
  def process_request(self, request, spider):
    ua = random.choices(spider.settings.get("USER_AGENT_LIST"))
    #添加请求头
    request.headers["User-Agent"] = ua
    #添加请求代理 需要在request的meta信息中添加proxy字段
    request.meta["proxy"] = "http://proxy:port"


class DownloadMiddlerware(object):
  def process_request(self, request, spider):
    ua = random.choices(spider.settings.get("USER_AGENT_LIST"))
    request.headers["User-Agent"] = ua
    request.meta["proxy"] = random.choices(spider.settings.get("PROXY_LIST"))

  def process_response(self, request, response, spider):
    #response做些许处理后 返回相应
    return response

#发送post请求
yield scrapy.Request(
    url,
    method="POST",
    body=""
    callback=self...
  )

#url地址补充完整
urllib.parse.urljoin(response.url, item['href'])

#一种执行的方式
from scrapy import cmdline
cmdline.execute("scrapy runspider myspider_redis.py".split())


USER_AGENT_LIST = [
  "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36",
  "Mozilla/5.0 (Linux; U; Android 2.3.6; en-us; Nexus S Build/GRK39F) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1",
  "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/532.5 (KHTML, like Gecko) Chrome/4.0.249.0 Safari/532.5",
  "Mozilla/5.0 (Windows; U; Windows NT 5.2; en-US) AppleWebKit/532.9 (KHTML, like Gecko) Chrome/5.0.310.0 Safari/532.9",
  "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/534.7 (KHTML, like Gecko) Chrome/7.0.514.0 Safari/534.7",
  "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US) AppleWebKit/534.14 (KHTML, like Gecko) Chrome/9.0.601.0 Safari/534.14",
  "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.14 (KHTML, like Gecko) Chrome/10.0.601.0 Safari/534.14",
  "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.20 (KHTML, like Gecko) Chrome/11.0.672.2 Safari/534.20",
  "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/534.27 (KHTML, like Gecko) Chrome/12.0.712.0 Safari/534.27",
  "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.24 Safari/535.1",
  "Mozilla/5.0 (Windows NT 6.0) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.120 Safari/535.2",
  "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.36 Safari/535.7",
  "Mozilla/5.0 (Windows; U; Windows NT 6.0 x64; en-US; rv:1.9pre) Gecko/2008072421 Minefield/3.0.2pre",
  "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.10) Gecko/2009042316 Firefox/3.0.10",
  "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-GB; rv:1.9.0.11) Gecko/2009060215 Firefox/3.0.11 (.NET CLR 3.5.30729)",
  "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6 GTB5",
  "Mozilla/5.0 (Windows; U; Windows NT 5.1; tr; rv:1.9.2.8) Gecko/20100722 Firefox/3.6.8 ( .NET CLR 3.5.30729; .NET4.0E)",
  "Mozilla/5.0 (Windows NT 6.1; rv:2.0.1) Gecko/20100101 Firefox/4.0.1",
  "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:2.0.1) Gecko/20100101 Firefox/4.0.1",
  "Mozilla/5.0 (Windows NT 5.1; rv:5.0) Gecko/20100101 Firefox/5.0",
  "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0a2) Gecko/20110622 Firefox/6.0a2",
  "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:7.0.1) Gecko/20100101 Firefox/7.0.1",  "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:2.0b4pre) Gecko/20100815 Minefield/4.0b4pre",
  "Mozilla/5.0 (Windows; U; Windows NT 5.1; de-CH) AppleWebKit/523.15 (KHTML, like Gecko, Safari/419.3) Arora/0.2",
  "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; GTB5; Avant Browser; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
  "Mozilla/5.0 (Macintosh; U; PPC Mac OS X 10.4; en; rv:1.9.0.19) Gecko/2011091218 Camino/2.0.9 (like Firefox/3.0.19)",
  "Mozilla/5.0 (Windows NT 6.2) AppleWebKit/536.6 (KHTML, like Gecko) Chrome/20.0.1090.0 Safari/536.6",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.57 Safari/536.11",
  "Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1180.75 Safari/537.1",
  "Mozilla/5.0 (X11; U; Linux i686; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.127 Safari/534.16",
  "Mozilla/5.0 (iPhone; U; CPU iPhone OS 5_1_1 like Mac OS X; en) AppleWebKit/534.46.0 (KHTML, like Gecko) CriOS/19.0.1084.60 Mobile/9B206 Safari/7534.48.3",
  "Mozilla/5.0 (Linux; U; Android-4.0.3; en-us; Galaxy Nexus Build/IML74K) AppleWebKit/535.7 (KHTML, like Gecko) CrMo/16.0.912.75 Mobile Safari/535.7",
  "Mozilla/5.0 (X11; U; CrOS i686 9.10.0; en-US) AppleWebKit/532.5 (KHTML, like Gecko) Chrome/4.0.253.0 Safari/532.5",
]




