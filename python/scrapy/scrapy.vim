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
//div[@class='c1 text14_2']//text()
//div[@class='c1 text14_2']//img//@src
//a[text()='>']//@href
.//td[2]//a[@class='news14']//@title



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
  start_urls = ['http://circ.gov.cn/']

  #定义提取url的地址规则
  rules = (
    #LinkExtractor选择提取器 提取url地址
    #callback 提取出来的url地址 的response会交给callback处理
    #follow 当前url地址的响应是否重新通过Rule来提取url地址
    #
    Rule(LinkExtractor(allow=r'Items/'), callback='parse_item', follow=True),
  )

  #parse函数有特殊的功能 不能定义
  def parse_item(self, response):
    i = {}
    #i['domain_id'] = response.xpath('//input[@id="sid"]/@value').extract()
    #i['name'] = response.xpath('//div[@id="name"]').extract()
    #i['description'] = response.xpath('//div[@id="description"]').extract()
    return i



















